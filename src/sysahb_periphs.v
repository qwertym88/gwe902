module sysahb_periphs (
  input wire sys_clk,
  input wire sys_resetn,
  input wire [31:0] sysahb_haddr,
  input wire [31:0] sysahb_hwdata,
  input wire [2 :0] sysahb_hburst,
  input wire [2 :0] sysahb_hsize,
  input wire [1 :0] sysahb_htrans,
  input wire sysahb_hwrite,
  input wire [3 :0] sysahb_hprot,
  output wire sysahb_hready,
  output wire [1 :0] sysahb_hresp,
  output wire [31:0] sysahb_hrdata
);

// sysahb_hready = hready_s1 & hready_s2 & hready_s3 & hready_s4, 表示总线的hready状态

// sysahb slave1 bram 256kB
// taken from system-on-chip-design-reference P23
// 只接18位地址线，虽然200 00000 到 208 00000地址的请求都会给到这，不知道该不该这样写
AHBBlockRam x_ahb_bram (
    .HCLK(sys_clk),
    .HRESETn(sys_resetn),
    .HSEL(hsel_s0),
    .HREADY(sysahb_hready),
    .HTRANS(htrans_s0),
    .HSIZE(hsize_s0[1:0]),
    .HWRITE(hwrite),
    .HADDR(haddr[17:0]),
    .HWDATA(hwdata),
    .HREADYOUT(hready_s0),
    .HRESP(hresp_s0),
    .HRDATA(hrdata_s0)
);
defparam x_ahb_bram.AWIDTH = 18;

// sysahb slave2 default slave
// Taken from page 28 of System-on-Chip Design with Arm Cortex-M processors
ahb_defslave x_ahb_defslave(
    .HCLK(sys_clk), 
    .HRESETn(sys_resetn), 
    .HSEL(hsel_s1), 
    .HTRANS(htrans_s1), 
    .HREADY(sysahb_hready),
    .HREADYOUT(hready_s1), 
    .HRESP(hresp_s1) 
);

ahb_decoder x_ahb_decoder(
    .HADDR ( sysahb_haddr ),
    .EN    ( 1'b1         ),
    .HSEL0 ( hsel_s0      ),
    .HSEL1 ( hsel_s1      ),
);

// ahb mux
// taken from system-on-chip-design-reference P150
ahb_slavemux x_ahb_slavemux(
    .HCLK       ( HCLK          ),
    .HRESETn    ( HRESETn       ),
    .HREADY     ( sysahb_hready ),
    .HSEL0      ( hsel_s0       ),
    .HREADYOUT0 ( hready_s0     ),
    .HRESP0     ( hresp_s0      ),
    .HRDATA0    ( hrdata_s0     ),
    .HSEL1      ( hsel_s1       ),
    .HREADYOUT1 ( hready_s1     ),
    .HRESP1     ( hresp_s1      ),
    .HRDATA1    ( hrdata_s1     ),
    .HREADYOUT  ( sysahb_hready ),
    .HRESP      ( sysahb_hresp  ),
    .HRDATA     ( sysahb_hrdata ),
);


endmodule