/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		picorv32.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Register definition
 ******************************************************************************************
 */

#ifndef __PICORV32_H
#define __PICORV32_H

/* Includes --------------------------------------------------------------------- */
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>

/* Macros --------------------------------------------------------------------- */
#define __I                     volatile const	/* 'read only' permissions      */
#define __O                     volatile        /* 'write only' permissions     */
#define __IO                    volatile        /* 'read / write' permissions   */

#define KHz (1000)
#define MHz (1000000)

#define SYSCLKFREQ (27 * MHz)	/* Base on System Clock in Hardware IPCore */

//#define USE_WBUART

/* Regiter Definitions --------------------------------------------------------------------- */

/* Wishbone UART Register Definitions ------------------------------------------------ */
typedef struct {
	__IO unsigned int SETUP;   /*0x00, WBUART setup*/
	__I  unsigned int FIFO;    /*0x04, WBUART fifo */
	__IO unsigned int RXREG;   /*0x08, WBUART RX   */
	__IO unsigned int TXREG;   /*0x0c, WBUART TX   */
} WBUART_RegDef;

/* Simple UART Register Definitions ------------------------------------------------ */
typedef struct {
	__IO unsigned int RESERVED;	//0x00
	__IO unsigned int CLKDIV;	//0x04
	__IO unsigned int DATA;		//0x08
} SIMPLEUART_RegDef;

/* Wishbone SPI Register Definitions ------------------------------------------------ */
typedef struct {
	__IO unsigned int RXDATA;  //0x00
	__IO unsigned int TXDATA;  //0x04
	__I  unsigned int STATUS;  //0x08
	__IO unsigned int CONTROL; //0x0c
	__IO unsigned int SSMASK;  //0x10
} WBSPI_RegDef;

/* Wishbone I2C Master Register Definitions ------------------------------------------------ */
typedef struct {
	__IO unsigned int PRER;     //0x00 Clock Prescale register
	__IO unsigned int CTR;      //0x04 Control register
	union {
		__O unsigned int TXR;   //0x08 Transmit register
		__I unsigned int RXR;   //0x08 Receive register
	};
	union {
		__O unsigned int CR;    //0x0c command register
		__I unsigned int SR;    //0x0c Status register
	};
} WBI2CMASTER_RegDef;

/* ADV SPI-Flash Register Definitions ------------------------------------------------ */
typedef struct
{
	__I  unsigned int IDREV;                /* 0x00 ID and revision register */
	     unsigned int RESERVED0[3];         /* 0x04 ~ 0x0c Reserved */
	__IO unsigned int TRANSFMT;             /* 0x10 SPI transfer format register */
	__IO unsigned int DIRECTIO;             /* 0x14 SPI direct IO control register */
	     unsigned int RESERVED1[2];         /* 0x18 ~ 0x1c Reserved */
	__IO unsigned int TRANSCTRL;            /* 0x20 SPI transfer control register */
	__IO unsigned int CMD;                  /* 0x24 SPI command register */
	__IO unsigned int ADDR;                 /* 0x28 SPI address register */
	__IO unsigned int DATA;                 /* 0x2c SPI data register */
	__IO unsigned int CTRL;                 /* 0x30 SPI conrtol register */
	__I  unsigned int STATUS;               /* 0x34 SPI status register */
	__IO unsigned int INTREN;               /* 0x38 SPI interrupt enable register */
	__O  unsigned int INTRST;               /* 0x3c SPI interrupt status register */
	__IO unsigned int TIMING;               /* 0x40 SPI interface timing register */
	     unsigned int RESERVED2[3];         /* 0x44 ~ 0x4c Reserved */
	__IO unsigned int MEMCTRL;              /* 0x50 SPI memory access control register */
	     unsigned int RESERVED3[3];         /* 0x54 ~ 0x5c Reserved */
	__IO unsigned int SLVST;                /* 0x60 SPI slave status register */
	__I  unsigned int SLVDATACNT;           /* 0x64 SPI slave data count register */
	     unsigned int RESERVED4[5];         /* 0x68 ~ 0x78 Reserved */
	__I  unsigned int CONFIG;               /* 0x7c Configuration register */
}SPI_FLASH_RegDef;

/* Wishbone GPIO Register Definitions ------------------------------------------------ */
typedef struct {
	__IO unsigned int CFG;		//0x00
	__IO unsigned int IE;		//0x04
	__IO unsigned int RSV[2];	//0x08~0x0c
	__IO unsigned int DIR;		//0x10
	__IO unsigned int IN;		//0x14
	__IO unsigned int OUT;		//0x18
} WBGPIO_RegDef;


/* Address Definitions --------------------------------------------------------------------- */
#define _IO_(addr)              (addr)

#define SIMPLEUART_BASE         _IO_(0x03000000)  //Simple UART base address
#define WBUART_BASE             _IO_(0x11000000)  //Wishbone UART base address
#define WBGPIO_BASE             _IO_(0x11001000)  //Wishbone GPIO base address
#define WBSPI_MASTER_BASE       _IO_(0x11002000)  //Wishbone SPI Master base address
#define WBSPI_SLAVE_BASE        _IO_(0x11003000)  //Wishbone SPI Slave base address
#define ADVSPI_BASE             _IO_(0x11004000)  //ADV SPI-Flash base address
#define WBI2C_BASE              _IO_(0x11005000)  //Wishbone I2C Master base address

#define OPEN_WB_BASE            _IO_(0x20000000)  //open wishbone interface base address (0x20000000~0x40000000)
#define OPEN_AHB_BASE           _IO_(0x80000000)  //open ahb interface base address (0x80000000~0xffff0000)


#define PICO_SIMPLEUART        ((SIMPLEUART_RegDef  *)    SIMPLEUART_BASE      )  //Simple UART
#define PICO_WBUART            ((WBUART_RegDef      *)    WBUART_BASE          )  //WB UART
#define PICO_WBGPIO            ((WBGPIO_RegDef      *)    WBGPIO_BASE          )  //WB GPIO
#define PICO_WBSPI_MASTER      ((WBSPI_RegDef       *)    WBSPI_MASTER_BASE    )  //WB SPI Master
#define PICO_WBSPI_SLAVE       ((WBSPI_RegDef       *)    WBSPI_SLAVE_BASE     )  //WB SPI Slave
#define PICO_SPI_FLASH         ((SPI_FLASH_RegDef   *)    ADVSPI_BASE          )  //ADV SPI_Flash
#define PICO_WBI2C             ((WBI2CMASTER_RegDef *)    WBI2C_BASE           )  //WB I2C Master

#endif /* __PICORV32_H */
