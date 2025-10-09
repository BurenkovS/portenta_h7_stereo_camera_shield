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

/* Includes --------------------------------------------------------------------- */
#include "wbuart.h"

/* Functions --------------------------------------------------------------------- */
uint32_t wbuart_init(unsigned int BaudRate)
{
	uint32_t ClkDiv = SYSCLKFREQ / BaudRate;
//	PICO_WBUART->SETUP = 0x40000000 + ClkDiv;
	PICO_WBUART->SETUP = ClkDiv;
	return ClkDiv;
}

int wbuart_putc(int c)
{
	while((PICO_WBUART->TXREG) & (1UL << 8));
	uint32_t tmp = PICO_WBUART->TXREG & (~0xff);
	PICO_WBUART->TXREG = tmp + (c & 0xff);
	return c;
}

int wbuart_getc()
{
	uint8_t tmp = 0;
	while((PICO_WBUART->RXREG) & (1UL << 8));
	tmp = (PICO_WBUART->RXREG) & 0xff;
	return tmp;
}

int wbuart_outbyte(int c)
{
	wbuart_putc(c);
	if (c =='\n')
		wbuart_putc('\r');
	return c;
}
