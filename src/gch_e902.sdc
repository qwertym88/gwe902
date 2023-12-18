//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: V1.9.9 Beta-6
//Created Time: 2023-12-18 10:44:37
create_clock -name clk27m -period 37.037 -waveform {0 18.518} [get_ports {clk27m}]
create_clock -name jtag_tck -period 333.333 -waveform {0 166.667} [get_ports {jtag_tclk}]
create_generated_clock -name PCLK -source [get_nets {sys_clk}] -master_clock sysclk -divide_by 4 [get_nets {x_sysahb_periphs/u_apb_subsystem/PCLK}]
create_generated_clock -name sysclk -source [get_ports {clk27m}] -master_clock clk27m -divide_by 4 [get_nets {sys_clk}]
