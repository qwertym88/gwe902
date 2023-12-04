//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-3
//Created Time: 2023-09-03 09:36:13
create_clock -name clk27m -period 37.037 -waveform {0 18.518} [get_ports {clk27m}]
create_clock -name jtag_tck -period 333.333 -waveform {0 166.667} [get_ports {jtag_tclk}]
