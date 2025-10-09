/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbgpio.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone GPIO Peripheral.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "wbgpio.h"

/* Functions --------------------------------------------------------------------- */
void GPIO_Init(WBGPIO_RegDef* GPIOx)
{
	GPIOx->CFG = 0;
	GPIOx->IE = 0;
	GPIOx->DIR = 0;
	GPIOx->IN = 0;
	GPIOx->OUT = 0;
}

uint32_t GPIO_GetDir(WBGPIO_RegDef* GPIOx)
{
	return GPIOx->DIR;
}

void GPIO_SetDir(WBGPIO_RegDef* GPIOx, uint32_t dir)
{
	GPIOx->DIR = dir;
}

void GPIO_EnableWriteBit(WBGPIO_RegDef* GPIOx, uint32_t bit)
{
	uint32_t tmp = GPIOx->DIR;
	tmp = tmp | (1UL << bit);
	GPIOx->DIR = tmp;
}

void GPIO_EnableReadBit(WBGPIO_RegDef* GPIOx, uint32_t bit)
{
	uint32_t tmp = GPIOx->DIR;
	tmp = tmp & (~(1UL << bit));
	GPIOx->DIR = tmp;
}

void GPIO_WriteData(WBGPIO_RegDef* GPIOx, uint32_t data)
{
	GPIOx->OUT = data;
}

uint32_t GPIO_ReadData(WBGPIO_RegDef* GPIOx)
{
	return GPIOx->IN;
}
