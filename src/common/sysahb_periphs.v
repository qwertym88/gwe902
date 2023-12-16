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
  output wire sysahb_hresp,
  output wire [31:0] sysahb_hrdata,
  // AHB Peripherals
  // UART
  input  wire           uart0_rxd,
  output wire           uart0_txd,
  output wire           uart0_txen,
  // Timer
  input  wire           timer0_extin,
  // Interrupt outputs
  output wire   [31:0]  apb_interrupt,
//   output wire           watchdog_interrupt,
//   output wire           watchdog_reset,
  // GPIO
  inout wire [7:0] gpio_portA,
  inout wire [7:0] gpio_portB
);

//SYS MEM
`define S0_BASE_START 32'h20000000
`define S0_BASE_END   32'h207fffff

//APB
`define S2_BASE_START 32'h40000000
`define S2_BASE_END   32'h4fffffff

wire hsel_s0;
wire hresp_s0;
wire hready_s0;
wire [31:0] hrdata_s0;

wire hsel_s1;
wire hresp_s1;
wire hready_s1;
wire [31:0] hrdata_s1;

wire hsel_s2;
wire hresp_s2;
wire hready_s2;
wire [31:0] hrdata_s2;

// sysahb_hready = hready_s1 & hready_s2 & hready_s3 & hready_s4, 表示总线的hready状态

// sysahb slave1 bram 32kB
// taken from system-on-chip-design-reference P23
// 只接18位地址线，虽然200 00000 到 208 00000地址的请求都会给到这，不知道该不该这样写
AHBBlockRam x_sysahb_bram (
    .HCLK(sys_clk),
    .HRESETn(sys_resetn),
    .HSEL(hsel_s0),
    .HREADY(sysahb_hready),
    .HTRANS(sysahb_htrans),
    .HSIZE(sysahb_hsize[1:0]),
    .HWRITE(sysahb_hwrite),
    .HADDR(sysahb_haddr[14:0]),
    .HWDATA(sysahb_hwdata),
    .HREADYOUT(hready_s0),
    .HRESP(hresp_s0),
    .HRDATA(hrdata_s0)
);
defparam x_sysahb_bram.AWIDTH = 15;

// sysahb slave2 default slave
// Taken from page 28 of System-on-Chip Design with Arm Cortex-M processors
ahb_defslave x_ahb_defslave(
    .HCLK(sys_clk), 
    .HRESETn(sys_resetn), 
    .HSEL(hsel_s1), 
    .HREADY(sysahb_hready),
    .HTRANS(sysahb_htrans), 
    .HREADYOUT(hready_s1), 
    .HRESP(hresp_s1) 
);

apb_subsystem u_apb_subsystem(
    .HCLK                ( sys_clk             ),
    .RESETn              ( sys_resetn          ),
    .HSEL                ( hsel_s2             ),
    .HADDR               ( sysahb_haddr[15:0]  ),
    .HTRANS              ( sysahb_htrans       ),
    .HWRITE              ( sysahb_hwrite       ),
    .HSIZE               ( sysahb_hsize        ),
    .HPROT               ( sysahb_hprot        ),
    .HREADY              ( sysahb_hready       ),
    .HWDATA              ( sysahb_hwdata       ),
    .HREADYOUT           ( hready_s2           ),
    .HRDATA              ( hrdata_s2           ),
    .HRESP               ( hresp_s2            ),
    .uart0_rxd           ( uart0_rxd           ),
    .uart0_txd           ( uart0_txd           ),
    .uart0_txen          ( uart0_txen          ),
    .timer0_extin        ( timer0_extin        ),
    .apb_interrupt       ( apb_interrupt       ),
    // .watchdog_interrupt  ( watchdog_interrupt  ),
    // .watchdog_reset      ( watchdog_reset      ),
    .gpio_portA          ( gpio_portA          ),
    .gpio_portB          ( gpio_portB          )
);

// assign hsel according to haddr
assign hsel_s0 = (sysahb_haddr >= `S0_BASE_START) && (sysahb_haddr <= `S0_BASE_END);
assign hsel_s2 = (sysahb_haddr >= `S2_BASE_START) && (sysahb_haddr <= `S2_BASE_END);
assign hsel_s1 = !hsel_s0 && !hsel_s2;

// ahb mux
// taken from system-on-chip-design-reference P150
ahb_slavemux x_ahb_slavemux(
    .HCLK       ( sys_clk       ),
    .HRESETn    ( sys_resetn    ),
    .HREADY     ( sysahb_hready ),
    .HSEL0      ( hsel_s0       ),
    .HREADYOUT0 ( hready_s0     ),
    .HRESP0     ( hresp_s0      ),
    .HRDATA0    ( hrdata_s0     ),
    .HSEL1      ( hsel_s1       ),
    .HREADYOUT1 ( hready_s1     ),
    .HRESP1     ( hresp_s1      ),
    .HRDATA1    ( hrdata_s1     ),
    .HSEL2      ( hsel_s2       ), 
    .HREADYOUT2 ( hready_s2     ),
    .HRESP2     ( hresp_s2      ),
    .HRDATA2    ( hrdata_s2     ),
    .HSEL3      ( 1'b0          ), // 暂时用不上
    .HREADYOUT3 ( 1'b1          ),
    .HRESP3     ( 1'b0          ),
    .HRDATA3    ( 32'h0         ),
    .HREADYOUT  ( sysahb_hready ),
    .HRESP      ( sysahb_hresp  ),
    .HRDATA     ( sysahb_hrdata )
);


endmodule