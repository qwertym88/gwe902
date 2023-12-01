module soc(
  input clk27m,
  input mcu_rst_signal,

  input jtag_tclk,
  inout jtag_tms
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
// 系统总线部分
wire    [31:0]  haddr_s1;
wire    [2 :0]  hburst_s1;
wire    [3 :0]  hprot_s1;
wire    [31:0]  hrdata_s1;
wire            hready_s1;
wire    [1 :0]  hresp_s1;
wire            hsel_s1;
wire    [2 :0]  hsize_s1;
wire    [1 :0]  htrans_s1;
wire    [31:0]  hwdata_s1;
wire            hwrite_s1;
// jtag支持信号
wire had_pad_jtg_tms_o;
wire had_pad_jtg_tms_oe;
wire pad_had_jtg_tclk;
wire pad_had_jtg_tms_i;
// 复位控制信号
wire pad_had_jtg_trst_b;
wire pad_had_rst_b;
wire pad_cpu_rst_b;
wire cpu_pad_soft_rst;
// 中断系统
wire pad_cpu_nmi;
wire pad_clic_int_vld;
wire pad_cpu_ext_int_b;
wire pad_cpu_sys_cnt;
// 时钟
wire sys_clk;
CLKDIV clk_div35 (
        .HCLKIN(clk27m),
        .RESETN(mcu_resetn),
        .CALIB(1'b1),
        .CLKOUT(sys_clk)
);
defparam clk_div35.DIV_MODE="3.5";

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
assign pad_clic_int_vld[ 31 : 0] = pad_vic_int_vld[ 31 : 0];
assign pad_clic_int_vld[64 - 1 : 32] = 'h0;
// CPU 中断请求信号：低电平时表示外部中断控制器发起中断申请。
assign pad_cpu_ext_int_b  =1'b1;
// 计时器
always@(posedge cpu_clk or negedge pg_reset_b)
begin
  if(!pg_reset_b)
    pad_cpu_sys_cnt[63:0] <= 64'h0;
  else
    pad_cpu_sys_cnt[63:0] <= pad_cpu_sys_cnt[63:0] + 64'h1;
end

// 两线jtag协议
assign i_pad_jtg_tms = had_pad_jtg_tms_oe ? had_pad_jtg_tms_o : 1'bz;
assign pad_had_jtg_tms_i = i_pad_jtg_tms;

openE902 x_e902 (
  // 系统总线部分
  .biu_pad_haddr        (biu_pad_haddr       ),
  .biu_pad_hwdata       (biu_pad_hwdata      ),
  .biu_pad_hburst       (biu_pad_hburst      ),
  .biu_pad_hsize        (biu_pad_hsize       ),
  .biu_pad_htrans       (biu_pad_htrans      ),
  .biu_pad_hwrite       (biu_pad_hwrite      ),
  .biu_pad_hprot        (biu_pad_hprot       ),
  .pad_biu_hrdata       (pad_biu_hrdata      ),
  .pad_biu_hready       (pad_biu_hready      ),
  .pad_biu_hresp        (pad_biu_hresp[0]    ), // 仅支持OKAY和ERROR两种响应,故只取低位
  // 指令总线部分
  .pad_iahbl_hrdata     (pad_iahbl_hrdata    ),
  .pad_iahbl_hready     (pad_iahbl_hready    ),
  .pad_iahbl_hresp      (pad_iahbl_hresp[0]  ),
  .iahbl_pad_haddr      (iahbl_pad_haddr     ),
  .iahbl_pad_hburst     (iahbl_pad_hburst    ), // E902 仅支持000 SINGLE，貌似没用
  .iahbl_pad_hprot      (iahbl_pad_hprot     ), 
  .iahbl_pad_hsize      (iahbl_pad_hsize     ),
  .iahbl_pad_htrans     (iahbl_pad_htrans    ),
  .iahbl_pad_hwdata     (iahbl_pad_hwdata    ),
  .iahbl_pad_hwrite     (iahbl_pad_hwrite    ),
  .pad_bmu_iahbl_base   (12'h000             ),
  .pad_bmu_iahbl_mask   (12'he00             ), // 指令地址空间设为512M
  // jtag支持信号
  .had_pad_jtg_tms_o    (had_pad_jtg_tms_o   ),
  .had_pad_jtg_tms_oe   (had_pad_jtg_tms_oe  ),
  .pad_had_jtg_tclk     (pad_had_jtg_tclk    ),
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
  .pll_core_cpuclk      (cpu_clk             ),
  // 其他
  // .sysio_pad_lpmd_b     (biu_pad_lpmd_b      ) // 低功耗模式状态信号
  .pad_cpu_wakeup_event (1'b0                ), // 低功耗事件唤醒
  // .had_pad_jdb_pm       (had_pad_jdb_pm      ), // 调试支持信号
  .pad_sysio_dbgrq_b    (1'b1                ), 
  .pad_cpu_dfs_req      (1'b0                ), // 动态调频
  // .cpu_pad_dfs_ack      (cpu_pad_dfs_ack     ),
);

// 指令总线只挂了一个512M的ram
cpu_mem x_cpu_mem(
  .sys_clk    (sys_clk             ),
  .sys_resetn (sys_resetn          ),
  .hrdata     (pad_iahbl_hrdata    ),
  .hready     (pad_iahbl_hready    ),
  .hresp      (pad_iahbl_hresp     ),
  .haddr      (iahbl_pad_haddr     ),
  .hburst     (iahbl_pad_hburst    ), // 实际没用
  .hprot      (iahbl_pad_hprot     ), // 实际没用
  .hsize      (iahbl_pad_hsize     ),
  .htrans     (iahbl_pad_htrans    ),
  .hwdata     (iahbl_pad_hwdata    ),
  .hwrite     (iahbl_pad_hwrite    )
);

// 系统外设总线
sysahb_periphs x_sysahb_periphs (
  .sys_clk             (sys_clk             ),
  .sys_resetn          (sys_resetn          ),
  .sysahb_haddr        (biu_pad_haddr       ),
  .sysahb_hwdata       (biu_pad_hwdata      ),
  .sysahb_hburst       (biu_pad_hburst      ),
  .sysahb_hsize        (biu_pad_hsize       ),
  .sysahb_htrans       (biu_pad_htrans      ),
  .sysahb_hwrite       (biu_pad_hwrite      ),
  .sysahb_hprot        (biu_pad_hprot       ),
  .sysahb_hrdata       (pad_biu_hrdata      ),
  .sysahb_hready       (pad_biu_hready      ),
  .sysahb_hresp        (pad_biu_hresp       )
);

/* ahb memory space

fff fffff

256kb ram 0x20000000 ~ 0x207fffff

--------------- 指令空间 0xe00*1M = 512M

512kb ram 0 ~ 0x20000000

000 00000

*/

endmodule


