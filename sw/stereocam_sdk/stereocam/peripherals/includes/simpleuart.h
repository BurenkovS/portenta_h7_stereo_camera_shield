/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		simpleuart.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Simple UART Peripheral.
 ******************************************************************************************
 */

#ifndef __SIMPLE_UART_H
#define __SIMPLE_UART_H

/* Includes --------------------------------------------------------------------- */
#include "picorv32.h"

/* Functions --------------------------------------------------------------------- */
void uart_init(uint32_t BaudRate);
void uart_putchar(char c);
int outbyte(int c);
char getchar_prompt(char *prompt);
char uart_getchar();

#endif
