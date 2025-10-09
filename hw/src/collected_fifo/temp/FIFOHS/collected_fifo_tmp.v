//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9 (64-bit)
//Part Number: GW2AR-LV18QN88C7/I6
//Device: GW2AR-18
//Created Time: Thu Apr  4 19:25:39 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	collected_fifo your_instance_name(
		.Data(Data_i), //input [8:0] Data
		.Reset(Reset_i), //input Reset
		.WrClk(WrClk_i), //input WrClk
		.RdClk(RdClk_i), //input RdClk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Rnum(Rnum_o), //output [10:0] Rnum
		.Q(Q_o), //output [8:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
