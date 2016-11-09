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

    LDR     R2, =__pad_zeros_8
    LDMIA   R2, {R4-R11}

1:  SUBS    R2, R1, R0
    BLS     3f
    CMP     R2, #32
    BCS     __start_align_32_b
    CMP     R2, #16
    BCS     __start_align_16_b
    CMP     R2, #8
    BCS     __start_align_8_b
    CMP     R2, #4
    BCS     __start_align_4_b
    CMP     R2, #2
    BCS     __start_align_2_b

2:  @ MOV     R4, #0x0
    CMP     R0, R1
    STRCCB  R4, [R0], #0x1
    BCC     1b
3:  LDMFD   SP!, {R1-R11, PC}

__start_align_32_b:
__start_align_16_b:
__start_align_8_b:
__start_align_4_b:
    TST    R0, #3
    BEQ     __start_addr_align_4
__start_align_2_b:
    TST    R0, #1
    BEQ     __start_addr_align_2
    B       2b

__start_addr_align_4:
    CMP     R2, #32
    BCS     __start_a4_cnt32
    CMP     R2, #16
    BCS     __start_a4_cnt16
    CMP     R2, #8
    BCS     __start_a4_cnt8
    CMP     R2, #4
    BCS     __start_a4_cnt4

    CMP     R2, #2
    BCS     __start_addr_align_2
    B       1b
__start_addr_align_2:
    STRH    R4, [R0]
    ADD     R0, R0, #0x2
    @ B       4b


4:  SUBS    R2, R1, R0
    BLS     3b
    B       __start_addr_align_4

__start_a4_cnt4:
    STMIA   R0!, {R4}
    B       4b
__start_a4_cnt8:
    STMIA   R0!, {R4-R5}
    B       4b
__start_a4_cnt16:
    STMIA   R0!, {R4-R7}
    B       4b
__start_a4_cnt32:
    STMIA   R0!, {R4-R11}
    B       4b

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
