/* Load constants and macros */
#include "pm.h"        

.code16
.text
    jmp LABEL_BEGIN

/* GDT */
LABEL_GDT:          Descriptor  0,       0,                0
LABEL_DESC_CODE32:  Descriptor  0,       (SegCode32Len - 1), (DA_C + DA_32)
LABEL_DESC_VIDEO:   Descriptor  0xB8000, 0xffff,           DA_DRW

.set GdtLen, (. - LABEL_GDT)  /* GDT Length */

GdtPtr: .2byte  (GdtLen - 1)  /* GDT Border */
        .4byte  0             /* GDT Base */

/* GDT Selector */
.set    SelectorCode32, (LABEL_DESC_CODE32 - LABEL_GDT)
.set    SelectorVideo,  (LABEL_DESC_VIDEO  - LABEL_GDT)

LABEL_BEGIN: 
    mov     %cs, %ax
    mov     %ax, %ds
    mov     %ax, %es
    mov     %ax, %ss
    mov     $0x100, %sp

    /* Initialize 32-bits code segment descriptor. */
    xor     %eax, %eax
    mov     %cs, %ax
    shl     $4, %eax
    addl    $(LABEL_SEG_CODE32), %eax
    movw    %ax, (LABEL_DESC_CODE32 + 2)
    shr     $16, %eax
    movb    %al, (LABEL_DESC_CODE32 + 4)
    movb    %ah, (LABEL_DESC_CODE32 + 7)

    /* Prepared for loading GDTR */
    xor     %eax, %eax
    mov     %ds, %ax
    shl     $4, %eax
    add     $(LABEL_GDT), %eax         # eax <- gdt base
	movl    %eax, (GdtPtr + 2)

    /* Load GDTR(Global Descriptor Table Register) */
    lgdtw   GdtPtr

    /* Clear Interrupt Flag */
    cli

    /* Open A20 */
    inb     $0x92, %al
    orb     $0b00000010, %al
    outb    %al, $0x92

    /* Prepared to swithing to protect mode */
    movl    %cr0, %eax
    orl     $1, %eax
    movl    %eax, %cr0

    /* Enter protect mode. */
    .2byte  0xea66
    .4byte  0x00000000
    .2byte  SelectorCode32

LABEL_SEG_CODE32: 
.code32
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs               /* Video segment selector(dest) */

    movl 	$((80 * 10 + 0) * 2), %edi
    movb    $0xC, %ah               # 0000: Black Back 1100: Red Front
    movb    $'P', %al

    mov     %ax, %gs:(%edi)

    /* Stop here, infinate loop. */
    jmp     . 

.set    SegCode32Len, . - LABEL_SEG_CODE32
