//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9 (64-bit)
//Part Number: GW2AR-LV18QN88C7/I6
//Device: GW2AR-18
//Created Time: Mon Feb 10 17:33:50 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	sdram_write_fifo_v3 your_instance_name(
		.Data(Data_i), //input [31:0] Data
		.Clk(Clk_i), //input Clk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Reset(Reset_i), //input Reset
		.Wnum(Wnum_o), //output [6:0] Wnum
		.Almost_Full(Almost_Full_o), //output Almost_Full
		.Q(Q_o), //output [31:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
