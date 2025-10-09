//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11 (64-bit)
//Part Number: GW2AR-LV18QN88C7/I6
//Device: GW2AR-18
//Created Time: Thu Sep 11 11:53:04 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    ram_sr your_instance_name(
        .dout(dout), //output [7:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [10:0] ada
        .din(din), //input [7:0] din
        .adb(adb) //input [10:0] adb
    );

//--------Copy end-------------------
