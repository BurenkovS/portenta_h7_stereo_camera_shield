/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbuart.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone UART Peripheral.
 ******************************************************************************************
 */

#ifndef __WB_UART_H
#define __WB_UART_H

/* Includes --------------------------------------------------------------------- */
#include "picorv32.h"

/* Macros --------------------------------------------------------------------- */
uint32_t wbuart_init(unsigned int BaudRate);
int wbuart_putc(int c);
int wbuart_getc();
int wbuart_outbyte(int c);

#endif
