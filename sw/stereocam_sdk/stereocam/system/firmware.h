/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		firmware.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Firmware.
 ******************************************************************************************
 */

#ifndef __FIRMWARE_H
#define __FIRMWARE_H

/* Includes --------------------------------------------------------------------- */
#include "config.h"
#include <stdint.h>

/* Functions --------------------------------------------------------------------- */
void stats(void);

#if BUILD_MODE == BUILD_XIP
unsigned int delay( unsigned int delay_cycles) __attribute__((optimize("O0"), section(".delay"))) ;
#else
unsigned int delay( unsigned int delay_cycles) __attribute__((optimize("O0"))) ;
#endif

void memset_32(uint32_t* dest, uint32_t data, uint32_t length);//length is 32bit

#endif
