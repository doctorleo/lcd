    .arm

    .text

    .global _start
_start:
    B       reset_handler
    NOP
    NOP
    NOP
    NOP
    NOP
    B       irq_handler
    NOP

    .align 3
irq_handler:
    @ 修正PC值
    SUB     LR, LR, #4
    @ 保存寄存器到栈区
    STMFD   SP!, {R0-R12}
    MRS     R0, SPSR
    STMFD   SP!, {R0, LR}

    BL      do_irq


    LDMFD   SP!, {R0, LR}
    MSR     SPSR, R0
    LDMFD   SP!, {R0-R12}
    MOVS    PC, LR



reset_handler:
    LDR R0,=0x40008000
    MCR P15,0,R0,C12,C0,0       @ Vector Base Address Register


    /* 初始化 SVC 栈 */
    MSR     CPSR_c, #0xD3 @ F:1 I:1 Mode:0x13<SVC>
    LDR     SP, =top_svc

    /* 初始化 IRQ 栈 0b110_10010*/ 
    MSR     CPSR_c, #0xD2
    LDR     SP, =top_irq

    /* 切换到 SVC 模式并开启IRQ: 0b010_10011 */
    MSR     CPSR, #0x53

    /* 初始化 USR 栈 */

    BL      clr_bss
    @ BL      clear_bss


    BL      main



__die:
    B       __die

    /* unsigned int _r0 // Count of cleared byte,
     * clr_bss1(unsigned long start_r0, unsigned long end_r1);
     * Note: start_r0 < end_r1
     * clobber registers: R1(backup: end address), R2-R11,
     */
    .global clr_bss1
    .align 3
clr_bss1:
    STMFD   SP!, {R1-R11, LR}

1:  ANDS    R2, R0, #8
    BEQ     __start_align_8_b
    ANDS    R2, R0, #4
    BEQ     __start_align_4_b
    ANDS    R2, R0, #2
    BEQ     __start_align_2_b
    MOV     R2, #0x0

2:  CMP     R0, R1
    STRCCB  R2, [R0], #0x1
    BCC     1b
3:  LDMFD   SP!, {R1-R11, PC}

__start_align_2_b:
__start_align_4_b:
__start_align_8_b:
_start_align:
    LDR     R2, =__pad_zeros_8
    LDMIA   R2, {R4-R11}

4:  SUBS    R2, R1, R0
    BLS     3b
    CMP     R2, #32
    BCS     _start_align_32
    CMP     R2, #16
    BCS     _start_align_16
    CMP     R2, #8
    BCS     _start_align_8
    CMP     R2, #4
    BEQ     _start_align_4
    CMP     R2, #2
    BCS     _start_align_2
    B       2b


5:  CMP     R0, R1
    BCS     3b
    B       4b

_start_align_32:
    STMIA   R0!, {R4-R11}
    B       5b
_start_align_16:
    STMIA   R0!, {R4-R7}
    B       5b
_start_align_8:
    STMIA   R0!, {R4-R5}
    B       5b
_start_align_4:
    STMIA   R0!, {R4}
    B       5b
_start_align_2:
    STRH    R4, [R0]
    ADD     R0, R0, #0x2
    B       5b

    .align 3
__pad_zeros_8:
    .word   0, 0, 0, 0
__pad_zeros_4:
    .word   0, 0
__pad_zeros_2:
    .word   0, 0

    .global clr_bss
    .align 3
clr_bss:
    STMFD   SP!, {R0-R2, LR}
    MOV     R0, #0x0

    LDR     R1, =_bss_start
    LDR     R2, =_bss_end
    
1:  CMP     R1, R2
    STRLO   R0, [R1], #0x4
    BLO     1b

    LDMFD   SP!, {R0-R2, PC}

    /*
    .global raise
raise:
    BX      LR
    */

    .global delay
delay:
    STMFD   SP!, {R4-R7, LR}
    LDR     R4, =0x20000000
loop:
    SUBS    R4, R4, #0x1
    BNE     loop
    LDMFD   SP!, {R4-R7, PC}
     

    .data
    .align 3


    .space 8192
top_svc:

    .space 4096
top_irq:
