/* chapter3/8/loader.S

   Author: Wenbo Yang <solrex@gmail.com> <http://solrex.cn>

   This file is part of the source code of book "Write Your Own OS with Free
   and Open Source Software". Homepage @ <http://share.solrex.cn/WriteOS/>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

#include "pm.h"

.set    PageDirBase0, 0x200000   /* 2MB, base address of page directory */
.set    PageTblBase0, 0x201000   /* 2MB+4KB, base address of page table */
.set    PageDirBase1, 0x210000   /* 2MB+64KB, base address of page directory */
.set    PageTblBase1, 0x211000   /* 2MB+68KB, base address of page table */

.set    LinearAddrDemo, 0x401000
.set    ProcFoo, 0x401000
.set    ProcBar, 0x501000
.set    ProcPagingDemo, 0x301000

.code16
.text
    jmp LABEL_BEGIN     /* jump over the .data section. */

/* NOTE! Wenbo-20080512: Actually here we put the normal .data section into
   the .code section. For application SW, it is not allowed. However, we are
   writting an OS. That is OK. Because there is no OS to complain about
   that behavior. :) */

/* Global Descriptor Table */
LABEL_GDT:          Descriptor        0,                  0, 0
LABEL_DESC_CODE32:  Descriptor        0, (SegCode32Len - 1), (DA_CR | DA_32)
LABEL_DESC_DATA:    Descriptor        0,      (DataLen - 1), DA_DRW
LABEL_DESC_STACK:   Descriptor        0,         TopOfStack, (DA_DRWA + DA_32)
LABEL_DESC_VIDEO:   Descriptor  0xB8000,             0xffff, (DA_DRW + DA_DPL3)
LABEL_DESC_LDT:     Descriptor        0,       (LDTLen - 1), DA_LDT
LABEL_DESC_CODECG:  Descriptor        0, (SegCodeCGLen - 1), (DA_C + DA_32)
LABEL_DESC_CODER3:  Descriptor        0, (SegCodeR3Len - 1), (DA_C + DA_32 + DA_DPL3)
LABEL_DESC_STACKR3: Descriptor        0,       TopOfStackR3, (DA_DRWA + DA_32 + DA_DPL3)
LABEL_DESC_TSS:     Descriptor        0,       (TSSLen - 1), DA_386TSS
LABEL_DESC_FLAT_C:  Descriptor        0,            0xfffff, (DA_CR|DA_32|DA_LIMIT_4K)
LABEL_DESC_FLAT_RW: Descriptor        0,            0xfffff, (DA_DRW|DA_LIMIT_4K)
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
.set    SelectorFlatC  ,(LABEL_DESC_FLAT_C - LABEL_GDT)
.set    SelectorFlatRW ,(LABEL_DESC_FLAT_RW - LABEL_GDT)

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
_ARDSTitle:     .ascii "BaseAddrLo BaseAddrHi LengthLo LengthHi   Type\n\0"
_RAMSizeMes:    .ascii "RAM Size:\0"
_LFMes:         .ascii "\n\0"   /* Line Feed Message(New line) */
_AMECount:      .4byte 0        /* Address Map Entry Counter */
_CursorPos:     .4byte (80*2+0)*2  /* Screen Cursor postion for printing */
_MemSize:       .4byte 0        /* Useable Memory Size */
_ARDStruct:                     /* Address Range Descriptor Structure */
  _BaseAddrLow:     .4byte 0    /* Low 32 bits of base address */
  _BaseAddrHigh:    .4byte 0    /* High 32 bits of base address */
  _LengthLow:       .4byte 0    /* Low 32 bits of length in bytes */
  _LengthHigh:      .4byte 0    /* High 32 bits of length in bytes */
  _Type:            .4byte 0    /* Address type of this range: 0, 1, other */
_PabeTableNum:  .4byte  0       /* Number of page tables */
_AddrMapBuf:  .space 256, 0      /* Address map buffer */

.set    PMMessage,        (_PMMessage - LABEL_DATA)
.set    LDTMessage,       (_LDTMessage - LABEL_DATA)
.set    ARDSTitle,        (_ARDSTitle - LABEL_DATA)
.set    RAMSizeMes,       (_RAMSizeMes - LABEL_DATA)
.set    LFMes,            (_LFMes - LABEL_DATA)
.set    AMECount,         (_AMECount - LABEL_DATA)
.set    CursorPos,        (_CursorPos - LABEL_DATA)
.set    MemSize,          (_MemSize - LABEL_DATA)
.set    ARDStruct,        (_ARDStruct - LABEL_DATA)
  .set  BaseAddrLow,      (_BaseAddrLow - LABEL_DATA)
  .set  BaseAddrHigh,     (_BaseAddrHigh - LABEL_DATA)
  .set  LengthLow,        (_LengthLow - LABEL_DATA)
  .set  LengthHigh,       (_LengthHigh - LABEL_DATA)
  .set  Type,             (_Type - LABEL_DATA)
.set    PabeTableNum,     (_PabeTableNum - LABEL_DATA)
.set    AddrMapBuf,       (_AddrMapBuf - LABEL_DATA)
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
    mov     %ax, %ss    /* the start(mentioned in the NOTE above).        */

    mov     $0x100, %sp

    /* Get System Address Map */
    xor     %ebx, %ebx             /* EBX: Continuation, 0 */
    mov     $(_AddrMapBuf), %di    /* ES:DI: Buffer Pointer, _AddrMapBuf */
BEGIN.loop:
    mov     $0xe820, %eax          /* EAX: Function code, E820h */
    mov     $20, %ecx              /* ECX: Buffer size, 20 */
    mov     $0x534d4150, %edx      /* EDX: Signature 'SMAP' */
    int     $0x15                  /* INT 15h */
    jc      BEGIN.getAMfail
    add     $20, %di               /* Increase buffer pointer by 20(bytes) */
    incl    (_AMECount)            /* Inc Address Map Entry Counter by 1 */
    cmp     $0, %ebx               /* End of Address Map? */
    jne     BEGIN.loop
    jmp     BEGIN.getAMok
BEGIN.getAMfail:                   /* Failed to get system address map */
    movl    $0, (_AMECount)
BEGIN.getAMok:                     /* Got system address map */

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
CODEA.1:
    lodsb                       /* Load a byte from source */
    test    %al, %al
    jz      CODEA.2
    mov     %ax, %gs:(%edi)
    add     $2, %edi
    jmp     CODEA.1
CODEA.2:

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
    mov     %ax, %ss                /* Stack segment selector */
    mov     $(SelectorVideo), %ax
    mov     %ax, %gs                /* Video segment selector(dest) */

    mov     $(TopOfStack), %esp

    push    $(ARDSTitle)           /* Display addr range descriptor struct title */
    call    DispStr
    add     $4, %esp
    call    DispAddrMap            /* Display system address map */

    call    PagingDemo             /* Setup and enable paging */

    push    $(PMMessage)
    call    DispStr
    add     $4, %esp

    mov     $(SelectorTSS), %ax    /* Load TSS to TR register */
    ltr     %ax

    pushl   $(SelectorStackR3)     /* Fake call procedure. */
    pushl   $(TopOfStackR3)
    pushl   $(SelectorCodeR3)
    pushl   $0
    lret                           /* return with no call */

CODE32.3:
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
/* Directly map linear addresses to physical addresses for simplification */
    /* Get useable PDE number from memory size. */
    xor     %edx, %edx
    mov     (MemSize), %eax         /* Memory Size */
    mov     $0x400000, %ebx         /* Page table size(bytes), 1024*1024*4 */
    div     %ebx                    /* temp = MemSize/4M */
    mov     %eax, %ecx
    test    %edx, %edx
    jz      SP.no_remainder
    inc     %ecx
SP.no_remainder:
    mov     %ecx, (PabeTableNum)    /* number of PDE = ceil(temp) */

    /* Init page table directories, %ecx entries. */
    mov     $(SelectorFlatRW), %ax
    mov     %ax, %es
    mov     $(PageDirBase0), %edi
    xor     %eax, %eax
    /* Set PDE attributes(flags): P: 1, U/S: 1, R/W: 1. */
    mov     $(PageTblBase0 | PG_P | PG_USU | PG_RWW), %eax
SP.1:
    stosl                   /* Store %eax to %es:%edi consecutively. */
    add     $4096, %eax     /* Page tables are in sequential format. */
    loop    SP.1            /* %ecx loops. */

    /* Init page tables, %ecx*1024 pages. */
    mov     (PabeTableNum), %eax /* Get saved ecx(number of PDE) */
    mov     $1024, %ebx
    mul     %ebx            /* Loop counter, num of pages: 1024*%ecx. */
    mov     %eax, %ecx
    mov     $(PageTblBase0), %edi
    /* Set PTE attributes(flags): P:1, U/S: 1， R/W: 1. */
    mov     $(PG_P | PG_USU | PG_RWW), %eax
SP.2:
    stosl                   /* Store %eax to %es:%edi consecutively. */
    add     $4096, %eax     /* Pages are in sequential format. */
    loop    SP.2            /* %ecx loops. */

    mov     $(PageDirBase0), %eax
    mov     %eax, %cr3 /* Store base address of page table dir to %cr3. */
    mov     %cr0, %eax
    or      $0x80000000, %eax
    mov     %eax, %cr0 /* Enable paging bit in %cr0. */
    ret

/* Display system address map. */
DispAddrMap:
    push    %esi
    push    %edi
    push    %ecx

    mov     $(AddrMapBuf), %esi  /* int *p = AddrMapBuf;                     */
    mov     (AMECount), %ecx     /* for (int i=0; i<AMECount; i++) {         */
DMS.loop:
    mov     $5, %edx             /*   int j = 5;                             */
    mov     $(ARDStruct), %edi   /*   int *q = (int *)ARDStruct;             */
DMS.1:
    push    (%esi)               /*   do {                                   */
    call    DispInt              /*     printf("%xh", *p);                   */
    pop     %eax
    stosl                        /*     *q++ = *p;                           */
    add     $4, %esi             /*     p++;                                 */
    dec     %edx                 /*     j--;                                 */
    cmp     $0, %edx
    jnz     DMS.1                /*   } while(j != 0);                       */
    call    DispLF               /*   printf("\n");                          */
    cmpl    $1, (Type)           /*   if (Type == AddressRangMemory){        */
    jne     DMS.2
    mov     (BaseAddrLow), %eax  /*     if(ARDStruct.BaseAddrLow             */
    add     (LengthLow), %eax    /*        + ARDStruct.LengthLow             */
    cmp     (MemSize), %eax      /*        > MemSize){                       */
    jb      DMS.2                /*       MemSize = BaseAddrLow + LengthLow; */
    mov     %eax, (MemSize)      /*     }                                    */
DMS.2:                           /*   }                                      */
    loop    DMS.loop             /* }                                        */

    call    DispLF               /* printf("\n");                            */
    push    $(RAMSizeMes)
    call    DispStr              /* printf("%s", RAMSizeMes);                */
    add     $4, %esp

    pushl   (MemSize)
    call    DispInt              /* printf("%x", MemSize);                   */
    add     $4, %esp
    call    DispLF               /* printf("\n");                            */

    pop     %ecx
    pop     %edi
    pop     %esi
    ret

PSwitch:
    /* Init page table directories, %ecx entries. */
    mov     $(SelectorFlatRW), %ax
    mov     %ax, %es
    mov     $(PageDirBase1), %edi
    xor     %eax, %eax
    /* Set PDE attributes(flags): P: 1, U/S: 1, R/W: 1. */
    mov     $(PageTblBase1 | PG_P | PG_USU | PG_RWW), %eax
    mov     (PabeTableNum), %ecx
PSwitch.1:
    stosl                   /* Store %eax to %es:%edi consecutively. */
    add     $4096, %eax     /* Page tables are in sequential format. */
    loop    PSwitch.1       /* %ecx loops. */

    /* Init page tables, %ecx*1024 pages. */
    mov     (PabeTableNum), %eax /* Get saved ecx(number of PDE) */
    mov     $1024, %ebx
    mul     %ebx            /* Loop counter, num of pages: 1024*%ecx. */
    mov     %eax, %ecx
    mov     $(PageTblBase1), %edi
    /* Set PTE attributes(flags): P:1, U/S: 1， R/W: 1. */
    mov     $(PG_P | PG_USU | PG_RWW), %eax
PSwitch.2:
    stosl                   /* Store %eax to %es:%edi consecutively. */
    add     $4096, %eax     /* Pages are in sequential format. */
    loop    PSwitch.2       /* %ecx loops. */

    /* Assume memory is larger than 8 MB. */
    mov    $(LinearAddrDemo), %eax
    shr    $22, %eax
    mov    $4096, %ebx
    mul    %ebx
    mov    %eax, %ecx
    mov    $(LinearAddrDemo), %eax
    shr    $12, %eax
    and    $0x3ff, %eax
    mov    $4, %ebx
    mul    %ebx
    add    %ecx, %eax
    add    $(PageTblBase1), %eax
    movl   $(ProcBar | PG_P | PG_USU | PG_RWW), %es:(%eax)

    mov    $(PageDirBase1), %eax
    mov    %eax, %cr3

    ret

PagingDemo:
    mov     %cs, %ax
    mov     %ax, %ds
    mov     $(SelectorFlatRW), %ax
    mov     %ax, %es

    pushl   $(FooLen)
    pushl   $(FooOffset)
    pushl   $(ProcFoo)
    call    MemCpy
    add     $12, %esp

    pushl   $(BarLen)
    pushl   $(BarOffset)
    pushl   $(ProcBar)
    call    MemCpy
    add     $12, %esp

    pushl   $(PagingDemoAllLen)
    pushl   $(PagingDemoProcOffset)
    pushl   $(ProcPagingDemo)
    call    MemCpy
    add     $12, %esp

    mov     $(SelectorData), %ax
    mov     %ax, %ds /* Data segment selector */
    mov     %ax, %es

    /* Test show it's right. */
    call    SetupPaging                         /* Start paging*/
    lcall   $(SelectorFlatC), $(ProcPagingDemo)
    call    PSwitch                             /* Swith paging */
    lcall   $(SelectorFlatC), $(ProcPagingDemo)
    ret

PagingDemoProc:
.set    PagingDemoProcOffset, (. - LABEL_SEG_CODE32)
    mov     $(LinearAddrDemo), %eax
    call    *%eax
    lret
.set    PagingDemoAllLen, (. - PagingDemoProc)

foo:
.set    FooOffset, (. - LABEL_SEG_CODE32)
    mov    $0xc, %ah            /* 0000: background black, 1100: font red */
    mov    $'F', %al
    mov    %ax, %gs:((80 * 12 + 3) * 2)    /* Line 18, column 0 */
    mov    $'o', %al
    mov    %ax, %gs:((80 * 12 + 4) * 2)    /* Line 18, column 1 */
    mov    %ax, %gs:((80 * 12 + 5) * 2)    /* Line 18, column 2 */
    ret
.set    FooLen, (. - foo)

bar:
.set    BarOffset, (. - LABEL_SEG_CODE32)
    mov    $0xc, %ah            /* 0000: background black, 1100: font red */
    mov    $'B', %al
    mov    %ax, %gs:((80 * 12 + 7) * 2)    /* Line 18, column 0 */
    mov    $'a', %al
    mov    %ax, %gs:((80 * 12 + 8) * 2)    /* Line 18, column 1 */
    mov    $'r', %al
    mov    %ax, %gs:((80 * 12 + 9) * 2)    /* Line 18, column 2 */
    ret
.set    BarLen, (. - bar)

#include "lib.h"
