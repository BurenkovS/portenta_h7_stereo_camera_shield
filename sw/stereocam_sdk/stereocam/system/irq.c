/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		irq.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Interrupt request.
 ******************************************************************************************
 */

/* Includes --------------------------------------------------------------------- */
#include <stdio.h>
#include "firmware.h"
#include "simpleuart.h"
#include "picorv32.h"
#include "wbuart.h"
#include "irq.h"
#include "config.h"
#include "globals.h"

/* Variables --------------------------------------------------------------------- */
uint32_t irq_mask = 0xffffffff;   //a global variable to save irq mask values.
uint32_t tmp = 0;
uint32_t val = 0;

/* Macros --------------------------------------------------------------------- */
#ifdef USE_WBUART
#define get_char()  wbuart_getc()
#define put_char(c)  wbuart_putc(c)
#else
#define get_char()  uart_getchar()
#define put_char(c)  uart_putchar(c)
#endif

/* Functions --------------------------------------------------------------------- */
void default_irq_handler(void)
{
	printf("Default interrupt handler\n");
}

/* Interrupt Handler */
//System Interrupt Handler
void timer_handler(void) __attribute__((weak, alias("default_irq_handler")));//0: timer interrupt
//void irq_1_handler(void) __attribute__((weak, alias("default_irq_handler")));//1: debug breakpoint interrupt
//void irq_2_handler(void) __attribute__((weak, alias("default_irq_handler")));//2: bus error interrupt
//void irq_3_handler(void) __attribute__((weak, alias("default_irq_handler")));//3: illegal instruction interrupt
//void irq_4_handler(void) __attribute__((weak, alias("default_irq_handler")));//4: debug interrupt
//void irq_5_handler(void) __attribute__((weak, alias("default_irq_handler")));//5: hardware stack protection interrupt

//Peripherals Interrupt Handler
//void irq_10_handler(void) __attribute__((weak, alias("default_irq_handler")));//10: Wishbone SPI Master Interrupt Handler
//void irq_11_handler(void) __attribute__((weak, alias("default_irq_handler")));//11: Wishbone SPI Slave Interrupt Handler
//void irq_12_handler(void) __attribute__((weak, alias("default_irq_handler")));//12: Wishbone I2C Master Interrupt Handler

//External User Interrupt Handler
//For Open Wishbone Interface and Open AHB Interface Interrupt Handler
//20~31
//void irq_20_handler(void) __attribute__((weak, alias("default_irq_handler")));//20:
void irq_21_handler(void) __attribute__((weak, alias("default_irq_handler")));//21:
//...																		  //22~31:

// ****************************************************************
// Прерывание от i2c-слейва
// ****************************************************************
void irq_20_handler(void)
{
	semaphore_i2c_irq = 1;
	return;
}

void mask_irq(uint32_t mask)
{
	//uint32_t old_mask;
	__asm__ __volatile__("mv a4, a0");
	__asm__ __volatile__(".word(0x0607678b)");
	return;
}

void irq_mask_one_bit(uint32_t irq)
{
	irq_mask = irq_mask | (1 << irq);
	mask_irq(irq_mask);
}

void irq_unmask_one_bit(uint32_t irq)
{
	irq_mask = irq_mask & (~(1 << irq));
	mask_irq(irq_mask);
}

uint32_t set_timer(uint32_t timer_val)
{
	uint32_t old_val = 0;
	__asm__ __volatile__("mv a4, a0");
	__asm__ __volatile__(".word(0x0a07078b)");
	__asm__ __volatile__("mv %[dest], a5"  :[dest]"=r"(old_val));
	return old_val;
}

uint32_t *irq(uint32_t *regs, uint32_t irqs)
{

	irq_mask = irq_mask | irqs;  //mask up the running interrupt
	mask_irq(irq_mask);

	if ((irqs & 1) != 0)
	{
		timer_handler();
		printf("timer\n");
	}

	if ((irqs & (1<<20)) != 0)
	{
		irq_20_handler();
	}

	if ((irqs & (1<<21)) != 0)
	{
		irq_21_handler();
		printf("irq21\n");
	}


	if ((irqs & 14) != 0)
	{
		uint32_t pc = (regs[0] & 1) ? regs[0] - 3 : regs[0] - 4;
		uint32_t instr = *(uint16_t*)pc;

		if ((instr & 3) == 3)
			instr = instr | (*(uint16_t*)(pc + 2)) << 16;

		if ((irqs & 0x8) != 0)
		{
			printf("Illegal Ins at 0x");
			printf("%x\n", pc);
			printf(": 0x");
			printf("%x\n", instr, ((instr & 3) == 3) ? 8 : 4);
		}


		if ((irqs & 4) != 0) 
		{
			printf("Bus error at 0x");
			printf("%x\n", pc);
			printf(": 0x");
			printf("%x\n", instr, ((instr & 3) == 3) ? 8 : 4);
		}

#ifndef SIMU
		for (int i = 0; i < 8; i++)
		{
			for (int k = 0; k < 4; k++)
			{
				int r = i + k*8;

				if (r == 0)
				{
					printf("pc ");
				}
				else
				{
					printf("x%d", r);
				}
				if (0 < r && r < 10)
				{
					printf(" ");
				}

				printf(" %08x", regs[r]);
				printf(k == 3 ? "\n" : "\t");
			}
		}
#endif
	}

	irq_mask = irq_mask & (~irqs);  //unmask the finished interrupt
	mask_irq(irq_mask);

	return regs;
}


