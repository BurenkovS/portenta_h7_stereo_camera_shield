//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11 (64-bit)
//Part Number: GW2AR-LV18QN88C7/I6
//Device: GW2AR-18
//Created Time: Mon Sep 22 18:47:48 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	small_pipe_comp_fifo your_instance_name(
		.Data(Data), //input [8:0] Data
		.Clk(Clk), //input Clk
		.WrEn(WrEn), //input WrEn
		.RdEn(RdEn), //input RdEn
		.Reset(Reset), //input Reset
		.Almost_Empty(Almost_Empty), //output Almost_Empty
		.Almost_Full(Almost_Full), //output Almost_Full
		.Q(Q), //output [8:0] Q
		.Empty(Empty), //output Empty
		.Full(Full) //output Full
	);

//--------Copy end-------------------
