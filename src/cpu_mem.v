module cpu_mem (
  input sys_clk,
  input sys_resetn,
  input [31:0] hrdata,
  input hready,
  input hresp,
  input [31:0] haddr,
  input [2 :0] hburst,
  input [3 :0] hprot, 
  input [1:0] hsize,
  input [1:0] htrans,
  input [31:0] hwdata,
  input hwrite 
);

wire hsel;
assign hsel = htrans[1] // trans只有00/10两种取值

// IAHB Lite Memory, 512MB
AHBBlockRam x_ahb_bram (
  .HCLK(sys_clk),
  .HRESETn(sys_resetn),
  .HSEL(hsel),
  .HREADY(hready),
  .HTRANS(htrans),
  .HSIZE(hsize[1:0]),
  .HWRITE(hwrite),
  .HADDR(haddr[18:0]),
  .HWDATA(hwdata),
  .HREADYOUT(hready),
  .HRESP(hresp),
  .HRDATA(hrdata)
);
defparam x_ahb_bram.AWIDTH = 19; // 19位地址线

endmodule