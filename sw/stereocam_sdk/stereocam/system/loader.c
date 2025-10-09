/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		loader.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Loader.
 ******************************************************************************************
 */

/* Includes --------------------------------------------------------------------- */
#include "config.h"
#include "picorv32.h"

#if BUILD_MODE == BUILD_BURN

void boot(void) __attribute__((section(".btsec")));
void loader(void) __attribute__((section(".ldsec")));


void boot(void)
{
	extern int _lma_ldsec_start;
	extern int _lma_ldsec_end;
	extern int _vsloader;

	unsigned int *src_ptr = (unsigned int *)(&_lma_ldsec_start);
	unsigned int *src_ptr_end = (unsigned int *)(&_lma_ldsec_end);
	unsigned int *dst_ptr = (unsigned int *)(&_vsloader);

	src_ptr += 0x4100000;
	src_ptr_end += 0x4100000;

	while(1)
	{
		*dst_ptr = *src_ptr;
		if(src_ptr == src_ptr_end)
		{
			break;
		}
		dst_ptr++;
		src_ptr++;
	}
	__asm__ __volatile__("la t3, _vsloader");
	__asm__ __volatile__("jr t3");
}

void loader(void)
{
	extern int _cp_text_start;
	extern int _cp_text_end;
	extern int _vstext;

	extern int _cp_data_start;
	extern int _cp_data_end;
	extern int _sdata;

	unsigned int *src_ptr = (unsigned int *)((&_cp_text_start));
	unsigned int *src_ptr_end = (unsigned int *)((&_cp_text_end));
	unsigned int *dst_ptr = (unsigned int *)(&_vstext);

	while(1)
	{
		*dst_ptr = *src_ptr;
		if(src_ptr == src_ptr_end)
		{
			break;
		}
		dst_ptr++;
		src_ptr++;
	}

	src_ptr = (unsigned int *)((&_cp_data_start));
	src_ptr_end = (unsigned int *)((&_cp_data_end));
	dst_ptr = (unsigned int *)(&_sdata);

	while(1)
	{
		*dst_ptr = *src_ptr;
		if(src_ptr == src_ptr_end)
		{
			break;
		}
		dst_ptr++;
		src_ptr++;
	}


	__asm__ __volatile__("la t3, _vstext");
	__asm__ __volatile__("jr t3");

}

#endif
