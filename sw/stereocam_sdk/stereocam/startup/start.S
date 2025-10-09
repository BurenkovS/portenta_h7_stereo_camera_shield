/*
 *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		start.S
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Startup
 ******************************************************************************************
 */
 
#include "custom_ops.S"
#include "config.h"

#if BUILD_MODE == BUILD_XIP
#define irq_regs  0x01000000
#define irq_stack 0x01000280
#endif

	.section .text
	.global irq

reset_vec:
#no more than 16 bytes here !
	j start

/********************************** Interrupt handler **********************************/

.balign 16
irq_vec:
# save registers
#    csrrci t5, mstatus, 0x8   //disable all interrupt
	picorv32_setq_insn(q2, x1)
	picorv32_setq_insn(q3, x2)

	addi x1, x2, -128

	picorv32_getq_insn(x2, q3)   //store x2
	sw x2,   2*4(x1)
	picorv32_getq_insn(x2, q0)   //store q0
	sw x2,   0*4(x1)
	picorv32_getq_insn(x2, q2)   //store x1
	sw x2,   1*4(x1)

	mv x2, x1                    //update sp

	sw x3,   3*4(x1)
	sw x4,   4*4(x1)
	sw x5,   5*4(x1)
	sw x6,   6*4(x1)
	sw x7,   7*4(x1)
	sw x8,   8*4(x1)
	sw x9,   9*4(x1)
	sw x10, 10*4(x1)
	sw x11, 11*4(x1)
	sw x12, 12*4(x1)
	sw x13, 13*4(x1)
	sw x14, 14*4(x1)
	sw x15, 15*4(x1)
	sw x16, 16*4(x1)
	sw x17, 17*4(x1)
	sw x18, 18*4(x1)
	sw x19, 19*4(x1)
	sw x20, 20*4(x1)
	sw x21, 21*4(x1)
	sw x22, 22*4(x1)
	sw x23, 23*4(x1)
	sw x24, 24*4(x1)
	sw x25, 25*4(x1)
	sw x26, 26*4(x1)
	sw x27, 27*4(x1)
	sw x28, 28*4(x1)
	sw x29, 29*4(x1)
	sw x30, 30*4(x1)
	sw x31, 31*4(x1)

# arg0 = address of regs
	mv a0, x1

# arg1 = interrupt type
	picorv32_getq_insn(a1, q1)

# call to C function
	jal ra, irq


# restore registers
# new irq_regs address returned from C code in a0
	addi x1, x2, 0

	lw x2,   0*4(x1)
	picorv32_setq_insn(q0, x2)

	lw x2,   1*4(x1)
	picorv32_setq_insn(q1, x2)

	lw x2,   2*4(x1)
	picorv32_setq_insn(q2, x2)

	lw x3,   3*4(x1)
	lw x4,   4*4(x1)
	lw x5,   5*4(x1)
	lw x6,   6*4(x1)
	lw x7,   7*4(x1)
	lw x8,   8*4(x1)
	lw x9,   9*4(x1)
	lw x10, 10*4(x1)
	lw x11, 11*4(x1)
	lw x12, 12*4(x1)
	lw x13, 13*4(x1)
	lw x14, 14*4(x1)
	lw x15, 15*4(x1)
	lw x16, 16*4(x1)
	lw x17, 17*4(x1)
	lw x18, 18*4(x1)
	lw x19, 19*4(x1)
	lw x20, 20*4(x1)
	lw x21, 21*4(x1)
	lw x22, 22*4(x1)
	lw x23, 23*4(x1)
	lw x24, 24*4(x1)
	lw x25, 25*4(x1)
	lw x26, 26*4(x1)
	lw x27, 27*4(x1)
	lw x28, 28*4(x1)
	lw x29, 29*4(x1)
	lw x30, 30*4(x1)
	lw x31, 31*4(x1)
	picorv32_getq_insn(x1, q1)
	picorv32_getq_insn(x2, q2)
	picorv32_retirq_insn()

	.globl start
	.type start,@function

start:
# for debug test
# zero-initialize register file
	addi x1, zero, 0
# x2 (sp) is initialized by reset
	addi x3, zero, 0
	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0

# initialize control and status registers
	csrw mepc,        zero
	csrw mcause,      zero
	csrw mscratch,    zero
	csrw mtval,       zero

#if BUILD_MODE != BUILD_BURN
# while using build_burn mode, the data section in dtcm will be set by boot loader function.
# copy data section
	la a0, _sidata
	la a1, _sdata
	la a2, _edata
	bge a1, a2, end_init_data
loop_init_data:
	lw a3, 0(a0)
	sw a3, 0(a1)
	addi a0, a0, 4
	addi a1, a1, 4
	blt a1, a2, loop_init_data
end_init_data:
#endif


# zero-init bss section
	la a0, _sbss
	la a1, _ebss
	bge a0, a1, end_init_bss
loop_init_bss:
	sw zero, 0(a0)
	addi a0, a0, 4
	blt a0, a1, loop_init_bss
end_init_bss:


#if BUILD_MODE == BUILD_XIP
# while using build xip mode, some spi flash driver function will be moved to itcm and run there, to avoid confliction in spi arbitrater.
# the delay function will also be moved to itcm, for more pricise delay.
# copy irqsec section
	la a0, _cps_irqsec
	la a1, _vsirqsec
	la a2, _veirqsec
init_irqsec:
	lw a3, 0(a0)
	sw a3, 0(a1)
	addi a0, a0, 4
	addi a1, a1, 4
	blt a1, a2, init_irqsec
#endif


# jump to main C code
	jal ra,main
1:
	j 1b

	/* trap */
	ebreak

