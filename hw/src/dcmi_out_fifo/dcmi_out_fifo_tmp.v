//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8
//Part Number: GW2AR-LV18QN88C7/I6
//Device: GW2AR-18
//Created Time: Tue Apr 05 20:55:04 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	dcmi_out_fifo your_instance_name(
		.Data(Data_i), //input [15:0] Data
		.Reset(Reset_i), //input Reset
		.WrClk(WrClk_i), //input WrClk
		.RdClk(RdClk_i), //input RdClk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Wnum(Wnum_o), //output [5:0] Wnum
		.Q(Q_o), //output [15:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
