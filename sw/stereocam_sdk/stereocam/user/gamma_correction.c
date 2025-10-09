/*
 * gamma_correction.c
 *
 *  Created on: 23 сент. 2025 г.
 *      Author: user
 */
#include "gamma_correction.h"

void write_gamma(uint8_t offset, uint8_t value)
{
	uint8_t* params_ptr = (uint8_t*)(GAMMA_TABLE_OFFSET+offset*4);
	*params_ptr = value;
}
