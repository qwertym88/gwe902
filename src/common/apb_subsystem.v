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
    // Interrupt outputs
    output wire   [31:0]  apb_interrupt,
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

wire        PCLKEN;
wire        PRESETn;
wire [15:0] PADDR;
wire        PWRITE;
wire [31:0] PWDATA;
wire [2:0]  PPROT;
wire [3:0]  PSTRB;
wire        PREADY;
wire [31:0] PRDATA;
wire        PSLVERR;
assign PCLKEN = 1'b1;
assign PRESETn = RESETn;

// 控制apb桥时钟信号使能
wire PCLKG;
wire APBACTIVE;

wire        gpioA_psel;
wire [31:0] gpioA_prdata;
wire        gpioA_pready;
wire        gpioA_pslverr;
wire [7:0] gpioA_in;
wire [7:0] gpioA_out;
wire [7:0] gpioA_outEn;
wire [7:0] gpioA_int;
wire gpioA_combint;

wire        gpioB_psel;
wire [31:0] gpioB_prdata;
wire        gpioB_pready;
wire        gpioB_pslverr;
wire [7:0] gpioB_in;
wire [7:0] gpioB_out;
wire [7:0] gpioB_outEn;
wire [7:0] gpioB_int;
wire gpioB_combint;

wire        uart0_psel;
wire [31:0] uart0_prdata;
wire        uart0_pready;
wire        uart0_pslverr;
wire uart0_txint;
wire uart0_rxint;
// wire uart0_txovrint;
// wire uart0_rxovrint;
// wire uart0_overflow_int;
// wire uart0_combined_int;
wire uart0_baudtick;
wire uart0_rx;
wire uart0_tx;

wire [31:0]  apbsubsys_interrupt;
assign apb_interrupt[31:0] = {
    {20{1'b0}}, 
    gpioB_int[7:0],
    gpioA_int[7:0],
    gpioB_combint,
    gpioA_combint,
    // uart0_overflow_int,
    uart0_txint,
    uart0_rxint
};

ahb_to_apb u_ahb_to_apb(
    .HCLK      ( HCLK      ),
    .HRESETn   ( RESETn   ),
    .HSEL      ( HSEL      ),
    .HADDR     ( HADDR[14:0]     ),
    .HTRANS    ( HTRANS    ),
    .HSIZE     ( HSIZE     ),
    .HWRITE    ( HWRITE    ),
    .HNONSEC   ( 1'b1      ),
    .HPROT     ( {3'b000,HPROT}     ),
    .HREADY    ( HREADY    ),
    .HWDATA    ( HWDATA    ),
    .HREADYOUT ( HREADYOUT ),
    .HRDATA    ( HRDATA    ),
    .HRESP     ( HRESP     ),
    .PADDR     ( PADDR     ),
    .PENABLE   ( PENABLE   ),
    .PWRITE    ( PWRITE    ),
    .PPROT     ( PPROT     ),
    .PSTRB     ( PSTRB     ),
    .PWDATA    ( PWDATA    ),
    .PSEL0     ( uart0_psel     ),
    .PSEL1     ( gpioA_psel     ),
    .PSEL2     ( gpioB_psel     ),
    .PRDATA0   ( uart0_prdata   ),
    .PRDATA1   ( gpioA_prdata   ),
    .PRDATA2   ( gpioB_prdata   ),
    .PREADY0   ( uart0_pready   ),
    .PREADY1   ( gpioA_pready   ),
    .PREADY2   ( gpioB_pready   ),
    .PSLVERR0  ( uart0_pslverr  ),
    .PSLVERR1  ( gpioA_pslverr  ),
    .PSLVERR2  ( gpioB_pslverr  )
);


apb_uart u_apb_uart_0 (
    .PCLK        (PCLK),     // Peripheral clock
    .PRESETn     (PRESETn),  // Reset
    .PSEL        (uart0_psel),     // APB interface inputs
    .PADDR       (PADDR[7:2]), // 按字访问寄存器
    .PENABLE     (PENABLE),
    .PWRITE      (PWRITE),
    .PWDATA      (PWDATA),
    .PRDATA      (uart0_prdata),   // APB interface outputs
    .PREADY      (uart0_pready), // readyout
    .PSLVERR     (uart0_pslverr),
    .RXD         (uart0_rx),      // Receive data
    .TXD         (uart0_tx),      // Transmit data
    .TXEN        (uart0_txen),     // Transmit Enabled
    .BAUDTICK    (uart0_baudtick),   // Baud rate x16 tick output (for testing)
    .TXINT       (uart0_txint),       // Transmit Interrupt
    .RXINT       (uart0_rxint)       // Receive  Interrupt
);

assign uart0_rx = uart0_rxd;
assign uart0_txd = uart0_tx;

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