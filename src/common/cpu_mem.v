module cpu_mem (
    input wire sys_clk,
    input wire sys_resetn,
    input wire [31:0] haddr,
    input wire [2 :0] hburst,
    input wire [3 :0] hprot, 
    input wire [2:0] hsize,
    input wire [1:0] htrans,
    input wire [31:0] hwdata,
    input wire hwrite,
    output wire [31:0] hrdata,
    output wire hresp,
    output wire hready
);

wire hsel;
assign hsel = htrans[1]; // trans只有00/10两种取值

// IAHB Lite Memory, 64kB
AHBBlockRam x_iahb_bram (
    .HCLK(sys_clk),
    .HRESETn(sys_resetn),
    .HSEL(hsel),
    .HREADY(hready),
    .HTRANS(htrans),
    .HSIZE(hsize[1:0]),
    .HWRITE(hwrite),
    .HADDR(haddr[14:0]),
    .HWDATA(hwdata),
    .HREADYOUT(hready),
    .HRESP(hresp),
    .HRDATA(hrdata)
);
defparam x_iahb_bram.AWIDTH = 15; // 15位地址线

endmodule