/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		advspi.c
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		ADV SPI-Flash Peripheral.
 ******************************************************************************************
 */

/* Includes --------------------------------------------------------------------- */
#include "advspi.h"

/* Declarations--------------------------------------------------------------------- */
static SPI_FLASH_RegDef *SPI_FLASH_Reg = (SPI_FLASH_RegDef *)PICO_SPI_FLASH;

/* Functions --------------------------------------------------------------------- */
void SelectSpi(SPI_FLASH_RegDef *SPI_Num)
{
	SPI_FLASH_Reg = SPI_Num;
}

void SPI_reset(void)
{
	SPI_FLASH_Reg->CTRL |= 0x01;         //reset spi
	while((SPI_FLASH_Reg->CTRL & 0x01)); //wait until spi reset complete
	return;
}

//select the slave mode or master mode
//but need the hardware support
void SPI_set_mode(uint32_t spi_mode)
{
	uint32_t buff = SPI_FLASH_Reg->TRANSFMT;
	SPI_FLASH_Reg->TRANSFMT = (buff & (~(1UL << 2))) + spi_mode;
	return;
}

//addrLen = SPI_ADDR_LEN_1_BYTE / SPI_ADDR_LEN_2_BYTE / SPI_ADDR_LEN_3_BYTE / SPI_ADDR_LEN_4_BYTE
//addrFmt = ADDRFMT_REGULAR / ADDRFMT_ASDATA
void SPI_set_addr_format(uint8_t addrEn, uint32_t addrLen, uint32_t addrFmt)
{
	uint32_t buff;
	if(0 == addrEn)
	{
		return;
	}
	else
	{
		//set the addr enable && addr fomat
		buff = SPI_FLASH_Reg->TRANSCTRL;
		SPI_FLASH_Reg->TRANSCTRL = (buff & (~(3UL << 28))) + addrFmt + SPI_ADDREN;
		//set the width of the addr length
		buff = SPI_FLASH_Reg->TRANSFMT;
		SPI_FLASH_Reg->TRANSFMT  = (buff & (~(3UL << 16))) + addrLen;
	}
	return;
}

void SPI_set_cmd_format(uint8_t cmdEn)
{
	uint32_t buff;
	if(0 == cmdEn)
	{
		return;
	}

	else
	{
		//open the spi cmd phase
		buff = SPI_FLASH_Reg->TRANSCTRL;
		SPI_FLASH_Reg->TRANSCTRL = (buff & (~(1UL << 30))) + SPI_CMDEN;
	}
	return;
}

//dataMerge takes effect only when data length is 8
void SPI_set_data_format(uint8_t dataBits, uint8_t dataMerge)
{
	uint32_t buff;
	buff = SPI_FLASH_Reg->TRANSFMT;
	SPI_FLASH_Reg->TRANSFMT = (buff &(~(0xf << 8))) + (((dataBits - 1) & 0xf) << 8);
	if(8 == dataBits)
	{
		buff = SPI_FLASH_Reg->TRANSFMT;
		SPI_FLASH_Reg->TRANSFMT = (buff &(~(0x1 << 7))) + ((dataMerge & 0x1) << 8);
	}
	return;
}

//mosiDir = SPI_MOSIBIDIR / SPI_MOSIUINDIR
//lsbmsb  = SPI_LSB / SPI_MSB
//cpol    = 0 / 1
//cpha    = 0 / 1
void SPI_set_transfer_format(uint32_t mosiDir, uint32_t lsbmsb, uint32_t cpol, uint32_t cpha)
{
	uint32_t buff;
	uint32_t tmp;
	buff = SPI_FLASH_Reg->TRANSFMT;
	tmp = mosiDir + lsbmsb + ((cpol & 0x1) << 1) + (cpha & 0x1);
	SPI_FLASH_Reg->TRANSFMT = (buff & (~(0x1b))) + tmp;
	return;
}

//transMode = SPI_TRANSMODE_WRnRD     / SPI_TRANSMODE_WRONLY   / SPI_TRANSMODE_RDONLY    /
//            SPI_TRANSMODE_WR_RD     / SPI_TRANSMODE_RD_WR    / SPI_TRANSMODE_WR_DMY_RD /
//            SPI_TRANSMODE_RD_DMY_WR / SPI_TRANSMODE_NONEDATA / SPI_TRANSMODE_DMY_WR    /
//            SPI_TRANSMODE_DMY_RD
//dualQuad  = SPI_REGULAR / SPI_DUAL / SPI_QUAD
//dummyCnt  = 1 / 2 / 3 / 4
void SPI_set_trans_ctrl(uint32_t transMode, uint32_t dualQuad, uint32_t dummyCnt)
{
	uint32_t buff = SPI_FLASH_Reg->TRANSCTRL;
	SPI_FLASH_Reg->TRANSCTRL = buff & (~((0xf << 24) + (0x3 << 22) + (0x3 << 9)));
	SPI_FLASH_Reg->TRANSCTRL += transMode;
	SPI_FLASH_Reg->TRANSCTRL += dualQuad;
	SPI_FLASH_Reg->TRANSCTRL += (((dummyCnt - 1) & 0x3) << 9);
	return;
}

void SPI_set_token(uint8_t tokenEn, uint8_t tokenValue)
{
	uint32_t buff = SPI_FLASH_Reg->TRANSCTRL;
	if(0 == tokenEn)
	{
		return;
	}
	else
	{
		SPI_FLASH_Reg->TRANSCTRL = (buff & (~((1 << 21) + (1 << 11)))) + (1 << 21) + ((tokenValue & 0x1) << 11);
	}
}

void SPI_tx_fifo_reset(void)
{
	SPI_FLASH_Reg->CTRL |= (0x1 << 2);    //reset tx fifo
	while((SPI_FLASH_Reg->CTRL & 0x2)) ;  //wait tx fifo reset complete
}

void SPI_rx_fifo_reset(void)
{
	SPI_FLASH_Reg->CTRL |= (0x1 << 1);    //reset rx fifo
	while((SPI_FLASH_Reg->CTRL & 0x1)) ;  //wait rx fifo reset complete
}

uint8_t spi_get_fifo_depth(uint8_t fifo_depth_config)
{
	uint8_t fifo_depth = 1;
	for(int i = 0; i < fifo_depth_config+1; i++)
	{
		fifo_depth *= 2;
	}
	return fifo_depth;
}

void SPI_set_tx_threshold(uint8_t tx_threshold)
{
	uint32_t buff;
	buff = SPI_FLASH_Reg->CONFIG;
	uint8_t tx_fifo_depth_config = (buff & 0x3f) >> 4;
	uint8_t tx_fifo_depth = spi_get_fifo_depth(tx_fifo_depth_config);
	if(tx_threshold > tx_fifo_depth)
	{
		printf("tx threshold should not be set larger than tx fifo depth!\r\n");
	}
	else
	{
		SPI_FLASH_Reg->CTRL &= (~(0x1f << 16));
		SPI_FLASH_Reg->CTRL |= ((tx_threshold) << 16);
	}
	return;
}

void SPI_set_rx_threshold(uint8_t rx_threshold)
{
	uint32_t buff;
	buff = SPI_FLASH_Reg->CONFIG;
	uint8_t rx_fifo_depth_config = (buff & 0x03);
	uint8_t rx_fifo_depth = spi_get_fifo_depth(rx_fifo_depth_config);
	if(rx_threshold > rx_fifo_depth)
	{
		printf("rx threshold should not be set larger than rx fifo depth!\r\n");
	}
	else
	{
		SPI_FLASH_Reg->CTRL &= (~(0x1f << 8));
		SPI_FLASH_Reg->CTRL |= ((rx_threshold) << 8);
	}
	return;
}

void spi_flash_init(void)
{
	uint32_t buff;

	SPI_FLASH_Reg->CTRL |= 0x01;         //reset spi
	while((SPI_FLASH_Reg->CTRL & 0x01)); //wait until spi reset complete

	buff = SPI_FLASH_Reg->CONFIG;
	uint8_t tx_fifo_depth_config = (buff & 0x3f) >> 4;
	uint8_t tx_fifo_depth = spi_get_fifo_depth(tx_fifo_depth_config);
	uint8_t rx_fifo_depth_config = (buff & 0x03);
	uint8_t rx_fifo_depth = spi_get_fifo_depth(rx_fifo_depth_config);

	while((SPI_FLASH_Reg->STATUS & 0x01)); //wait until SPI2 active finish



	buff = (2 << 16) +(7 << 8) + (0 << 7);
	//AddrLen = 3; DataLen = 8 DataMerge = 0
	//other fields reset to 0 while spi_default_modes connected to 0
	SPI_FLASH_Reg->TRANSFMT = buff;


	SPI_FLASH_Reg->CTRL |= (0x1 << 2);    //reset tx fifo
	while((SPI_FLASH_Reg->CTRL & 0x2)) ;  //wait tx fifo reset complete
	SPI_FLASH_Reg->CTRL  |= ((tx_fifo_depth/2) << 16);  //set tx threshold as half of txfifo depth

	SPI_FLASH_Reg->CTRL |= (0x1 << 1);    //reset rx fifo
	while((SPI_FLASH_Reg->CTRL & 0x1)) ;  //wait rx fifo reset complete
	SPI_FLASH_Reg->CTRL  |= ((rx_fifo_depth/2) << 8);  //set rx threshold as half of rxfifo depth

	//SPI_FLASH_Reg->INTREN |= (0x1 << 4);  //Do not support Interupt signal
	SPI_FLASH_Reg->INTREN &= 0x00000000;    //close all the interrupt
	SPI_FLASH_Reg->TIMING &= (~(0xff));
	SPI_FLASH_Reg->TIMING |= (0x3);       //Set the SPI Interface Timing Register (0x40)
	                                   //to set SCLK_DIV to 4, which divide the spi_clk into
	                                   //((4+1)*2) = 10 as SCLK
	return;
}

//cmd -> address -> data
void spi_flash_read(uint8_t rd_len, uint32_t cmd, uint32_t address,uint8_t *read_buffer)
{
	SPI_FLASH_Reg->TRANSCTRL = (1 << 30) +     //enable cmd
							(1 << 29) +        //Open the address
			                (2 << 24) +        //trans mode = 2 (read only)
							(0 << 22) +        //dual mode 0 regular mode
							((rd_len-1) << 0); //set read trans byte count
	//printf("%08x\n", SPI_FLASH_Reg->TRANSCTRL);
	SPI_FLASH_Reg->ADDR = address;
	//printf("%08x\n", SPI_FLASH_Reg->ADDR);
	SPI_FLASH_Reg->CMD  = cmd;
	//printf("%08x\n", SPI_FLASH_Reg->CMD);

	for(uint8_t i = 0; i < rd_len; i++)
	{
		*read_buffer = SPI_FLASH_Reg->DATA;
		read_buffer++;
		while(SPI_FLASH_Reg ->STATUS & (0x1 <<15));
	}
	while((SPI_FLASH_Reg->STATUS & 0x01)); //wait until SPI_Ctroller active finish
}

//the consequence of sending
//cmd -> address -> data
void spi_flash_write(uint8_t wr_len, uint32_t cmd, uint32_t address,uint8_t *write_buffer)
{
	spi_flash_write_cmd(WRITE_ENABLE);
	spi_flash_read_status();

	SPI_FLASH_Reg->TRANSCTRL = (1 << 30) +        //enable cmd
							(1 << 29) + //enable address
			                (1 << 24) +        //trans mode = 1 (write only)
							(0 << 22) +         //dual mode
							((wr_len-1) << 12); //set read trans byte count

	SPI_FLASH_Reg->ADDR = address;
	SPI_FLASH_Reg->CMD  = cmd;
	for(uint8_t i = 0; i < wr_len; i++)
	{
		SPI_FLASH_Reg->DATA = (uint32_t)(*write_buffer);
		write_buffer++;
		//check the status of txfifo
		while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));
	}

	while((SPI_FLASH_Reg->STATUS & 0x01)); //wait until SPI_ctroller active finish
	spi_flash_write_cmd(WRITE_DISENABLE);
	spi_flash_read_status();
}

//change the mode of spi flash
void change_mode_spi_flash()
{
	uint32_t i;
	//read spi memory access register 0x50
	i = SPI_FLASH_Reg ->MEMCTRL;
	//write back to spi flash reg
	SPI_FLASH_Reg ->MEMCTRL = i;
	//wait the memCtrlChg become 0
	while(SPI_FLASH_Reg ->MEMCTRL & (0x01 <<8 ));

}

//write cmd to spi flash
//accord different spi flash
void spi_flash_write_cmd(uint32_t cmd)
{
	SPI_FLASH_Reg->TRANSCTRL = (0 << 30) +        //Disenable cmd
			                (1 << 24) + //trans mode = 1 (write only)
							(0 << 22) +//regular mode
							(0 << 12); //set trans byte count is 1
	SPI_FLASH_Reg->CMD  = 0x01;//Start to transfer
	if(cmd == CHIP_ERASE)
	{
		spi_flash_write_cmd(WRITE_ENABLE);
		spi_flash_read_status();
	}
	SPI_FLASH_Reg->DATA = cmd;
	//Check the status of tx_FIFO
	while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));
	//Check the status of Transfer
	while((SPI_FLASH_Reg->STATUS & 0x01));
}

//Page program
void spi_flash_page_program(uint8_t wr_len,uint32_t address,uint8_t *write_buffer)
{
	spi_flash_write_cmd(WRITE_ENABLE);
	spi_flash_read_status();

	SPI_FLASH_Reg->TRANSCTRL = (1 << 30) + //enable cmd
							(1 << 29) + //enable address
			                (1 << 24) +        //trans mode = 1 (write only)
							(0 << 22) +         //dual mode
							((wr_len-1) << 12); //set read trans byte count

	SPI_FLASH_Reg->ADDR = address;
	SPI_FLASH_Reg->CMD  = 0x02;//page program cmd
	for(uint8_t i = 0; i < wr_len; i++)
	{
		SPI_FLASH_Reg->DATA = (uint32_t)(*write_buffer);
		write_buffer++;
		//check the status of txfifo
		while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));
	}

	while((SPI_FLASH_Reg->STATUS & 0x01)); //wait until SPI_ctroller active finish
	spi_flash_write_cmd(WRITE_DISENABLE);
	spi_flash_read_status();    //wait spi flash free
}

//Sector Erase
void spi_flash_sector_erase(uint32_t address)
{
	spi_flash_write_cmd(WRITE_ENABLE);
	spi_flash_read_status();
	//litter endian and the range of address
	//uint8_t temp[3];
	uint8_t temp0;
	uint8_t temp1;
	uint8_t temp2;
	SPI_FLASH_Reg->TRANSCTRL = (1 << 30) + //enable cmd
			                (1 << 24) +        //trans mode = 1 (write only)
							(0 << 22) +         //dual mode
							(2 << 12); //set address - 3bytes

	temp0 = (address >> 16 &0xFF);//The address High byte
	temp1 = (address >> 8  &0xFF);//The address middle byte
	temp2 = (address       &0xFF);//The address low   byte

	SPI_FLASH_Reg->CMD  = 0x20; //Sector Erase cmd

	SPI_FLASH_Reg->DATA = temp0;
	//check the status of txfifo
	while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));

	SPI_FLASH_Reg->DATA = temp1;
	//check the status of txfifo
	while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));

	SPI_FLASH_Reg->DATA = temp2;
	//check the status of txfifo
	while(SPI_FLASH_Reg ->STATUS & (0x1 <<23));

	while((SPI_FLASH_Reg->STATUS & 0x01)); //wait until SPI_ctroller active finish
	spi_flash_write_cmd(WRITE_DISENABLE);
	spi_flash_read_status();    //wait spi flash free
}

void spi_flash_read_status()
{
	uint8_t temp_first;
	SPI_FLASH_Reg->TRANSCTRL = (1 << 30) +     //enable cmd
			                (2 << 24) +        //trans mode = 2 (read only)
							(0 << 22) +        //dual mode 0 regular mode
							(0 << 0); //set read 1 byte
   do
   {
	   	SPI_FLASH_Reg->CMD  = 0x05;//read status
		temp_first  = SPI_FLASH_Reg->DATA;
		//printf("The spi  read status is %x\r\n",temp_first);
   }
   while(temp_first & 0x01 );//Select the low bit and wait become 0

   while((SPI_FLASH_Reg->STATUS & 0x03)) ; //wait until SPI_Ctroller active finish
}
