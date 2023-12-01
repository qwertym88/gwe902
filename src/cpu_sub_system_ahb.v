/*Copyright 2018-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
module cpu_sub_system_ahb(
  biu_pad_haddr,
  biu_pad_hburst,
  biu_pad_hprot,
  biu_pad_hsize,
  biu_pad_htrans,
  biu_pad_hwdata,
  biu_pad_hwrite,
//   biu_pad_lpmd_b,
  clk_en,
//   corec_pmu_sleep_out,
  cpu_clk,
  i_pad_jtg_tms, // inout
  nmi_req,
  pad_biu_bigend_b,
  pad_biu_hrdata,
  pad_biu_hready,
  pad_biu_hresp,
  pad_cpu_rst_b,
  pad_had_rst_b,
  pad_had_jtg_tclk,
  pad_had_jtg_tms_i, // output
  pad_had_jtg_trst_b,
  pad_vic_int_vld,
//   pad_yy_gate_clk_en_b,
//   pad_yy_test_mode,
//   pg_reset_b,
//   pmu_corec_isolation,
//   pmu_corec_sleep_in,
  sys_resetn, // 系统复位信号
  sys_softrst_req // output
//   wakeup_req
);

// &Ports; @23
input           clk_en;              
input           cpu_clk;             
input           nmi_req;             
input           pad_biu_bigend_b;    
input   [31:0]  pad_biu_hrdata;      
input           pad_biu_hready;      
input   [1 :0]  pad_biu_hresp; // HRESP[1:0]表示 OKEY, ERROR, RETRY, SPLIT
input           pad_cpu_rst_b;       
input           pad_had_jtg_tclk;    
input           pad_had_jtg_trst_b;  // jtag测试复位
input   [31:0]  pad_vic_int_vld;     
// input           pad_yy_gate_clk_en_b; 
// input           pad_yy_test_mode;    
// input           pg_reset_b;          
// input           pmu_corec_isolation; 
// input           pmu_corec_sleep_in;  
input           wakeup_req;          
output  [31:0]  biu_pad_haddr;       
output  [2 :0]  biu_pad_hburst;      
output  [3 :0]  biu_pad_hprot;       
output  [2 :0]  biu_pad_hsize;       
output  [1 :0]  biu_pad_htrans;      
output  [31:0]  biu_pad_hwdata;      
output          biu_pad_hwrite;      
// output  [1 :0]  biu_pad_lpmd_b;      
// output          corec_pmu_sleep_out; 
output          pad_had_jtg_tms_i;   
output          sys_softrst_req;             
inout           i_pad_jtg_tms;       

// &Regs; @24
reg     [63:0]  pad_cpu_sys_cnt;     

// &Wires; @25
wire    [31:0]  biu_pad_haddr;       
wire    [2 :0]  biu_pad_hburst;      
wire    [3 :0]  biu_pad_hprot;       
wire    [2 :0]  biu_pad_hsize;       
wire    [1 :0]  biu_pad_htrans;      
wire    [31:0]  biu_pad_hwdata;      
wire            biu_pad_hwrite;      
// wire    [1 :0]  biu_pad_lpmd_b;      
wire            biu_pad_retire;      
wire    [31:0]  biu_pad_retire_pc;   
wire    [31:0]  biu_pad_wb_gpr_data; 
wire            biu_pad_wb_gpr_en;   
wire    [4 :0]  biu_pad_wb_gpr_index; 
wire    [31:0]  cp0_pad_mcause;      
wire    [31:0]  cp0_pad_mintstatus;  
wire    [31:0]  cp0_pad_mstatus;     
wire            cpu_clk;             
wire            cpu_pad_dfs_ack;     
wire            cpu_pad_lockup;      
wire    [1 :0]  cpu_pad_soft_rst;    
wire            cpu_rst;             
wire    [1 :0]  had_pad_jdb_pm;      
wire            had_pad_jtg_tms_o;   
wire            had_pad_jtg_tms_oe;  
wire            had_rst;             
// wire            i_pad_jtg_tms;       
wire    [31:0]  iahbl_pad_haddr;     
wire    [2 :0]  iahbl_pad_hburst;    
wire    [3 :0]  iahbl_pad_hprot;     
wire    [2 :0]  iahbl_pad_hsize;     
wire    [1 :0]  iahbl_pad_htrans;    
wire    [31:0]  iahbl_pad_hwdata;    
wire            iahbl_pad_hwrite;    
wire            iu_pad_inst_split;   
wire            nmi_req;             
wire            pad_biu_bigend_b;    
wire    [31:0]  pad_biu_hrdata;      
wire            pad_biu_hready;      
wire    [1 :0]  pad_biu_hresp;       
// wire            pad_biu_hresp_0;     
wire    [64 - 1 :0]  pad_clic_int_vld;    
wire            pad_cpu_ext_int_b;   
wire            pad_cpu_rst_b;       
wire            pad_had_jtg_tclk;    
wire            pad_had_jtg_tms_i;   
wire            pad_had_jtg_trst_b;  
wire    [31:0]  pad_iahbl_hrdata;    
wire            pad_iahbl_hready;    
wire    [1 :0]  pad_iahbl_hresp;     
wire    [31:0]  pad_vic_int_vld;     
// wire            pad_yy_gate_clk_en_b; 
// wire            pad_yy_test_mode;    
// wire            pg_reset_b;          
wire            sys_softrst_req;             
wire            wakeup_req;          


// 中断控制器中断源请求信号
assign pad_clic_int_vld[ 31 : 0] = pad_vic_int_vld[ 31 : 0];
assign pad_clic_int_vld[64 - 1 : 32] = 'h0;
// CPU 中断请求信号：低电平时表示外部中断控制器发起中断申请。
assign pad_cpu_ext_int_b  =1'b1;

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
  .pad_bmu_iahbl_mask   (12'he00             ),
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

// reg [1:0] cpu_rst_reg;
// always @(posedge cpu_clk or negedge sys_resetn) begin
//   if (~sys_resetn) begin
//     cpu_rst_reg <= 2'b00;
//   end else begin
//     cpu_rst_reg[0] <= ~cpu_pad_soft_rst[0];
//     cpu_rst_reg[1] <= cpu_rst_reg[0] & ~cpu_pad_soft_rst[0];
//   end
// end
// assign cpu_rst = cpu_rst_reg[1]; // 内核复位两个周期后再复位内核，此时已是同步的，应该不需要再像集成手册里用两个ddf做同步

// // assign had_rst = sys_resetn; // 系统复位
// assign sys_softrst_req = ~cpu_pad_soft_rst[1]; // 系统复位请求


always@(posedge cpu_clk or negedge pg_reset_b)
begin
  if(!pg_reset_b)
    pad_cpu_sys_cnt[63:0] <= 64'h0;
  else
    pad_cpu_sys_cnt[63:0] <= pad_cpu_sys_cnt[63:0] + 64'h1;
end

assign i_pad_jtg_tms = had_pad_jtg_tms_oe ? had_pad_jtg_tms_o : 1'bz;
assign pad_had_jtg_tms_i = i_pad_jtg_tms;



// IAHB Lite Memory
// &Instance("iahb_mem_ctrl", "x_iahb_mem_ctrl"); @431
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

endmodule


 