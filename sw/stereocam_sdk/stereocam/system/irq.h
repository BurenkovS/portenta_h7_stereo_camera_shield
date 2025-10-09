/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		irq.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Interrupt Request.
 ******************************************************************************************
 */

#ifndef __IRQ_H
#define __IRQ_H

/* Includes --------------------------------------------------------------------- */
#include <stdint.h>

/* Functions --------------------------------------------------------------------- */
//uint32_t *irq(uint32_t *regs, uint32_t irqs) __attribute__((section(".irqsec")));
uint32_t *irq(uint32_t *regs, uint32_t irqs);
uint32_t set_timer(uint32_t timer_val)  __attribute__((optimize("O0")));
void mask_irq(uint32_t mask)  __attribute__((optimize("O0")));
void irq_mask_one_bit(uint32_t irq)  __attribute__((optimize("O0")));
void irq_unmask_one_bit(uint32_t irq)  __attribute__((optimize("O0")));

#endif
