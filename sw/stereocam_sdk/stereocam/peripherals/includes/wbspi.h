/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		wbspi.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Wishbone SPI Peripheral.
 ******************************************************************************************
 */

#ifndef __WB_SPI_H
#define __WB_SPI_H

/* Includes --------------------------------------------------------------------- */
#include "picorv32.h"

/* Macros --------------------------------------------------------------------- */
#define SLAVE_NUM_MAX 8

//bit definition of CONTROL register
#define IROE     (1UL << 0)
#define ITOE     (1UL << 1)
#define ITRDY    (1UL << 3)
#define IRRDY    (1UL << 4)
#define IE       (1UL << 5)
#define SSO      (1UL << 7)

//bit definition of STATUS register
#define ROE      (1UL << 2)
#define TOE      (1UL << 3)
#define TMT      (1UL << 4)
#define TRDY     (1UL << 5)
#define RRDY     (1UL << 6)
#define ERROR    (1UL << 7)

/* Functions --------------------------------------------------------------------- */
uint32_t wbspi_master_select_slave(WBSPI_RegDef *WBSPI, uint32_t slave_id);
uint32_t wbspi_enable_interrupt(WBSPI_RegDef *WBSPI, uint32_t interrupt_id);
uint32_t wbspi_disable_interrupt(WBSPI_RegDef *WBSPI, uint32_t interrupt_id);
uint32_t wbspi_master_txdata(WBSPI_RegDef *WBSPI, uint32_t txdata);
uint32_t wbspi_master_rxdata(WBSPI_RegDef *WBSPI);
void wbspi_slave_prepare_txdata(WBSPI_RegDef *WBSPI, uint32_t txdata);
uint32_t wbspi_slave_read_data(WBSPI_RegDef *WBSPI);

#endif
