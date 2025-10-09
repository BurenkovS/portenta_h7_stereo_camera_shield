/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbi2c.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone I2C Peripheral.
 ******************************************************************************************
 */

#ifndef __WB_I2C_H
#define __WB_I2C_H

/* Includes ------------------------------------------------------------------*/
#include "picorv32.h"

/* Macros --------------------------------------------------------------------- */
#define I2C_CTR_EN     ((uint32_t)0x00000080)
#define I2C_CTR_IEN    ((uint32_t)0x00000040)
#define I2C_CTR_PERE   ((uint32_t)0x0000FFFF)
#define I2C_CMD_IACK   ((uint32_t)0x00000001)
#define I2C_CMD_ACK    ((uint32_t)0x00000008)
#define I2C_CMD_WR     ((uint32_t)0x00000010)
#define I2C_CMD_RD     ((uint32_t)0x00000020)
#define I2C_CMD_STO    ((uint32_t)0x00000040)
#define I2C_CMD_STA    ((uint32_t)0x00000080)
#define I2C_SR_TIP     ((uint32_t)0x00000002)
#define I2C_SR_AL      ((uint32_t)0x00000020)
#define I2C_SR_BUSY    ((uint32_t)0x00000040)
#define I2C_SR_RXACK   ((uint32_t)0x00000080)

/* Functions --------------------------------------------------------------------- */
void Delay_ms_i2c(__IO uint32_t delay_ms);

uint8_t  I2C_Init(WBI2CMASTER_RegDef *I2Cx, uint16_t speed);
void     I2C_SendByte(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_data, uint8_t data_address, uint8_t data);
void     I2C_SendBytes(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_start_address, uint8_t *data, int32_t data_num);
void     I2C_ReadBytes(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_start_address, uint8_t *data, int32_t data_num);
uint8_t  I2C_ReceiveByte(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_addr, uint8_t mem_addr);
uint16_t I2C_Rate_Set(WBI2CMASTER_RegDef *I2Cx, uint16_t Rate);
void     I2C_Enable(WBI2CMASTER_RegDef *I2Cx);
void     I2C_Disable(WBI2CMASTER_RegDef *I2Cx);
void     I2C_InterruptOpen(WBI2CMASTER_RegDef *I2Cx);
void     I2C_InterruptClose(WBI2CMASTER_RegDef *I2Cx);

void I2C_SendWord(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_address, uint16_t data, uint8_t dir);
uint16_t I2C_ReceiveWord(WBI2CMASTER_RegDef *I2Cx ,uint8_t slv_addr,uint8_t data_addr, uint8_t dir);

void I2C_SendArray(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_address, uint8_t *send_data, uint32_t send_length);
void I2C_ReceiveArray(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_addr, uint8_t data_addr, uint8_t *receive_buffer, uint32_t receive_length);

#endif
