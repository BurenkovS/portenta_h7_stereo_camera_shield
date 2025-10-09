//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9 (64-bit) 
//Created Time: 2025-02-05 11:47:40
create_clock -name MT1PixClk -period 35.714 -waveform {0 17.857} [get_ports {MT1PixClk}]
create_clock -name MT2PixClk -period 35.714 -waveform {0 17.857} [get_ports {MT2PixClk}]
create_clock -name pll_vid_clk_54M -period 18.519 -waveform {0 9.259} [get_ports {dcmi_o_pixclk}]
//create_clock -name clk_sys -period 10.41 [get_pins {rPLL_inst/rpll_inst/CLKOUT}]
create_clock -name clk_sys -period 12.34 [get_pins {rPLL_inst/rpll_inst/CLKOUT}]
create_clock -name XTAL -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}] -add
set_false_path -from [get_clocks {MT1PixClk}] -to [get_clocks {clk_sys}] 
set_false_path -from [get_clocks {clk_sys}] -to [get_clocks {pll_vid_clk_54M}] 
report_timing -setup -from_clock [get_clocks {XTAL}] -to_clock [get_clocks {XTAL}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk_sys}] -to_clock [get_clocks {clk_sys}]
