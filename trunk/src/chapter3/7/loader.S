/* chapter3/7/loader.S

   Author: Wenbo Yang <solrex@gmail.com> <http://solrex.cn>

   This file is part of the source code of book "Write Your Own OS with Free
   and Open Source Software". Homepage @ <http://share.solrex.cn/WriteOS/>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

#include "pm.h"

.set    PageDirBase, 0x200000   /* 2MB */
.set    PageTblBase, 0x201000   /* 2MB+4KB */

.code16
.text
    jmp LABEL_BEGIN     /* jump over the .data section. */

/* NOTE! Wenbo-20080512: Actually here we put the normal .data section into
   the .code section. For application SW, it is not allowed. However, we are
   writting an OS. That is OK. Because there is no OS to complain about
   that behavior. :) */

/* Global Descriptor Table */
LABEL_GDT:          Descriptor        0,                  0, 0
LABEL_DESC_CODE32:  Descriptor        0, (SegCode32Len - 1), (DA_C + DA_32)
LABEL_DESC_DATA:    Descriptor        0,      (DataLen - 1), DA_DRW
LABEL_DESC_STACK:   Descriptor        0,         TopOfStack, (DA_DRWA + DA_32)
LABEL_DESC_VIDEO:   Descriptor  0xB8000,             0xffff, (DA_DRW + DA_DPL3)
LABEL_DESC_LDT:     Descriptor        0,       (LDTLen - 1), DA_LDT
LABEL_DESC_CODECG:  Descriptor        0, (SegCodeCGLen - 1), (DA_C + DA_32)
LABEL_DESC_CODER3:  Descriptor        0, (SegCodeR3Len - 1), (DA_C + DA_32 + DA_DPL3)
LABEL_DESC_STACKR3: Descriptor        0,       TopOfStackR3, (DA_DRWA + DA_32 + DA_DPL3)
LABEL_DESC_TSS:     Descriptor        0,       (TSSLen - 1), DA_386TSS
LABEL_DESC_PAGEDIR: Descriptor PageDirBase,            4096, DA_DRW
LABEL_DESC_PAGETBL: Descriptor PageTblBase,            1024, (DA_DRW | DA_LIMIT_4K)
/* Gate Descriptors */
LABEL_CG_TEST:      Gate    SelectorCodeCG, 0, 0, (DA_386CGate + DA_DPL3)

.set GdtLen, (. - LABEL_GDT)  /* GDT Length */

GdtPtr: .2byte  (GdtLen - 1)  /* GDT Limit */
        .4byte  0             /* GDT Base */

/* GDT Selector(TI flag clear) */
.set    SelectorCode32, (LABEL_DESC_CODE32 - LABEL_GDT)
.set    SelectorData,   (LABEL_DESC_DATA   - LABEL_GDT)
.set    SelectorStack,  (LABEL_DESC_STACK  - LABEL_GDT)
.set    SelectorVideo,  (LABEL_DESC_VIDEO  - LABEL_GDT)
.set    SelectorLDT,    (LABEL_DESC_LDT    - LABEL_GDT)
.set    SelectorCodeCG, (LABEL_DESC_CODECG - LABEL_GDT)
.set    SelectorCGTest, (LABEL_CG_TEST     - LABEL_GDT)
.set    SelectorCodeR3, (LABEL_DESC_CODER3 - LABEL_GDT + SA_RPL3)
.set    SelectorStackR3,(LABEL_DESC_STACKR3- LABEL_GDT + SA_RPL3)
.set    SelectorTSS,    (LABEL_DESC_TSS - LABEL_GDT)
.set    SelectorPageDir,(LABEL_DESC_PAGEDIR - LABEL_GDT)
.set    SelectorPageTbl,(LABEL_DESC_PAGETBL - LABEL_GDT)

/* LDT segment */
LABEL_LDT:
LABEL_LDT_DESC_CODEA:   Descriptor  0, (CodeALen - 1), (DA_C + DA_32)

.set    LDTLen, (. - LABEL_LDT) /* LDT Length */
/* LDT Selector (TI flag set)*/
.set    SelectorLDTCodeA, (LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL)

/* 32-bit global data segment. */
LABEL_DATA:
_PMMessage:     .ascii "Welcome to protect mode! ^-^\n\0"
_LDTMessage:    .ascii "Aha, you jumped into a LDT segment.\n\0"
_MemChkTitle:   .ascii "BaseAddrLo BaseAddrHi LengthLo LengthHi   Type\n\0"
_RAMSizeMes:    .ascii "RAM Size:\0"
_ReturnMes:     .ascii "\n\0"
_MCRNumber:     .4byte 0
_DispPos:       .4byte (80*2+0)*2
_MemSize:       .4byte 0
_ARDStruct:
  _BaseAddrLow:     .4byte 0
  _BaseAddrHigh:    .4byte 0
  _LengthLow:       .4byte 0
  _LengthHigh:      .4byte 0
  _Type:            .4byte 0
_MemChkBuf:  .space 256, 0

.set    PMMessage,        (_PMMessage - LABEL_DATA)
.set    LDTMessage,       (_LDTMessage - LABEL_DATA)
.set    MemChkTitle,      (_MemChkTitle - LABEL_DATA)
.set    RAMSizeMes,       (_RAMSizeMes - LABEL_DATA)
.set    ReturnMes,        (_ReturnMes - LABEL_DATA)
.set    MCRNumber,        (_MCRNumber - LABEL_DATA)
.set    DispPos,          (_DispPos - LABEL_DATA)
.set    MemSize,          (_MemSize - LABEL_DATA)
.set    ARDStruct,        (_ARDStruct - LABEL_DATA)
  .set  BaseAddrLow,      (_BaseAddrLow - LABEL_DATA)
  .set  BaseAddrHigh,     (_BaseAddrHigh - LABEL_DATA)
  .set  LengthLow,        (_LengthLow - LABEL_DATA)
  .set  LengthHigh,       (_LengthHigh - LABEL_DATA)
  .set  Type,             (_Type - LABEL_DATA)
.set    MemChkBuf,        (_MemChkBuf - LABEL_DATA)
.set    DataLen,          (. - LABEL_DATA)

/* 32-bit global stack segment. */
.align  4
LABEL_STACK:
.space  512, 0
.set    TopOfStack, (. - LABEL_STACK)

/* 32-bit ring 3 stack segment. */
LABEL_STACKR3:
.space  512, 0
.set    TopOfStackR3, (. - LABEL_STACKR3)

LABEL_TSS:
    .4byte  0           /* Back Link */
    .4byte  TopOfStack  /* ESP0 */
    .4byte  SelectorStack /* SS0 */
    .4byte  0           /* ESP1 */
    .4byte  0           /* SS1 */
    .4byte  0           /* ESP2 */
    .4byte  0           /* SS2 */
    .4byte  0           /* CR3(PDBR) */
    .4byte  0           /* EIP */
    .4byte  0           /* EFLAGS */
    .4byte  0           /* EAX */
    .4byte  0           /* ECX */
    .4byte  0           /* EDX */
    .4byte  0           /* EBX */
    .4byte  0           /* ESP */
    .4byte  0           /* EBP */
    .4byte  0           /* ESI */
    .4byte  0           /* EDI */
    .4byte  0           /* ES */
    .4byte  0           /* CS */
    .4byte  0           /* SS */
    .4byte  0           /* DS */
    .4byte  0           /* FS */
    .4byte  0           /* GS */
    .4byte  0           /* LDT Segment Selector */
    .2byte  0           /* Trap Flag: 1-bit */
    .2byte  (. - LABEL_TSS + 2)     /* I/O Map Base Address */
    .byte   0xff        /* End */
.set    TSSLen, (. - LABEL_TSS)

/* Program starts here. */
LABEL_BEGIN:
    mov     %cs, %ax    /* Move code segment address(CS) to data segment */
    mov     %ax, %ds    /* register(DS), ES and SS. Because we have      */
    mov     %ax, %es    /* embedded .data section into .code section in  */
    mov     %ax, %ss    /* the start(metioned in the NOTE above).        */

    mov     $0x100, %sp

    xor     %ebx, %ebx
    mov     $(_MemChkBuf), %di
BEGIN.loop:
    mov     $0xe820, %eax
    mov     $20, %ecx
    mov     $0x534d4150, %edx
    int     $0x15
    jc      LABEL_MEM_CHK_FAIL
    add     $20, %di
    incl    (_MCRNumber)
    cmp     $0, %ebx
    jne     BEGIN.loop
    jmp     LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
    movl    $0, (_MCRNumber)
LABEL_MEM_CHK_OK:

    /* Initialize 32-bits code segment descriptor. */
    InitDesc LABEL_SEG_CODE32, LABEL_DESC_CODE32

    /* Initialize data segment descriptor. */
    InitDesc LABEL_DATA, LABEL_DESC_DATA

    /* Initialize stack segment descriptor. */
    InitDesc LABEL_STACK, LABEL_DESC_STACK

    /* Initialize LDT descriptor in GDT. */
    InitDesc LABEL_LDT, LABEL_DESC_LDT

    /* Initialize code A descriptor in LDT. */
    InitDesc LABEL_CODEA, LABEL_LDT_DESC_CODEA

    /* Initialize call gate dest code segment descriptor. */
    InitDesc LABEL_SEG_CODECG, LABEL_DESC_CODECG

    /* Initialize ring 3 stack segment descriptor. */
    InitDesc LABEL_STACKR3, LABEL_DESC_STACKR3

    /* Initialize ring 3 dest code segment descriptor. */
    InitDesc LABEL_SEG_CODER3, LABEL_DESC_CODER3

    /* Initialize TSS segment descriptor. */
    InitDesc LABEL_TSS, LABEL_DESC_TSS

    /* Prepared for loading GDTR */
    xor     %eax, %eax
    mov     %ds, %ax
    shl     $4, %eax
    add     $(LABEL_GDT), %eax      /* eax <- gdt base*/
    movl    %eax, (GdtPtr + 2)

    /* Load GDTR(Global Descriptor Table Register) */
    lgdtw   GdtPtr

    /* Clear Interrupt Flags */
    cli

    /* Open A20 line. */
    inb     $0x92, %al
    orb     $0b00000010, %al
    outb    %al, $0x92

    /* Enable protect mode, PE bit of CR0. */
    movl    %cr0, %eax
    orl     $1, %eax
    movl    %eax, %cr0

    /* Mixed-Size Jump. */
    ljmpl $SelectorCode32, $0       /* Thanks to earthengine@gmail, I got */
                                    /* this mixed-size jump insn of gas.  */

/* 32-bit code segment for LDT */
LABEL_CODEA:
.code32
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs

    movb    $0xC, %ah               /* 0000: Black Back 1100: Red Front */
    xor     %esi, %esi
    xor     %edi, %edi
    movl    $(LDTMessage), %esi
    movl    $((80 * 12 + 0) * 2), %edi
    cld                         /* Clear DF flag. */

/* Display a string from %esi(string offset) to %edi(video segment). */
CODEA_1:
    lodsb                       /* Load a byte from source */
    test    %al, %al
    jz      CODEA_2
    mov     %ax, %gs:(%edi)
    add     $2, %edi
    jmp     CODEA_1
CODEA_2:

    /* Stop here, infinate loop. */
    jmp     .
.set    CodeALen, (. - LABEL_CODEA)

/* 32-bit code segment for GDT */
LABEL_SEG_CODE32: 
    mov     $(SelectorData), %ax
    mov     %ax, %ds                /* Data segment selector */
    mov     $(SelectorData), %ax
    mov     %ax, %es                /* Data segment selector */
    mov     $(SelectorStack), %ax
    mov     $(SelectorStack), %ax
    mov     %ax, %ss                /* Stack segment selector */
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs                /* Video segment selector(dest) */

    mov     $(TopOfStack), %esp

    push    $(PMMessage)
    call    DispStr
    add     $4, %esp

    push    $(MemChkTitle)
    call    DispStr
    add     $4, %esp
    call    DispMemSize
    
    call    SetupPaging

    mov     $(SelectorTSS), %ax    /* Load TSS to TR register */
    ltr     %ax

    pushl   $(SelectorStackR3)     /* Fake call procedure. */
    pushl   $(TopOfStackR3)
    pushl   $(SelectorCodeR3)
    pushl   $0
    lret                           /* return with no call */

CODE32_3:
    mov     $(SelectorLDT), %ax
    lldt    %ax
    
    ljmp    $(SelectorLDTCodeA), $0

/* Get the length of 32-bit segment code. */
.set    SegCode32Len, . - LABEL_SEG_CODE32

/* 32-bit code segment for call gate destination segment */
LABEL_SEG_CODECG:
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs

    movl    $((80 * 12 + 0) * 2), %edi  /* line 11, column 0 */
    movb    $0xC, %ah               /* 0000: Black Back 1100: Red Front */
    movb    $'C', %al               /* Print a 'C' */

    mov     %ax, %gs:(%edi)
    lret

/* Get the length of 32-bit call gate destination segment code. */
.set    SegCodeCGLen, . - LABEL_SEG_CODECG

/* 32-bit code segment for runing in ring 3. */
LABEL_SEG_CODER3:
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs

    movl    $((80 * 12 + 1) * 2), %edi  /* line 11, column 1 */
    movb    $0xC, %ah               /* 0000: Black Back 1100: Red Front */
    movb    $'3', %al               /* Print a '3' */

    mov     %ax, %gs:(%edi)
    lcall   $(SelectorCGTest), $0  /* Call CODECG through call gate */
    jmp     .   

/* Get the length f 32-bit ring 3 segment code. */
.set    SegCodeR3Len, . - LABEL_SEG_CODER3

SetupPaging:
    xor     %edx, %edx
    mov     (MemSize), %eax
    mov     $0x400000, %ebx
    div     %ebx
    mov     %eax, %ecx
    test    %edx, %edx
    jz      SP.no_remainder
    inc     %ecx
SP.no_remainder:
    push    %ecx

    mov     $(SelectorPageDir), %ax
    mov     %ax, %es
    xor     %edi, %edi
    xor     %eax, %eax
    mov     $(PageTblBase | PG_P | PG_USU | PG_RWW), %eax
SP_1:
    stosl
    add     $4096, %eax
    loop    SP_1

    mov     $(SelectorPageTbl), %ax
    mov     %ax, %es
    pop     %eax
    mov     $1024, %ebx
    mul     %ebx
    mov     %eax, %ecx
    xor     %edi, %edi
    mov     $(PG_P | PG_USU | PG_RWW), %eax
SP_2:
    stosl
    add     $4096, %eax
    loop    SP_2

    mov     $(PageDirBase), %eax
    mov     %eax, %cr3
    mov     %cr0, %eax
    or      $0x80000000, %eax
    mov     %eax, %cr0
    jmp     SP_3
SP_3:
    nop
    ret

DispMemSize:
    push    %esi
    push    %edi
    push    %ecx

    mov     $(MemChkBuf), %esi
    mov     (MCRNumber), %ecx
DMS.loop:
    mov     $5, %edx
    mov     $(ARDStruct), %edi
DMS.1:                          
    push    (%esi)
    call    DispInt
    pop     %eax
    stosl
    add     $4, %esi
    dec     %edx
    cmp     $0, %edx
    jnz     DMS.1
    call    DispReturn
    cmpl    $1, (Type)
    jne     DMS.2
    mov     (BaseAddrLow), %eax
    add     (LengthLow), %eax
    cmp     (MemSize), %eax
    jb      DMS.2
    mov     %eax, (MemSize)
DMS.2:
    loop    DMS.loop

    call    DispReturn
    push    $(RAMSizeMes)
    call    DispStr
    add     $4, %esp

    pushl   (MemSize)
    call    DispInt
    add     $4, %esp

    pop     %ecx
    pop     %edi
    pop     %esi
    ret

#include "lib.h"

