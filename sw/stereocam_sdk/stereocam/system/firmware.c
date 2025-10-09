/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		firmware.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Firmware.
 ******************************************************************************************
 */

/* Includes --------------------------------------------------------------------- */
#include "firmware.h"
#include "picorv32.h"
#include "wbuart.h"

/* Macros --------------------------------------------------------------------- */
#ifdef USE_WBUART
#define put_char(c) wbuart_outbyte(c)
#else
#define put_char(c) outbyte(c)
#endif

/* Functions --------------------------------------------------------------------- */
static void stats_print_dec(unsigned int val, int digits, bool zero_pad)
{
	char buffer[32];
	char *p = buffer;
	while (val || digits > 0)
	{
		if (val)
			*(p++) = '0' + val % 10;
		else
			*(p++) = zero_pad ? '0' : ' ';
		val = val / 10;
		digits--;
	}
	while (p != buffer)
	{
		if (p[-1] == ' ' && p[-2] == ' ') p[-1] = '.';
		put_char(*(--p));
		//printf("%c", *(--p));
	}
}

void stats(void)
{
	unsigned int num_cycles, num_instr;
	__asm__ volatile ("rdcycle %0; rdinstret %1;" : "=r"(num_cycles), "=r"(num_instr));
	printf("\r\n-------------------------------------\r\n");
	printf("Running status: \r\n");
	printf("Cycle counter ........: %u\r\n", num_cycles);
	printf("Instruction counter ..: %u\r\n", num_instr);

	printf("CPI: ");
	stats_print_dec((num_cycles / num_instr), 0, false);
	printf(".");
	stats_print_dec(((100 * num_cycles) / num_instr) % 100, 2, true);
	printf("\r\n");
	printf("-------------------------------------\r\n");
	printf("\r\n");
}

unsigned int delay( unsigned int delay_cycles)
{
    unsigned int cycles_current;
    unsigned int cycles_start;
    unsigned int cycles = 0;
    __asm__ volatile ("rdcycle %0;" : "=r"(cycles_start));


    do
    {
        __asm__ volatile ("rdcycle %0;" : "=r"(cycles_current));
        cycles = cycles_current - cycles_start;
    } while(cycles < delay_cycles);

    return cycles;
}

void memset_32(uint32_t* dest, uint32_t data, uint32_t length) //length in 32bit
{
	uint32_t* dest_end = dest + 4 * length;
	while(dest != dest_end)
	{
		*dest++ = data;
	}
}
