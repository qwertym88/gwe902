module soc(
  input clk27m,
  input mcu_rst_signal,

  input jtag_tclk,
  inout jtag_tms
);

/////////////////////////////////////input and output////////////////////////////
// 暂时用不上  
// inout   [7 :0]  b_pad_gpio_porta;  
// input           i_pad_uart0_sin;    
// output          o_pad_uart0_sout;     

// wire    [7 :0]  b_pad_gpio_porta;   
wire    [31:0]  biu_pad_haddr;      
wire    [2 :0]  biu_pad_hburst;     
wire    [3 :0]  biu_pad_hprot;      
wire    [2 :0]  biu_pad_hsize;      
wire    [1 :0]  biu_pad_htrans;     
wire    [31:0]  biu_pad_hwdata;     
wire            biu_pad_hwrite;     
wire    [1 :0]  biu_pad_lpmd_b;     
// wire            clk_en;             
// wire            corec_pmu_sleep_out;
// wire            cpu_clk;    

// wire            fifo_biu_hready;    
// wire    [31:0]  fifo_pad_haddr;     
// wire    [2 :0]  fifo_pad_hburst;    
// wire    [3 :0]  fifo_pad_hprot;     
// wire    [2 :0]  fifo_pad_hsize;     
// wire    [1 :0]  fifo_pad_htrans;    
// wire            fifo_pad_hwrite; 

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

// ?
wire    [31:0]  haddr_s2; 
wire    [31:0]  hrdata_s2;
wire            hready_s2;
wire    [1 :0]  hresp_s2;  
wire            hsel_s2;  
wire    [31:0]  hwdata_s2; 
wire            hwrite_s2; 

wire    [31:0]  haddr_s3;  
wire    [2 :0]  hburst_s3; 
wire    [3 :0]  hprot_s3;
wire    [31:0]  hrdata_s3; 
wire            hready_s3;
wire    [1 :0]  hresp_s3; 
wire            hsel_s3; 
wire    [2 :0]  hsize_s3; 
wire    [1 :0]  htrans_s3;  
wire    [31:0]  hwdata_s3;
wire            hwrite_s3; 

wire    [31:0]  haddr_s4;  
wire    [2 :0]  hburst_s4; 
wire    [3 :0]  hprot_s4; 
wire    [31:0]  hrdata_s4; 
wire            hready_s4; 
wire    [1 :0]  hresp_s4; 
wire            hsel_s4; 
wire    [2 :0]  hsize_s4;  
wire    [1 :0]  htrans_s4;                   
wire    [31:0]  hwdata_s4; 
wire            hwrite_s4;              

wire            hmastlock; 


// wire            i_pad_clk;          
wire            i_pad_cpu_jtg_rst_b;
// wire            i_pad_jtg_nrst_b;   
// wire            i_pad_jtg_tclk;     
// wire            i_pad_jtg_tms;      
// wire            i_pad_jtg_trst_b;   
// wire            i_pad_rst_b;        
// wire            i_pad_uart0_sin;    
wire            nmi_req;            
// wire            o_pad_uart0_sout;   
wire    [31:0]  pad_biu_hrdata;     
wire            pad_biu_hready;     
wire    [1 :0]  pad_biu_hresp;      
wire            pad_cpu_rst_b;      
wire            pad_had_jtg_tclk;   
wire            pad_had_jtg_tms_i;  
wire            pad_had_jtg_trst_b; 
wire            pad_had_jtg_trst_b_pre; 
wire    [31:0]  pad_vic_int_vld;    
wire            per_clk;            
wire            pg_reset_b;         
wire            pmu_corec_isolation;
wire            pmu_corec_sleep_in; 
wire            smpu_deny;          
wire            sys_rst;            
wire            wakeup_req;      


mcu_reset x_mcu_reset(
  .mcu_rst_signal(mcu_rst_signal),
  .poweron_resetn(poweron_resetn),
  .cpu_pad_soft_rst(cpu_pad_soft_rst),
  .sys_clk(sys_clk),
  .pad_cpu_rst_b(pad_cpu_rst_b),
  .pad_had_rst_b(pad_had_rst_b),
  .pad_had_jtg_trst_b(pad_had_jtg_trst_b)
);

wire sys_clk;
CLKDIV clk_div35 (
        .HCLKIN(clk27m),
        .RESETN(mcu_resetn),
        .CALIB(1'b1),
        .CLKOUT(sys_clk)
);
defparam clk_div35.DIV_MODE="3.5";

openE902 x_e902 (
  .biu_pad_haddr        (biu_pad_haddr       ),
  .biu_pad_hburst       (biu_pad_hburst      ),
  .biu_pad_hprot        (biu_pad_hprot       ),
  .biu_pad_hsize        (biu_pad_hsize       ),
  .biu_pad_htrans       (biu_pad_htrans      ),
  .biu_pad_hwdata       (biu_pad_hwdata      ),
  .biu_pad_hwrite       (biu_pad_hwrite      ),
  .cp0_pad_mcause       (cp0_pad_mcause      ),
  .cp0_pad_mintstatus   (cp0_pad_mintstatus  ),
  .cp0_pad_mstatus      (cp0_pad_mstatus     ),
  .cpu_pad_dfs_ack      (cpu_pad_dfs_ack     ),
  .cpu_pad_lockup       (cpu_pad_lockup      ),
  .cpu_pad_soft_rst     (cpu_pad_soft_rst    ),
  .had_pad_jdb_pm       (had_pad_jdb_pm      ),
  .had_pad_jtg_tms_o    (had_pad_jtg_tms_o   ),
  .had_pad_jtg_tms_oe   (had_pad_jtg_tms_oe  ),
  .iahbl_pad_haddr      (iahbl_pad_haddr     ),
  .iahbl_pad_hburst     (iahbl_pad_hburst    ), // E902 仅支持000 SINGLE，貌似没用
  .iahbl_pad_hprot      (iahbl_pad_hprot     ), // 貌似也没用？
  .iahbl_pad_hsize      (iahbl_pad_hsize     ),
  .iahbl_pad_htrans     (iahbl_pad_htrans    ),
  .iahbl_pad_hwdata     (iahbl_pad_hwdata    ),
  .iahbl_pad_hwrite     (iahbl_pad_hwrite    ),
  .iu_pad_gpr_data      (biu_pad_wb_gpr_data ),
  .iu_pad_gpr_index     (biu_pad_wb_gpr_index),
  .iu_pad_gpr_we        (biu_pad_wb_gpr_en   ),
  .iu_pad_inst_retire   (biu_pad_retire      ),
  .iu_pad_inst_split    (iu_pad_inst_split   ),
  .iu_pad_retire_pc     (biu_pad_retire_pc   ),
  .pad_biu_hrdata       (pad_biu_hrdata      ),
  .pad_biu_hready       (pad_biu_hready      ),
  .pad_biu_hresp        (pad_biu_hresp[0]    ), // E902仅支持OKAY和ERROR两种响应,故只取低位
  .pad_bmu_iahbl_base   (12'h000             ),
  .pad_bmu_iahbl_mask   (12'he00             ), // 指令地址空间512M
  .pad_clic_int_vld     (pad_clic_int_vld    ),
  .pad_cpu_dfs_req      (1'b0                ),
  .pad_cpu_ext_int_b    (pad_cpu_ext_int_b   ),
  .pad_cpu_nmi          (nmi_req             ),
  .pad_cpu_rst_addr     (32'h0               ),
  .pad_cpu_rst_b        (cpu_rst             ),
  .pad_cpu_sys_cnt      (pad_cpu_sys_cnt     ),
  .pad_cpu_wakeup_event (1'b0                ), // 低功耗事件唤醒
  .pad_had_jtg_tclk     (pad_had_jtg_tclk    ),
  .pad_had_jtg_tms_i    (pad_had_jtg_tms_i   ),
  .pad_had_jtg_trst_b   (pad_had_jtg_trst_b  ), // 对吗？
  .pad_had_rst_b        (sys_resetn          ),
  .pad_iahbl_hrdata     (pad_iahbl_hrdata    ),
  .pad_iahbl_hready     (pad_iahbl_hready    ),
  .pad_iahbl_hresp      (pad_iahbl_hresp[0]  ),
  .pad_sysio_dbgrq_b    (1'b1                ),
  .pad_yy_gate_clk_en_b (1'b1                ),
  .pad_yy_test_mode     (1'b0                ),
  .pll_core_cpuclk      (cpu_clk             ) 
//   .sysio_pad_lpmd_b     (biu_pad_lpmd_b      ) // 低功耗模式状态信号
);

// 中断控制器中断源请求信号
assign pad_clic_int_vld[ 31 : 0] = pad_vic_int_vld[ 31 : 0];
assign pad_clic_int_vld[64 - 1 : 32] = 'h0;
// CPU 中断请求信号：低电平时表示外部中断控制器发起中断申请。
assign pad_cpu_ext_int_b  =1'b1;


always@(posedge cpu_clk or negedge pg_reset_b)
begin
  if(!pg_reset_b)
    pad_cpu_sys_cnt[63:0] <= 64'h0;
  else
    pad_cpu_sys_cnt[63:0] <= pad_cpu_sys_cnt[63:0] + 64'h1;
end

assign i_pad_jtg_tms = had_pad_jtg_tms_oe ? had_pad_jtg_tms_o : 1'bz;
assign pad_had_jtg_tms_i = i_pad_jtg_tms;

iahb_mem_ctrl  x_iahb_mem_ctrl (
  .lite_mmc_hsel       (iahbl_pad_htrans[1]), // E902 仅支持 IDLE 和 NONSEQ 两种传输类型。
  .lite_yy_haddr       (iahbl_pad_haddr    ),
  .lite_yy_hsize       (iahbl_pad_hsize    ),
  .lite_yy_htrans      (iahbl_pad_htrans   ),
  .lite_yy_hwdata      (iahbl_pad_hwdata   ),
  .lite_yy_hwrite      (iahbl_pad_hwrite   ),
  .mmc_lite_hrdata     (pad_iahbl_hrdata   ),
  .mmc_lite_hready     (pad_iahbl_hready   ),
  .mmc_lite_hresp      (pad_iahbl_hresp    ),
  .pad_biu_bigend_b    (pad_biu_bigend_b   ),
  .pad_cpu_rst_b       (sys_resetn         ),
  .pll_core_cpuclk     (cpu_clk            )
);

//***********************Instance cpu_sub_system_ahb****************************
cpu_sub_system_ahb  x_cpu_sub_system_ahb (
  .biu_pad_haddr        (biu_pad_haddr       ),
  .biu_pad_hburst       (biu_pad_hburst      ),
  .biu_pad_hprot        (biu_pad_hprot       ),
  .biu_pad_hsize        (biu_pad_hsize       ),
  .biu_pad_htrans       (biu_pad_htrans      ),
  .biu_pad_hwdata       (biu_pad_hwdata      ),
  .biu_pad_hwrite       (biu_pad_hwrite      ),
//   .biu_pad_lpmd_b       (biu_pad_lpmd_b      ), 低功耗 sysio_pad_lpmd_b
//   .corec_pmu_sleep_out  (corec_pmu_sleep_out ), 无用
  .cpu_clk              (sys_clk             ),
  .i_pad_jtg_tms        (i_pad_jtg_tms       ), // ?
  .nmi_req              (nmi_req             ), // 不可屏蔽中断信号?
  .pad_biu_bigend_b     (1'b1                ), // 大端存储，0有效
  .pad_biu_hrdata       (pad_biu_hrdata      ),
  .pad_biu_hready       (pad_biu_hready      ), 

  .pad_biu_hresp        (pad_biu_hresp       ),
  .pad_cpu_rst_b        (pad_cpu_rst_b       ), // ?
  .pad_had_rst_b        (pad_had_rst_b       ),

  .pad_had_jtg_tclk     (pad_had_jtg_tclk    ),
  .pad_had_jtg_tms_i    (pad_had_jtg_tms_i   ),
  .pad_had_jtg_trst_b   (pad_had_jtg_trst_b  ),
//+   .had_pad_jtg_tms_o(jtag_tms_o),
//+   .had_pad_jtg_tms_oe(jtag_tms_oe),   ?
/*
assign i_pad_jtg_tms = had_pad_jtg_tms_oe ? had_pad_jtg_tms_o : 1'bz;
assign pad_had_jtg_tms_i = i_pad_jtg_tms;
*/

  .pad_vic_int_vld      (pad_vic_int_vld     ), // 中断信号，?
  // .pad_yy_gate_clk_en_b (1'b0                ), // 门控时钟使能信号:当在 scan 模式下可将该信号接为 scan_enable，其他时刻可接 0
  // .pad_yy_test_mode     (1'b0                ), // 测试信号
//   .pg_reset_b           (pg_reset_b          ), reset ?
//   .pmu_corec_isolation  (pmu_corec_isolation ), 
//   .pmu_corec_sleep_in   (pmu_corec_sleep_in  ), apb?
  .sys_rst              (sys_rst             ),
  .wakeup_req           (wakeup_req          ) // apb？
);

//assign pad_had_jtg_trst_b_pre = i_pad_cpu_jtg_rst_b;


//***********************Instance ahb bus arbiter****************************
ahb  x_ahb (
  .biu_pad_haddr   (biu_pad_haddr ), 
  .biu_pad_hburst  (biu_pad_hburst),
  .biu_pad_hprot   (biu_pad_hprot ),
  .biu_pad_hsize   (biu_pad_hsize ),
  .biu_pad_htrans  (biu_pad_htrans),
  .biu_pad_hwdata  (biu_pad_hwdata ),
  .biu_pad_hwrite  (biu_pad_hwrite), // -m fifo- --> biu-
  .haddr_s1        (haddr_s1       ),
  .haddr_s2        (haddr_s2       ),
  .haddr_s0        (haddr_s0       ),
  .haddr_s3        (haddr_s3       ),
  .hburst_s1       (hburst_s1      ),
  .hburst_s0       (hburst_s0      ),
  .hburst_s3       (hburst_s3      ),
  .hmastlock       (hmastlock      ),
  .hprot_s1        (hprot_s1       ),
  .hprot_s0        (hprot_s0       ),
  .hprot_s3        (hprot_s3       ),
  .hrdata_s1       (hrdata_s1      ),
  .hrdata_s2       (hrdata_s2      ),
  .hrdata_s0       (hrdata_s0      ),
  .hrdata_s3       (hrdata_s3      ),
  .hready_s1       (hready_s1      ),
  .hready_s2       (hready_s2      ),
  .hready_s0       (hready_s0      ),
  .hready_s3       (hready_s3      ),
  .hresp_s1        (hresp_s1       ),
  .hresp_s2        (hresp_s2       ),
  .hresp_s0        (hresp_s0       ),
  .hresp_s3        (hresp_s3       ),
  .hsel_s1         (hsel_s1        ),
  .hsel_s2         (hsel_s2        ),
  .hsel_s0         (hsel_s0        ),
  .hsel_s3         (hsel_s3        ),
  .hsize_s1        (hsize_s1       ),
  .hsize_s0        (hsize_s0       ),
  .hsize_s3        (hsize_s3       ),
  .htrans_s1       (htrans_s1      ),
  .htrans_s0       (htrans_s0      ),
  .htrans_s3       (htrans_s3      ),
  .hwdata_s1       (hwdata_s1      ),
  .hwdata_s2       (hwdata_s2      ),
  .hwdata_s0       (hwdata_s0      ),
  .hwdata_s3       (hwdata_s3      ),
  .hwrite_s1       (hwrite_s1      ),
  .hwrite_s2       (hwrite_s2      ),
  .hwrite_s0       (hwrite_s0      ),
  .hwrite_s3       (hwrite_s3      ),
  .pad_biu_hrdata  (pad_biu_hrdata ),
  .pad_biu_hready  (pad_biu_hready ),
  .pad_biu_hresp   (pad_biu_hresp  ),
  .pad_cpu_rst_b   (pg_reset_b     ),
  .pll_core_cpuclk (sys_clk        ),
  .smpu_deny       (smpu_deny      )
);

//*********************** ahb slave 0 defalut slave ****************************
err_gen  x_err_gen (
  .haddr           (haddr_s0       ),
  .hburst          (hburst_s0      ),
  .hprot           (hprot_s0       ), 
  .hrdata          (hrdata_s0      ),
  .hready          (hready_s0      ),
  .hresp           (hresp_s0       ),
  .hsel            (hsel_s0        ),
  .hsize           (hsize_s0       ),
  .htrans          (htrans_s0      ),
  .hwdata          (hwdata_s0      ),
  .hwrite          (hwrite_s0      ),
  .pad_cpu_rst_b   (pg_reset_b     ),
  .pll_core_cpuclk (sys_clk        )
);



//*********************** ahb slave 1 smem ****************************
mem_ctrl  x_smem_ctrl (
  .haddr_s1        (haddr_s1       ),
  .hburst_s1       (hburst_s1      ),
  .hprot_s1        (hprot_s1       ),
  .hrdata_s1       (hrdata_s1      ),
  .hready_s1       (hready_s1      ),
  .hresp_s1        (hresp_s1       ),
  .hsel_s1         (hsel_s1        ),
  .hsize_s1        (hsize_s1       ),
  .htrans_s1       (htrans_s1      ),
  .hwdata_s1       (hwdata_s1      ),
  .hwrite_s1       (hwrite_s1      ),
  .pad_cpu_rst_b   (pad_cpu_rst_b  ),
  .pll_core_cpuclk (sys_clk        )
);

//*********************** ahb slave 2 apb ****************************
apb  x_apb (
  .b_pad_gpio_porta       (b_pad_gpio_porta      ),
  .biu_pad_lpmd_b         (biu_pad_lpmd_b        ),
  // .clk_en                 (clk_en                ),
  .corec_pmu_sleep_out    (corec_pmu_sleep_out   ), // apb停止
  .cpu_clk                (cpu_clk               ),
  .fifo_pad_haddr         (fifo_pad_haddr        ),
  .fifo_pad_hprot         (fifo_pad_hprot        ),
  .haddr_s2               (haddr_s2              ),
  .hrdata_s2              (hrdata_s2             ),
  .hready_s2              (hready_s2             ),
  .hresp_s2               (hresp_s2              ),
  .hsel_s2                (hsel_s2               ),
  .hwdata_s2              (hwdata_s2             ),
  .hwrite_s2              (hwrite_s2             ),
  .i_pad_cpu_jtg_rst_b    (i_pad_cpu_jtg_rst_b   ),
  .i_pad_jtg_tclk         (i_pad_jtg_tclk        ),
  .nmi_req                (nmi_req               ),
  .pad_clk                (clk27m                ), // !!!
  .pad_cpu_rst_b          (pad_cpu_rst_b         ),
  .pad_had_jtg_tap_en     (1'b1                  ),
  .pad_had_jtg_tms_i      (pad_had_jtg_tms_i     ),
  .pad_had_jtg_trst_b     (pad_had_jtg_trst_b    ),
  .pad_had_jtg_trst_b_pre (pad_had_jtg_trst_b_pre),
  .pad_vic_int_vld        (pad_vic_int_vld       ),
  .per_clk                (per_clk               ), // !!!
  .pg_reset_b             (pg_reset_b            ),
  .pmu_corec_isolation    (pmu_corec_isolation   ),
  .pmu_corec_sleep_in     (pmu_corec_sleep_in    ),
  .smpu_deny              (smpu_deny             ),
  .sys_rst                (sys_rst               ),
  .uart0_sin              (i_pad_uart0_sin       ),
  .uart0_sout             (o_pad_uart0_sout      ),
  .wakeup_req             (wakeup_req            )
);



//***********************Instance ahb slave 3 dmem ****************************
mem_ctrl  x_dmem_ctrl (
  .haddr_s1        (haddr_s4       ),
  .hburst_s1       (hburst_s4      ),
  .hprot_s1        (hprot_s4       ),
  .hrdata_s1       (hrdata_s4      ),
  .hready_s1       (hready_s4      ),
  .hresp_s1        (hresp_s4       ),
  .hsel_s1         (hsel_s4        ),
  .hsize_s1        (hsize_s4       ),
  .htrans_s1       (htrans_s4      ),
  .hwdata_s1       (hwdata_s4      ),
  .hwrite_s1       (hwrite_s4      ),
  .pad_cpu_rst_b   (pad_cpu_rst_b  ),
  .pll_core_cpuclk (sys_clk        )
);

endmodule


