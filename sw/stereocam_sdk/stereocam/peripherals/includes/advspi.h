/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		advspi.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		ADV SPI-Flash Peripheral.
 ******************************************************************************************
 */

#ifndef __SPI_FLASH_H
#define __SPI_FLASH_H

/* Includes --------------------------------------------------------------------- */
#include "config.h"
#include "picorv32.h"

/* Macros --------------------------------------------------------------------- */

/****** SPI Control Codes *****/

#define SPI_CONTROL_Pos              0
#define SPI_CONTROL_Msk             (0xFFUL << SPI_CONTROL_Pos)


/*----- SPI Control Codes: Mode -----*/
#define SPI_MODE_INACTIVE           (0x00UL << SPI_CONTROL_Pos)     ///< SPI Inactive
#define SPI_MODE_MASTER             (0x01UL << SPI_CONTROL_Pos)     ///< SPI Master (Output on MOSI, Input on MISO); arg = Bus Speed in bps
#define SPI_MODE_SLAVE              (0x02UL << SPI_CONTROL_Pos)     ///< SPI Slave  (Output on MISO, Input on MOSI)
#define SPI_MODE_MASTER_SIMPLEX     (0x03UL << SPI_CONTROL_Pos)     ///< SPI Master (Output/Input on MOSI); arg = Bus Speed in bps
#define SPI_MODE_SLAVE_SIMPLEX      (0x04UL << SPI_CONTROL_Pos)     ///< SPI Slave  (Output/Input on MISO)


/*----- SPI Control Codes: Mode Parameters: Frame Format -----*/
#define SPI_FRAME_FORMAT_Pos         8
#define SPI_FRAME_FORMAT_Msk        (7UL << SPI_FRAME_FORMAT_Pos)
#define SPI_CPOL0_CPHA0             (0UL << SPI_FRAME_FORMAT_Pos)   ///< Clock Polarity 0, Clock Phase 0 (default)
#define SPI_CPOL0_CPHA1             (1UL << SPI_FRAME_FORMAT_Pos)   ///< Clock Polarity 0, Clock Phase 1
#define SPI_CPOL1_CPHA0             (2UL << SPI_FRAME_FORMAT_Pos)   ///< Clock Polarity 1, Clock Phase 0
#define SPI_CPOL1_CPHA1             (3UL << SPI_FRAME_FORMAT_Pos)   ///< Clock Polarity 1, Clock Phase 1
#define SPI_TI_SSI                  (4UL << SPI_FRAME_FORMAT_Pos)   ///< Texas Instruments Frame Format
#define SPI_MICROWIRE               (5UL << SPI_FRAME_FORMAT_Pos)   ///< National Microwire Frame Format


/*----- SPI Control Codes: Mode Parameters: Data Bits -----*/
#define SPI_DATA_BITS_Pos            12
#define SPI_DATA_BITS_Msk           (0x3FUL << SPI_DATA_BITS_Pos)
#define SPI_DATA_BITS(n)            (((n) & 0x3F) << SPI_DATA_BITS_Pos) ///< Number of Data bits


/*----- SPI Control Codes: Mode Parameters: Bit Order -----*/
#define SPI_BIT_ORDER_Pos            18
#define SPI_BIT_ORDER_Msk           (1UL << SPI_BIT_ORDER_Pos)
#define SPI_MSB_LSB                 (0UL << SPI_BIT_ORDER_Pos)      ///< SPI Bit order from MSB to LSB (default)
#define SPI_LSB_MSB                 (1UL << SPI_BIT_ORDER_Pos)      ///< SPI Bit order from LSB to MSB

/*----- SPI Control Codes: Mode Parameters: Slave Select Mode -----*/
#define SPI_SS_MASTER_MODE_Pos       19
#define SPI_SS_MASTER_MODE_Msk      (3UL << SPI_SS_MASTER_MODE_Pos)
#define SPI_SS_MASTER_UNUSED        (0UL << SPI_SS_MASTER_MODE_Pos) ///< SPI Slave Select when Master: Not used (default)
#define SPI_SS_MASTER_SW            (1UL << SPI_SS_MASTER_MODE_Pos) ///< SPI Slave Select when Master: Software controlled
#define SPI_SS_MASTER_HW_OUTPUT     (2UL << SPI_SS_MASTER_MODE_Pos) ///< SPI Slave Select when Master: Hardware controlled Output
#define SPI_SS_MASTER_HW_INPUT      (3UL << SPI_SS_MASTER_MODE_Pos) ///< SPI Slave Select when Master: Hardware monitored Input
#define SPI_SS_SLAVE_MODE_Pos        21
#define SPI_SS_SLAVE_MODE_Msk       (1UL << SPI_SS_SLAVE_MODE_Pos)
#define SPI_SS_SLAVE_HW             (0UL << SPI_SS_SLAVE_MODE_Pos)  ///< SPI Slave Select when Slave: Hardware monitored (default)
#define SPI_SS_SLAVE_SW             (1UL << SPI_SS_SLAVE_MODE_Pos)  ///< SPI Slave Select when Slave: Software controlled


/*----- SPI Control Codes: Miscellaneous Controls  -----*/
#define SPI_SET_BUS_SPEED           (0x10UL << SPI_CONTROL_Pos)     ///< Set Bus Speed in bps; arg = value
#define SPI_GET_BUS_SPEED           (0x11UL << SPI_CONTROL_Pos)     ///< Get Bus Speed in bps
#define SPI_SET_DEFAULT_TX_VALUE    (0x12UL << SPI_CONTROL_Pos)     ///< Set default Transmit value; arg = value
#define SPI_CONTROL_SS              (0x13UL << SPI_CONTROL_Pos)     ///< Control Slave Select; arg: 0=inactive, 1=active
#define SPI_ABORT_TRANSFER          (0x14UL << SPI_CONTROL_Pos)     ///< Abort current data transfer


/****** SPI Slave Select Signal definitions *****/
#define SPI_SS_INACTIVE              0                                  ///< SPI Slave Select Signal Inactive
#define SPI_SS_ACTIVE                1                                  ///< SPI Slave Select Signal Active


/****** SPI specific error codes *****/
#define SPI_ERROR_MODE              (DRIVER_ERROR_SPECIFIC - 1)     ///< Specified Mode not supported
#define SPI_ERROR_FRAME_FORMAT      (DRIVER_ERROR_SPECIFIC - 2)     ///< Specified Frame Format not supported
#define SPI_ERROR_DATA_BITS         (DRIVER_ERROR_SPECIFIC - 3)     ///< Specified number of Data bits not supported
#define SPI_ERROR_BIT_ORDER         (DRIVER_ERROR_SPECIFIC - 4)     ///< Specified Bit order not supported
#define SPI_ERROR_SS_MODE           (DRIVER_ERROR_SPECIFIC - 5)     ///< Specified Slave Select Mode not supported


/* SPI transfer format register */
#define SPI_CPHA                      (1UL << 0)
#define SPI_CPOL                      (1UL << 1)
#define SPI_SLAVE                     (1UL << 2)
#define SPI_MASTER                    (0UL << 2)
#define SPI_LSB                       (1UL << 3)
#define SPI_MSB                       (0UL << 3)
#define SPI_MOSIBIDIR                 (1UL << 4)
#define SPI_MOSIUINDIR                (0UL << 4)
#define SPI_MERGE                     (1UL << 7)
#define DATA_BITS(data_bits)          ((data_bits - 1) << 8)


// SPI address length format
#define SPI_ADDR_LEN_1_BYTE           (0UL << 16)
#define SPI_ADDR_LEN_2_BYTE           (1UL << 16)
#define SPI_ADDR_LEN_3_BYTE           (2UL << 16)
#define SPI_ADDR_LEN_4_BYTE           (3UL << 16)


/* SPI transfer control register */
// RD/WR transfer count
#define RD_TRANCNT(num)               ((num - 1) << 0)
#define WR_TRANCNT(num)               ((num - 1) << 12)


// SPI transfer mode
#define SPI_TRANSMODE_WRnRD           (0x0 << 24)
#define SPI_TRANSMODE_WRONLY          (0x1 << 24)
#define SPI_TRANSMODE_RDONLY          (0x2 << 24)
#define SPI_TRANSMODE_WR_RD           (0x3 << 24)
#define SPI_TRANSMODE_RD_WR           (0x4 << 24)
#define SPI_TRANSMODE_WR_DMY_RD       (0x5 << 24)
#define SPI_TRANSMODE_RD_DMY_WR       (0x6 << 24)
#define SPI_TRANSMODE_NONEDATA        (0x7 << 24)
#define SPI_TRANSMODE_DMY_WR          (0x8 << 24)
#define SPI_TRANSMODE_DMY_RD          (0x9 << 24)

#define SPI_CMDEN                     (1UL << 30)
#define SPI_ADDREN                    (1UL << 29)
#define ADDRFMT_REGULAR               (0UL << 28)
#define ADDRFMT_ASDATA                (1UL << 28)
#define SPI_REGULAR                   (0UL << 22)
#define SPI_DUAL                      (1UL << 22)
#define SPI_QUAD                      (2UL << 22)
#define TOKEN_VALUE_00                (0UL << 11)
#define TOKEN_VALUE_69                (1UL << 11)
#define DUMMYCNT(num)                 ((num - 1) << 9)


/* SPI control register */
#define SPIRST                        (1UL << 0)
#define RXFIFORST                     (1UL << 1)
#define TXFIFORST                     (1UL << 2)
#define RXDMAEN                       (1UL << 3)
#define TXDMAEN                       (1UL << 4)
#define RXTHRES(num)                  (num << 8)
#define TXTHRES(num)                  (num << 16)

#define THRES_MASK                    (0x1f)
#define RXTHRES_OFFSET                (8)
#define TXTHRES_OFFSET                (16)


/* SPI interrupt status register */
/* SPI interrupt enable register */
#define SPI_RXFIFOOORINT              (1UL << 0)
#define SPI_TXFIFOOURINT              (1UL << 1)
#define SPI_RXFIFOINT                 (1UL << 2)
#define SPI_TXFIFOINT                 (1UL << 3)
#define SPI_ENDINT                    (1UL << 4)
#define SPI_SLVCMD                    (1UL << 5)


//The winbone FLASH cmd
#define CHIP_ERASE      0x60
#define WRITE_ENABLE    0x06
#define WRITE_DISENABLE 0x04


/* Functions --------------------------------------------------------------------- */
void SelectSpi(SPI_FLASH_RegDef *SPI_Num);
void SPI_reset(void);
void SPI_set_mode(uint32_t spi_mode);
void SPI_set_addr_format(uint8_t addrEn, uint32_t addrLen, uint32_t addrFmt);
//addrLen = SPI_ADDR_LEN_1_BYTE / SPI_ADDR_LEN_2_BYTE / SPI_ADDR_LEN_3_BYTE / SPI_ADDR_LEN_4_BYTE
//addrFmt = ADDRFMT_REGULAR / ADDRFMT_ASDATA

void SPI_set_cmd_format(uint8_t cmdEn);
void SPI_set_data_format(uint8_t dataBits, uint8_t dataMerge);
//dataMerge takes effect only when data length is 8

void SPI_set_transfer_format(uint32_t mosiDir, uint32_t lsbmsb, uint32_t cpol, uint32_t cpha);
//mosiDir = SPI_MOSIBIDIR / SPI_MOSIUINDIR
//lsbmsb  = SPI_LSB / SPI_MSB
//cpol    = 0 / 1
//cpha    = 0 / 1

void SPI_set_trans_ctrl(uint32_t transMode, uint32_t dualQuad, uint32_t dummyCnt);
//transMode = SPI_TRANSMODE_WRnRD     / SPI_TRANSMODE_WRONLY   / SPI_TRANSMODE_RDONLY    /
//            SPI_TRANSMODE_WR_RD     / SPI_TRANSMODE_RD_WR    / SPI_TRANSMODE_WR_DMY_RD /
//            SPI_TRANSMODE_RD_DMY_WR / SPI_TRANSMODE_NONEDATA / SPI_TRANSMODE_DMY_WR    /
//            SPI_TRANSMODE_DMY_RD
//dualQuad  = SPI_REGULAR / SPI_DUAL / SPI_QUAD
//dummyCnt  = 1 / 2 / 3 / 4

void SPI_set_token(uint8_t tokenEn, uint8_t tokenValue);
void SPI_tx_fifo_reset(void);
void SPI_rx_fifo_reset(void);
uint8_t spi_get_fifo_depth(uint8_t fifo_depth_config);
void SPI_set_tx_threshold(uint8_t tx_threshold);
void SPI_set_rx_threshold(uint8_t rx_threshold);


#if BUILD_MODE != BUILD_XIP
uint8_t spi_get_fifo_depth(uint8_t fifo_depth_config)    __attribute__((optimize("Os")));
void spi_flash_init() __attribute__((optimize("Os")));//(uint8_t * tx_fifo_depth,uint8_t * rx_fifo_depth);
void spi_flash_read(uint8_t rd_len, uint32_t cmd, uint32_t address, uint8_t *read_buffer) __attribute__((optimize("O3")));
void spi_flash_write(uint8_t wr_len, uint32_t cmd, uint32_t address, uint8_t *write_buffer) __attribute__((optimize("Os")));
void change_mode_spi_flash() __attribute__((optimize("Os")));
void spi_flash_write_cmd(uint32_t cmd) __attribute__((optimize("O3")));
void spi_flash_page_program(uint8_t wr_len, uint32_t address, uint8_t *write_buffer) __attribute__((optimize("O3")));
void spi_flash_sector_erase(uint32_t address) __attribute__((optimize("O3")));
void spi_flash_read_status() __attribute__((optimize("Os")));
#else
uint8_t spi_get_fifo_depth(uint8_t fifo_depth_config)    __attribute__((optimize("Os"), section(".advspi")));
void spi_flash_init() __attribute__((optimize("Os")));//(uint8_t * tx_fifo_depth,uint8_t * rx_fifo_depth);
void spi_flash_read(uint8_t rd_len, uint32_t cmd, uint32_t address, uint8_t *read_buffer) __attribute__((optimize("O3"), section(".advspi")));
void spi_flash_write(uint8_t wr_len, uint32_t cmd, uint32_t address, uint8_t *write_buffer) __attribute__((optimize("Os"), section(".advspi")));
void change_mode_spi_flash() __attribute__((optimize("Os")));
void spi_flash_write_cmd(uint32_t cmd) __attribute__((optimize("O3")));
void spi_flash_page_program(uint8_t wr_len,uint32_t address, uint8_t *write_buffer) __attribute__((optimize("O3"), section(".advspi")));
void spi_flash_sector_erase(uint32_t address) __attribute__((optimize("O3"), section(".advspi")));
void spi_flash_read_status() __attribute__((optimize("Os"), section(".advspi")));
#endif

#endif
