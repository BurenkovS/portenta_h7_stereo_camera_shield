/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbgpio.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone GPIO Peripheral.
 ******************************************************************************************
 */

#ifndef __WB_GPIO_H
#define __WB_GPIO_H

/* Includes ------------------------------------------------------------------*/
#include "picorv32.h"

/* Macros ------------------------------------------------------------------*/
#define WBGPIO_BIT_DIR_OUT 1UL
#define WBGPIO_BIT_DIR_IN  0UL

/* Functions --------------------------------------------------------------------- */
void GPIO_Init(WBGPIO_RegDef* GPIOx);
uint32_t GPIO_GetDir(WBGPIO_RegDef* GPIOx);
void GPIO_SetDir(WBGPIO_RegDef* GPIOx, uint32_t dir);
void GPIO_EnableWriteBit(WBGPIO_RegDef* GPIOx, uint32_t bit);//enable output bit
void GPIO_WriteData(WBGPIO_RegDef* GPIOx, uint32_t data);//output
void GPIO_EnableReadBit(WBGPIO_RegDef* GPIOx, uint32_t bit);//enable input bit
uint32_t GPIO_ReadData(WBGPIO_RegDef* GPIOx);//input

#endif
