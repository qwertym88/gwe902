module soc(
  input clk27m,
  input mcu_rst_signal,
  // jtag
  input jtag_tclk,
  inout jtag_tms,
  // UART
  input  wire uart0_rxd,
  output wire uart0_txd,
  output wire uart0_txen,
  // GPIO
  inout wire [7:0] gpio_portA,
  inout wire [7:0] gpio_portB
);

wire sys_resetn;

// 指令总线
wire    [31:0]  iahb_haddr;
wire    [2 :0]  iahb_hburst;
wire    [3 :0]  iahb_hprot;
wire    [2 :0]  iahb_hsize;
wire    [1 :0]  iahb_htrans;
wire    [31:0]  iahb_hwdata;
wire            iahb_hwrite;
wire            iahb_hresp; // 仅支持OKAY和ERROR两种响应,故只有一位
wire    [31:0]  iahb_hrdata;
wire            iahb_hready;
// 系统总线部分
wire    [31:0]  sysahb_haddr;
wire    [2 :0]  sysahb_hburst;
wire    [3 :0]  sysahb_hprot;
wire    [31:0]  sysahb_hrdata;
wire            sysahb_hready;
wire            sysahb_hresp; // 仅支持OKAY和ERROR两种响应,故只有一位
wire            sysahb_hsel;
wire    [2 :0]  sysahb_hsize;
wire    [1 :0]  sysahb_htrans;
wire    [31:0]  sysahb_hwdata;
wire            sysahb_hwrite;
// jtag支持信号
wire had_pad_jtg_tms_o;
wire had_pad_jtg_tms_oe;
// wire pad_had_jtg_tclk;
wire pad_had_jtg_tms_i;
// 复位控制信号
wire pad_had_jtg_trst_b;
wire pad_had_rst_b;
wire pad_cpu_rst_b;
wire [1:0] cpu_pad_soft_rst;
// 中断系统
wire pad_cpu_nmi;
wire [63:0] pad_clic_int_vld;
wire pad_cpu_ext_int_b;
wire [31:0] pad_vic_int_vld; // apb中断
reg [63:0] pad_cpu_sys_cnt;
wire watchdog_interrupt;
wire watchdog_reset;
// 时钟
wire sys_clk = clk27m;
// CLKDIV clk_div35 (
//   .HCLKIN(clk27m),
//   .RESETN(sys_resetn),
//   .CALIB(1'b1),
//   .CLKOUT(sys_clk)
// );
// defparam clk_div35.DIV_MODE="3.5";

// 复位控制
mcu_reset x_mcu_reset(
  .mcu_rst_signal(mcu_rst_signal),
  .cpu_pad_soft_rst(cpu_pad_soft_rst),
  .sys_clk(sys_clk),
  .pad_cpu_rst_b(pad_cpu_rst_b),
  .pad_had_rst_b(pad_had_rst_b),
  .pad_had_jtg_trst_b(pad_had_jtg_trst_b),
  .sys_resetn(sys_resetn)
);

// 中断源请求信号
wire nmi_req;
// assign pad_vic_int_vld = 32'h0;
assign pad_clic_int_vld[ 31 : 0] = pad_vic_int_vld[ 31 : 0];
assign pad_clic_int_vld[64 - 1 : 32] = 'h0;
// CPU 中断请求信号：低电平时表示外部中断控制器发起中断申请。
assign pad_cpu_ext_int_b = 1'b1;
// 计时器
always@(posedge sys_clk or negedge sys_resetn)
begin
  if(!sys_resetn)
    pad_cpu_sys_cnt[63:0] <= 64'h0;
  else
    pad_cpu_sys_cnt[63:0] <= pad_cpu_sys_cnt[63:0] + 64'h1;
end

// 两线jtag协议
assign jtag_tms = had_pad_jtg_tms_oe ? had_pad_jtg_tms_o : 1'bz;
assign pad_had_jtg_tms_i = jtag_tms;

openE902 x_e902 (
  // 系统总线部分
  .biu_pad_haddr        (sysahb_haddr        ),
  .biu_pad_hwdata       (sysahb_hwdata       ),
  .biu_pad_hburst       (sysahb_hburst       ),
  .biu_pad_hsize        (sysahb_hsize        ),
  .biu_pad_htrans       (sysahb_htrans       ),
  .biu_pad_hwrite       (sysahb_hwrite       ),
  .biu_pad_hprot        (sysahb_hprot        ),
  .pad_biu_hrdata       (sysahb_hrdata       ),
  .pad_biu_hready       (sysahb_hready       ),
  .pad_biu_hresp        (sysahb_hresp        ), 
  // 指令总线部分
  .pad_iahbl_hrdata     (iahb_hrdata         ),
  .pad_iahbl_hready     (iahb_hready         ),
  .pad_iahbl_hresp      (iahb_hresp          ),
  .iahbl_pad_haddr      (iahb_haddr          ),
  .iahbl_pad_hburst     (iahb_hburst         ), // E902 仅支持000 SINGLE，貌似没用
  .iahbl_pad_hprot      (iahb_hprot          ), 
  .iahbl_pad_hsize      (iahb_hsize          ),
  .iahbl_pad_htrans     (iahb_htrans         ),
  .iahbl_pad_hwdata     (iahb_hwdata         ),
  .iahbl_pad_hwrite     (iahb_hwrite         ),
  .pad_bmu_iahbl_base   (12'h000             ),
  .pad_bmu_iahbl_mask   (12'he00             ), // 指令地址空间设为512M
  // jtag支持信号
  .had_pad_jtg_tms_o    (had_pad_jtg_tms_o   ),
  .had_pad_jtg_tms_oe   (had_pad_jtg_tms_oe  ),
  .pad_had_jtg_tclk     (jtag_tclk           ),
  .pad_had_jtg_tms_i    (pad_had_jtg_tms_i   ),
  // 复位控制信号
  .pad_had_jtg_trst_b   (pad_had_jtg_trst_b  ), 
  .pad_had_rst_b        (pad_had_rst_b       ),
  .pad_cpu_rst_addr     (32'h0               ),
  .pad_cpu_rst_b        (pad_cpu_rst_b       ),
  .cpu_pad_soft_rst     (cpu_pad_soft_rst    ),
  // 中断系统
  .pad_cpu_nmi          (nmi_req             ),
  .pad_clic_int_vld     (pad_clic_int_vld    ),
  .pad_cpu_ext_int_b    (pad_cpu_ext_int_b   ),
  .pad_cpu_sys_cnt      (pad_cpu_sys_cnt     ),
  // cpu观测信号
  // .cp0_pad_mcause       (cp0_pad_mcause      ),
  // .cp0_pad_mintstatus   (cp0_pad_mintstatus  ),
  // .cp0_pad_mstatus      (cp0_pad_mstatus     ),
  // .cpu_pad_lockup       (cpu_pad_lockup      ),
  // .iu_pad_gpr_data      (biu_pad_wb_gpr_data ),
  // .iu_pad_gpr_index     (biu_pad_wb_gpr_index),
  // .iu_pad_gpr_we        (biu_pad_wb_gpr_en   ),
  // .iu_pad_inst_retire   (biu_pad_retire      ),
  // .iu_pad_inst_split    (iu_pad_inst_split   ),
  // .iu_pad_retire_pc     (biu_pad_retire_pc   ),
  // dft
  .pad_yy_gate_clk_en_b (1'b1                ),
  .pad_yy_test_mode     (1'b0                ),
  // 时钟
  .pll_core_cpuclk      (sys_clk             ),
  // 其他
  // .sysio_pad_lpmd_b     (biu_pad_lpmd_b      ) // 低功耗模式状态信号
  .pad_cpu_wakeup_event (1'b0                ), // 低功耗事件唤醒
  // .had_pad_jdb_pm       (had_pad_jdb_pm      ), // 调试支持信号
  .pad_sysio_dbgrq_b    (1'b1                ), 
  .pad_cpu_dfs_req      (1'b0                ) // 动态调频
  // .cpu_pad_dfs_ack      (cpu_pad_dfs_ack     ),
);

// 指令总线只挂了一个ram
cpu_mem x_cpu_mem(
  .sys_clk    (sys_clk             ),
  .sys_resetn (sys_resetn          ),
  .hrdata     (iahb_hrdata         ),
  .hready     (iahb_hready         ),
  .hresp      (iahb_hresp          ),
  .haddr      (iahb_haddr          ),
  .hburst     (iahb_hburst         ), // 实际没用
  .hprot      (iahb_hprot          ), // 实际没用
  .hsize      (iahb_hsize          ),
  .htrans     (iahb_htrans         ),
  .hwdata     (iahb_hwdata         ),
  .hwrite     (iahb_hwrite         )
);

// 系统外设总线
sysahb_periphs x_sysahb_periphs (
  .sys_clk             (sys_clk              ),
  .sys_resetn          (sys_resetn           ),
  .sysahb_haddr        (sysahb_haddr         ),
  .sysahb_hwdata       (sysahb_hwdata        ),
  .sysahb_hburst       (sysahb_hburst        ),
  .sysahb_hsize        (sysahb_hsize         ),
  .sysahb_htrans       (sysahb_htrans        ),
  .sysahb_hwrite       (sysahb_hwrite        ),
  .sysahb_hprot        (sysahb_hprot         ),
  .sysahb_hrdata       (sysahb_hrdata        ),
  .sysahb_hready       (sysahb_hready        ),
  .sysahb_hresp        (sysahb_hresp         ),
  .uart0_rxd           ( uart0_rxd           ),
  .uart0_txd           ( uart0_txd           ),
  .uart0_txen          ( uart0_txen          ),
  .timer0_extin        ( sys_clk             ),
  .timer1_extin        ( sys_clk             ),
  .apbsubsys_interrupt ( pad_vic_int_vld     ),
  .gpio_portA          ( gpio_portA          ),
  .gpio_portB          ( gpio_portB          )
);

/* ahb memory space

fff fffff

32kb ram 0x20000000 ~ 0x207fffff

--------------- 指令空间 0xe00*1M = 512M

64kb ram 0 ~ 0x20000000

000 00000

*/

endmodule


