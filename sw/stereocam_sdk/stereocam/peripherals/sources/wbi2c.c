/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbi2c.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone I2C Peripheral.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "wbi2c.h"

/* Functions --------------------------------------------------------------------- */
void Delay_ms_i2c(__IO uint32_t delay_ms)
{
  for(delay_ms=delay_ms * (SYSCLKFREQ>>13); delay_ms != 0; delay_ms--);
}

void I2C_Disable(WBI2CMASTER_RegDef *I2Cx)
{
	I2Cx->CTR = ~I2C_CTR_EN;
}

void I2C_Enable(WBI2CMASTER_RegDef *I2Cx)
{
	I2Cx->CTR |= I2C_CTR_EN ;//|I2C_CTR_IEN;
}

uint16_t I2C_Rate_Set(WBI2CMASTER_RegDef *I2Cx, uint16_t Rate)
{
	uint16_t     prescal = 0;
	prescal =    (uint16_t) (SYSCLKFREQ / (5000 * Rate) - 1);
	I2Cx->PRER = (prescal & I2C_CTR_PERE);
	return       prescal;
}

uint8_t I2C_Init(WBI2CMASTER_RegDef *I2Cx, uint16_t Rate)
{
	uint16_t temp_save;
	temp_save=I2C_Rate_Set(I2Cx, Rate);
	I2C_Enable(I2Cx);

	if( (I2Cx->CTR & I2C_CTR_EN) && (I2Cx->PRER == (uint32_t)(temp_save & I2C_CTR_PERE)))
	{
		return 0;
	}
	else
		return 1;
}

void I2C_SendByte(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_address, uint8_t data)
{

	I2Cx->TXR = (slv_address << 1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR | I2C_CMD_ACK;
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here


	I2Cx->TXR = data_address;
	I2Cx->CR = (I2C_CMD_WR | I2C_CMD_ACK);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack


	I2Cx->TXR = data;
	I2Cx->CR |= (I2C_CMD_STO | I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack
	while(I2Cx->SR & I2C_SR_BUSY);
	Delay_ms_i2c(3);//Wait the data to I2C Ready
}

uint8_t I2C_ReceiveByte(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_addr, uint8_t data_addr)
{
	uint8_t data=0;
	I2Cx->TXR = (slv_addr << 1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR | I2C_CMD_ACK;
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here


	I2Cx->TXR = data_addr;
	I2Cx->CR = I2C_CMD_WR | I2C_CMD_ACK;//stop
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack


	I2Cx->TXR = (slv_addr << 1) | 1;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR | I2C_CMD_ACK;
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack


	I2Cx->CR = ((I2C_CMD_ACK) | I2C_CMD_STO | I2C_CMD_RD);//send nack
	while(I2Cx->SR & I2C_SR_TIP);
	data = I2Cx->RXR;
	Delay_ms_i2c(3);//Wait the data from I2C Ready
    return data;
}

//send a 16 bit data, dir == 1, upper byte first; dir == 0, lower byte first
void I2C_SendWord(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_address, uint16_t data, uint8_t dir)
{
	uint8_t data0 = 0;
	uint8_t data1 = 0;
	if(dir)  //send upper byte first
	{
		data0 = (uint8_t)(data >> 8);
		data1 = (uint8_t)(data & 0xff);
	}
	else  //send lower byte first
	{
		data0 = (uint8_t)(data & 0xff);
		data1 = (uint8_t)(data >> 8);
	}

	I2Cx->TXR = (slv_address << 1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR | I2C_CMD_ACK;
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here


	I2Cx->TXR = data_address;
	I2Cx->CR = (I2C_CMD_WR | I2C_CMD_ACK);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	I2Cx->TXR = data0;
	//I2Cx->CR |= (I2C_CMD_STO | I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
	I2Cx->CR = (I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack
	//while(I2Cx->SR & I2C_SR_BUSY);
	Delay_ms_i2c(3);//Wait the data to I2C Ready


	I2Cx->TXR = data1;
	I2Cx->CR |= (I2C_CMD_STO | I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack
	while(I2Cx->SR & I2C_SR_BUSY);
	Delay_ms_i2c(3);//Wait the data to I2C Ready
}

//receive a 16 bit data, dir == 1, upper byte first; dir == 0, lower byte first
uint16_t I2C_ReceiveWord(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_addr, uint8_t data_addr, uint8_t dir)
{
	uint8_t rbyte0 = 0;
	uint8_t rbyte1 = 0;
	uint16_t rword = 0;

	I2Cx->TXR = (slv_addr <<1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR;
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here

	I2Cx->TXR = data_addr;
	I2Cx->CR = I2C_CMD_WR;//stop
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	I2Cx->TXR = (slv_addr << 1) | 1;
	I2Cx->CR = (I2C_CMD_STA | I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	I2Cx->CR = ((~I2C_CMD_ACK) & I2C_CMD_RD);//send nack
	while(I2Cx->SR & I2C_SR_TIP);
	rbyte0 = (uint8_t)(I2Cx->RXR);
	Delay_ms_i2c(3);

	I2Cx->CR = (I2C_CMD_RD | I2C_CMD_STO) & (~I2C_CMD_ACK);//send nack
	while(I2Cx->SR & I2C_SR_TIP);
	rbyte1  = (uint8_t)(I2Cx->RXR);
	Delay_ms_i2c(3);

	if(dir)  //the first byte received is upper byte
	{
		rword = (((uint16_t)(rbyte0)) << 8) + rbyte1;
	}
	else  //the first byte received is lower byte
	{
		rword = (((uint16_t)(rbyte1)) << 8) + rbyte0;
	}

	return rword;
}

void I2C_SendArray(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_address, uint8_t *send_data, uint32_t send_length)
{
	uint8_t *data_ptr = send_data;
	I2Cx->TXR = (slv_address << 1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR | I2C_CMD_ACK;
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here


	I2Cx->TXR = data_address;
	I2Cx->CR = (I2C_CMD_WR | I2C_CMD_ACK);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	for(uint32_t cnt = 0; cnt < send_length - 1; cnt++)
	{
		I2Cx->TXR = *data_ptr;
		I2Cx->CR = (I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
		while(I2Cx->SR & I2C_SR_TIP);//wait TIP
		while(I2Cx->SR & I2C_SR_RXACK);//wait ack
		data_ptr++;
		Delay_ms_i2c(3);//Wait the data to I2C Ready
	}

	I2Cx->TXR = *data_ptr;
	I2Cx->CR |= (I2C_CMD_STO | I2C_CMD_WR | I2C_CMD_ACK);//I2C_CMD_WR;//(I2C_CMD_STO|I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack
	while(I2Cx->SR & I2C_SR_BUSY);
	Delay_ms_i2c(3);//Wait the data to I2C Ready
}

void I2C_ReceiveArray(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_addr, uint8_t data_addr, uint8_t *receive_buffer, uint32_t receive_length)
{
	uint8_t *buffer_ptr = receive_buffer;
	I2Cx->TXR = (slv_addr <<1) | 0;
	I2Cx->CR = I2C_CMD_STA | I2C_CMD_WR;
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack-----Over Here

	I2Cx->TXR = data_addr;
	I2Cx->CR = I2C_CMD_WR;//stop
	while(I2Cx->SR & I2C_SR_TIP);//wait TIP
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	I2Cx->TXR = (slv_addr << 1) | 1;
	I2Cx->CR = (I2C_CMD_STA | I2C_CMD_WR);
	while(I2Cx->SR & I2C_SR_TIP);
	while(I2Cx->SR & I2C_SR_RXACK);//wait ack

	for(uint32_t cnt = 0; cnt < receive_length - 1; cnt++)
	{
		I2Cx->CR = ((~I2C_CMD_ACK) & I2C_CMD_RD);//send nack
		while(I2Cx->SR & I2C_SR_TIP);
		*buffer_ptr = (uint8_t)(I2Cx->RXR);
		buffer_ptr++;
		Delay_ms_i2c(3);
	}

	I2Cx->CR = (I2C_CMD_RD | I2C_CMD_STO) & (~I2C_CMD_ACK);//send nack
	while(I2Cx->SR & I2C_SR_TIP);
	*buffer_ptr  = (uint8_t)(I2Cx->RXR);
	Delay_ms_i2c(3);

	return;
}

void I2C_SendBytes(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_start_address, uint8_t *data, int32_t data_num)
{
	int32_t i;
	for(i = 0; i < data_num; i++)
	{
		I2C_SendByte(I2Cx, slv_address, (data_start_address + i), data[i]);
	}
}

void I2C_ReadBytes(WBI2CMASTER_RegDef *I2Cx, uint8_t slv_address, uint8_t data_start_address, uint8_t *data, int32_t data_num)
{
	int32_t i;
	for(i = 0; i < data_num; i++)
	{
		data[i] = I2C_ReceiveByte(I2Cx, slv_address, (data_start_address + i));
	}
}

void I2C_InterruptOpen(WBI2CMASTER_RegDef *I2Cx)
{
	I2Cx->CTR = I2C_CTR_IEN;
}

void I2C_InterruptClose(WBI2CMASTER_RegDef *I2Cx)
{
	I2Cx->CTR &= ~I2C_CTR_IEN;
}
