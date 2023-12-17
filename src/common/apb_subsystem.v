module apb_subsystem (
    input  wire           HCLK,
    input  wire           HRESETn,
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
CLKDIV clk_div2 (
  .HCLKIN(HCLK),
  .RESETN(HRESETn),
  .CALIB(1'b1),
  .CLKOUT(PCLK)
);
defparam clk_div2.DIV_MODE="4";


wire        PRESETn;
wire        PENABLE; // apb设备使能
wire        PSEL;
wire [15:0] PADDR;
wire        PWRITE;
wire [31:0] PWDATA;
wire [3:0]  PSTRB;
wire [2:0]  PPROT;
wire [31:0] PRDATA;
wire        PREADY;
wire        PRESP;
wire        PSLVERR;
assign PRESETn = HRESETn;

// 控制apb桥时钟信号使能
// wire PCLKG;
// wire APBACTIVE;
// assign PCLKG = APBACTIVE ? PCLK : 1'b0;
// assign PCLKG = PCLK;

wire        uart0_psel;
wire [31:0] uart0_prdata;
wire        uart0_pready;
wire        uart0_pslverr;
wire uart0_txint;
wire uart0_rxint;
wire uart0_txovrint;
wire uart0_rxovrint;
wire uart0_overflow_int;
wire uart0_combined_int;

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
    {20{1'b0}}, 
    gpioB_int[7:0],
    gpioA_int[7:0],
    gpioB_combint,
    gpioA_combint,
    uart0_txint,
    uart0_rxint
};

cmsdk_ahb_to_apb_async#(
    .ADDRWIDTH ( 16 )
)u_cmsdk_ahb_to_apb_async(
    .HCLK      ( HCLK      ),
    .HRESETn   ( HRESETn   ),
    .HSEL      ( HSEL      ),
    .HADDR     ( HADDR     ),
    .HTRANS    ( HTRANS    ),
    .HSIZE     ( HSIZE     ),
    .HPROT     ( HPROT     ),
    .HWRITE    ( HWRITE    ),
    .HREADY    ( HREADY    ),
    .HWDATA    ( HWDATA    ),
    .HREADYOUT ( HREADYOUT ),
    .HRDATA    ( HRDATA    ),
    .HRESP     ( HRESP     ),
    .PCLK      ( PCLK      ),
    .PRESETn   ( PRESETn   ),
    .PADDR     ( PADDR     ),
    .PENABLE   ( PENABLE   ),
    .PSTRB     ( PSTRB     ),
    .PPROT     ( PPROT     ),
    .PWRITE    ( PWRITE    ),
    .PWDATA    ( PWDATA    ),
    .PSEL      ( PSEL      ),
    .PRDATA    ( PRDATA    ),
    .PREADY    ( PREADY    ),
    .PSLVERR   ( PSLVERR   )
    // .APBACTIVE ( APBACTIVE )
);

// APB slave multiplexer
cmsdk_apb_slave_mux#( 
    // Parameter to determine which ports are used
    .PORT0_ENABLE   ( 1 ), // uart0
    .PORT1_ENABLE   ( 1 ), // gpioa
    .PORT2_ENABLE   ( 1 ) // gpiob
)
u_apb_slave_mux (
    // Inputs
    .DECODE4BIT        (PADDR[15:12]), // 高4位分成16个apb设备
    .PSEL              (PSEL),
    // PSEL (output) and return status & data (inputs) for each port
    .PSEL0             (uart0_psel),
    .PREADY0           (uart0_pready),
    .PRDATA0           (uart0_prdata),
    .PSLVERR0          (uart0_pslverr),
    .PSEL1             (gpioA_psel),
    .PREADY1           (gpioA_pready),
    .PRDATA1           (gpioA_prdata),
    .PSLVERR1          (gpioA_pslverr),
    .PSEL2             (gpioB_psel),
    .PREADY2           (gpioB_pready),
    .PRDATA2           (gpioB_prdata),
    .PSLVERR2          (gpioB_pslverr),
    // Output
    .PREADY            (PREADY),
    .PRDATA            (PRDATA),
    .PSLVERR           (PSLVERR)
);

cmsdk_apb_uart u_cmsdk_apb_uart(
    .PCLK      ( PCLK      ),
    .PCLKG     ( PCLK      ),
    .PRESETn   ( PRESETn   ),
    .PSEL      ( uart0_psel      ),
    .PADDR     ( PADDR[11:2]     ),
    .PENABLE   ( PENABLE   ),
    .PWRITE    ( PWRITE    ),
    .PWDATA    ( PWDATA    ),
    .ECOREVNUM ( 4'h0      ),
    .PRDATA    ( uart0_prdata    ),
    .PREADY    ( uart0_pready    ),
    .PSLVERR   ( uart0_pslverr   ),
    .RXD       ( uart0_rxd       ),
    .TXD       ( uart0_txd       ),
    .TXEN      ( uart0_txen      ),
    // .BAUDTICK  ( BAUDTICK  ),
    .TXINT     ( uart0_txint     ),
    .RXINT     ( uart0_rxint     ),
    .TXOVRINT  ( uart0_txovrint  ),
    .RXOVRINT  ( uart0_rxovrint  ),
    .UARTINT   ( uart0_combined_int   )
);


apb_gpio#(
    .PortWidth ( 8 )
) u_apb_gpioA(
    .PCLK    ( PCLK    ),
    .PRESETn ( PRESETn ),
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