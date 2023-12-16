module apb_subsystem (
    input  wire           HCLK,
    input  wire           RESETn,
    // ahb
    input  wire           HSEL,
    input  wire   [15:0]  HADDR,
    input  wire    [1:0]  HTRANS,
    input  wire           HWRITE,
    input  wire    [2:0]  HSIZE,
    input  wire    [3:0]  HPROT,
    input  wire           HREADY,
    input  wire   [31:0]  HWDATA,
    output wire           HREADYOUT,
    output wire   [31:0]  HRDATA,
    output wire           HRESP,
    // Peripherals
    // UART
    input  wire           uart0_rxd,
    output wire           uart0_txd,
    output wire           uart0_txen,
    // Timer
    input  wire           timer0_extin,
    // Interrupt outputs
    output wire   [31:0]  apb_interrupt,
    // output wire           watchdog_interrupt,
    // output wire           watchdog_reset,
    // GPIO
    inout wire [7:0] gpio_portA,
    inout wire [7:0] gpio_portB
);

// pclk与hclk同相不同频
wire PCLK;
wire PENABLE; // apb设备使能
// CLKDIV clk_div4 (
//   .HCLKIN(HCLK),
//   .RESETN(RESETn),
//   .CALIB(1'b1),
//   .CLKOUT(PCLK)
// );
// defparam clk_div4.DIV_MODE="4";
assign PCLK = HCLK;

wire PCLKEN;
wire PRESETn;
wire [11:0] PADDR;
wire PWRITE;
wire [31:0] PWDATA;
assign PCLKEN = 1'b1;
assign PRESETn = RESETn;

// 控制apb桥时钟信号使能
wire PCLKG;
wire APBACTIVE;

wire gpioA_psel;
wire gpioA_pready;
wire [31:0] gpioA_prdata;
wire gpioA_pslverr;
wire [7:0] gpioA_in;
wire [7:0] gpioA_out;
wire [7:0] gpioA_outEn;
wire [7:0] gpioA_int;
wire gpioA_combint;

wire gpioB_psel;
wire gpioB_pready;
wire [31:0] gpioB_prdata;
wire gpioB_pslverr;
wire [7:0] gpioB_in;
wire [7:0] gpioB_out;
wire [7:0] gpioB_outEn;
wire [7:0] gpioB_int;
wire gpioB_combint;

wire [31:0]  apbsubsys_interrupt;

/*
apbsubsys_interrupt[31:0] = {
    {16{1'b0}},                       // 16-31 (AHB GPIO #0 individual interrupt)
    1'b0,                             // 15 (DMA interrupt)
    i_uart2_overflow_int,             // 14
    i_uart1_overflow_int,             // 13
    i_uart0_overflow_int,             // 12
    1'b0,                             // 11
    i_dualtimer2_int,                 // 10
    i_timer1_int,                     // 9
    i_timer0_int,                     // 8
    1'b0,                             // 7 (GPIO #1 combined interrupt)
    1'b0,                             // 6 (GPIO #0 combined interrupt)
    i_uart2_txint,                    // 5
    i_uart2_rxint,                    // 4
    i_uart1_txint,                    // 3
    i_uart1_rxint,                    // 2
    i_uart0_txint,                    // 1
    i_uart0_rxint};                   // 0
*/

assign apb_interrupt[31:0] = {
    apbsubsys_interrupt[5:0],
    gpioA_combint,
    gpioB_combint,
    apbsubsys_interrupt[15:8],
    gpioA_int[7:0],
    gpioB_int[7:0]
};

// assign apb_interrupt[31:0] = 32'h0;

// assign apbsubsys_interrupt[6] = gpioA_combint;
// assign apbsubsys_interrupt[7] = gpioB_combint;
// assign apbsubsys_interrupt[23:16] = gpioA_int;
// assign apbsubsys_interrupt[31:24] = gpioB_int;

cmsdk_apb_subsystem#(
    .APB_EXT_PORT12_ENABLE      ( 1 ),
    .APB_EXT_PORT13_ENABLE      ( 1 ),
    .INCLUDE_APB_TEST_SLAVE     ( 0 ),
    .INCLUDE_APB_TIMER0         ( 1 ),
    .INCLUDE_APB_TIMER1         ( 0 ),
    .INCLUDE_APB_DUALTIMER0     ( 0 ),
    .INCLUDE_APB_UART0          ( 1 ),
    .INCLUDE_APB_UART1          ( 0 ),
    .INCLUDE_APB_UART2          ( 0 ),
    .INCLUDE_APB_WATCHDOG       ( 0 ),
    .BE                         ( 0 )
) u_cmsdk_apb_subsystem(
    .HCLK                 ( HCLK                ),
    .HRESETn              ( RESETn             ),
    .HSEL                 ( HSEL                ),
    .HADDR                ( HADDR               ),
    .HTRANS               ( HTRANS              ),
    .HWRITE               ( HWRITE              ),
    .HSIZE                ( HSIZE               ),
    .HPROT                ( HPROT               ),
    .HREADY               ( HREADY              ),
    .HWDATA               ( HWDATA              ),
    .HREADYOUT            ( HREADYOUT           ),
    .HRDATA               ( HRDATA              ),
    .HRESP                ( HRESP               ),
    .PCLK                 ( PCLK                ),
    .PCLKG                ( PCLKG               ),
    .PCLKEN               ( PCLKEN              ),
    .PRESETn              ( PRESETn             ),
    .PADDR                ( PADDR               ),
    .PWRITE               ( PWRITE              ),
    .PWDATA               ( PWDATA              ),
    .PENABLE              ( PENABLE             ),
    .ext12_psel           ( gpioA_psel          ),
    .ext13_psel           ( gpioB_psel          ),
    .ext12_prdata         ( gpioA_prdata        ),
    .ext12_pready         ( gpioA_pready        ),
    .ext12_pslverr        ( gpioA_pslverr       ),
    .ext13_prdata         ( gpioB_prdata        ),
    .ext13_pready         ( gpioB_pready        ),
    .ext13_pslverr        ( gpioB_pslverr       ),
    .APBACTIVE            ( APBACTIVE           ),
    .uart0_rxd            ( uart0_rxd           ),
    .uart0_txd            ( uart0_txd           ),
    .uart0_txen           ( uart0_txen          ),
    .timer0_extin         ( timer0_extin        ),
    .apbsubsys_interrupt  ( apbsubsys_interrupt )
    // .watchdog_interrupt   ( watchdog_interrupt  ),
    // .watchdog_reset       ( watchdog_reset      )
);

// The AHB to APB bridge generates APBACTIVE signal. It enables you to handle clock gating for gated APB 
// bus clock, PCLKG in the example system.
// When there is no APB transfer, you can stop the gated APB bus clock to reduce power.
assign PCLKG = 1'b1;

apb_gpio#(
    .PortWidth ( 8 )
) u_apb_gpioA(
    .PCLK    ( PCLK    ),
    .PRESETn ( RESETn ),
    .PSEL    ( gpioA_psel    ),
    .PADDR   ( PADDR[7:2]   ),
    .PENABLE ( PENABLE ),
    .PWRITE  ( PWRITE  ),
    .PWDATA  ( PWDATA  ),
    .PRDATA  ( gpioA_prdata  ),
    .PREADY  ( gpioA_pready  ),
    .PSLVERR ( gpioA_pslverr ),
    .PORTIN  ( gpioA_in  ),
    .PORTOUT ( gpioA_out ),
    .PORTEN  ( gpioA_outEn  ),
    .GPIOINT ( gpioA_int ),
    .COMBINT  ( gpioA_combint  )
);

generate
     genvar i;
     for(i=0;i<8;i=i+1)
         begin: gpioa
             assign gpio_portA[i] = gpioA_outEn[i] ? gpioA_out[i] : 1'bz;
             assign gpioA_in[i] = gpio_portA[i];
         end
 endgenerate


apb_gpio#(
    .PortWidth ( 8 )
)u_apb_gpioB(
    .PCLK    ( PCLK    ),
    .PRESETn ( PRESETn ),
    .PSEL    ( gpioB_psel    ),
    .PADDR   ( PADDR[7:2]   ),
    .PENABLE ( PENABLE ),
    .PWRITE  ( PWRITE  ),
    .PWDATA  ( PWDATA  ),
    .PRDATA  ( gpioB_prdata  ),
    .PREADY  ( gpioB_pready  ),
    .PSLVERR ( gpioB_pslverr ),
    .PORTIN  ( gpioB_in  ),
    .PORTOUT ( gpioB_out ),
    .PORTEN  ( gpioB_outEn  ),
    .GPIOINT ( gpioB_int ),
    .COMBINT  ( gpioB_combint  )
);

generate
     genvar j;
     for(j=0;j<8;j=j+1)
         begin: gpiob
             assign gpio_portB[j] = gpioB_outEn[j] ? gpioB_out[j] : 1'bz;
             assign gpioB_in[j] = gpio_portB[j];
         end
 endgenerate

    
endmodule