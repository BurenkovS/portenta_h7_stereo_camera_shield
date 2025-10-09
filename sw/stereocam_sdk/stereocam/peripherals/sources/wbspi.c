/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbspi.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone SPI Peripheral.
 ******************************************************************************************
 */

/* Includes --------------------------------------------------------------------- */
#include "wbspi.h"

/* Functions --------------------------------------------------------------------- */
uint32_t wbspi_master_select_slave(WBSPI_RegDef *WBSPI, uint32_t slave_num)
{
	if(slave_num > SLAVE_NUM_MAX)
		return -1;
	WBSPI->SSMASK = (1UL << slave_num);
	return 0;
}

uint32_t wbspi_enable_interrupt(WBSPI_RegDef *WBSPI, uint32_t interrupt_id)
{
	WBSPI->CONTROL |= interrupt_id;
	return WBSPI->CONTROL;
}

uint32_t wbspi_disable_interrupt(WBSPI_RegDef *WBSPI, uint32_t interrupt_id)
{
	WBSPI->CONTROL &= (~interrupt_id);
	return WBSPI->CONTROL;
}

uint32_t wbspi_master_txdata(WBSPI_RegDef *WBSPI, uint32_t txdata)
{
	while (!(WBSPI->STATUS & (1UL << 5))) ;
	WBSPI->TXDATA = txdata;
	while (!(WBSPI->STATUS & (1UL << 6))) ;
	uint32_t master_rx_data = WBSPI->RXDATA;
	return master_rx_data;
}

uint32_t wbspi_master_rxdata(WBSPI_RegDef *WBSPI)
{
	uint32_t master_rx_data = 0;
	while (!(WBSPI->STATUS & (1UL << 5))) ;
	WBSPI->TXDATA = 0x00;
	while (!(WBSPI->STATUS & (1UL << 6))) ;
	master_rx_data = WBSPI->RXDATA;
	return master_rx_data;
}

void wbspi_slave_prepare_txdata(WBSPI_RegDef *WBSPI, uint32_t txdata)
{
	while (!(WBSPI->STATUS & (1UL << 5))) ;
	WBSPI->TXDATA = txdata;
}

uint32_t wbspi_slave_read_data(WBSPI_RegDef *WBSPI)
{
	while (!(WBSPI->STATUS & (1UL << 6))) ;
	uint32_t slave_rx_data = WBSPI->RXDATA;
	return slave_rx_data;
}
