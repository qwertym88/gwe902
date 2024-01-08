//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: V1.9.9 Beta-6
//Created Time: 2024-01-07 22:27:36
create_clock -name clk50m -period 20 -waveform {0 10} [get_ports {clk50m}]
create_clock -name jtag_tck -period 333.333 -waveform {0 166.667} [get_ports {jtag_tclk}]
create_generated_clock -name sysclk -source [get_ports {clk50m}] -master_clock clk50m -divide_by 6 [get_nets {sys_clk}]
