module mcu_reset (
    input wire mcu_rst_signal,
    input wire [1:0] cpu_pad_soft_rst,
    input wire sys_clk,
    output wire pad_cpu_rst_b,
    output wire pad_had_rst_b,
    output wire pad_had_jtg_trst_b,
    output wire sys_resetn
);

wire mcu_rstn;
wire cpu_rst;
wire sys_rst;

// ensure external power-on-reset is synchronized to HCLK,
// Taken from page 28 of System-on-Chip Design with Arm Cortex-M processors
reg [1:0] mcu_rst_reg;
always @(posedge sys_clk or negedge mcu_rst_signal)
begin
 if (mcu_rst_signal == 1'b0) begin
    mcu_rst_reg <= 2'b0; //异步复位
 end    
 else begin
    mcu_rst_reg[0] <= 1'b1;
    mcu_rst_reg[1] <= mcu_rst_reg[0]; // 两个时钟周期后释放
 end    
end
assign mcu_rstn = mcu_rst_reg[1]; // 使上电复位上升沿与clk同步

// cpu_pad_soft_rst[0]发出内核复位请求，等待2周期执行
reg [1:0] cpu_rst_reg;
always @(posedge sys_clk or negedge mcu_rstn) begin
  if (~mcu_rstn) begin
    cpu_rst_reg <= 2'b00;
  end 
  else begin
    cpu_rst_reg[0] <= cpu_pad_soft_rst[0];
    cpu_rst_reg[1] <= cpu_rst_reg[0] & cpu_pad_soft_rst[0];
  end
end
assign cpu_rst = ~cpu_rst_reg[1]; // 即cpu_pad_soft_rst[0]=1两周期后，或上电复位信号mcu_rstn=0时处理器复位

// cpu_pad_soft_rst[1]发出系统复位请求，等待2周期执行
reg [1:0] sys_rst_reg;
always @(posedge sys_clk or negedge mcu_rstn) begin
  if (~mcu_rstn) begin
    sys_rst_reg <= 2'b00;
  end 
  else begin
    sys_rst_reg[0] <= cpu_pad_soft_rst[1];
    sys_rst_reg[1] <= sys_rst_reg[0] & cpu_pad_soft_rst[1];
  end
end
assign sys_rst = ~sys_rst_reg[1]; // 即cpu_pad_soft_rst[1]=1两周期后，或上电复位信号mcu_rstn=0时系统复位

// 见集成手册p19
assign pad_cpu_rst_b = cpu_rst & sys_rst;
assign pad_had_rst_b = sys_rst;
assign pad_had_jtg_trst_b = mcu_rstn;

assign sys_resetn = sys_rst;


// 另一种设计，和集成手册p19那张图一模一样的

// // pad_cpu_rst_b
// assign cpu_rst_req_pre = mcu_resetn & (~cpu_pad_soft_rst[0] || ~cpu_pad_soft_rst[1]);
// reg cpu_rst_req_reg[1:0]
// always@(posedge clk or negedge cpu_rst_req_pre)
// begin
//  if (cpu_rst_req_pre == 1'b0)
//  begin
//      cpu_rst_req_reg <= 2'b0; //异步复位
//  end    
//  else
//  begin
//      cpu_rst_req_reg[0] <= 1'b1;
//      cpu_rst_req_reg[1] <= cpu_rst_req_reg[0]; // 同步释放
//  end    
// end
// assign pad_cpu_rst_b = cpu_rst_req_reg[1];

// // pad_had_rst_b
// assign had_rst_req_pre = mcu_resetn & ~cpu_pad_soft_rst[1];
// reg had_rst_req_reg[1:0]
// always@(posedge clk or negedge had_rst_req_pre)
// begin
//  if (had_rst_req_pre == 1'b0)
//  begin
//      had_rst_req_reg <= 2'b0; //异步复位
//  end    
//  else
//  begin
//      had_rst_req_reg[0] <= 1'b1;
//      had_rst_req_reg[1] <= had_rst_req_reg[0]; // 同步释放
//  end    
// end
// assign pad_had_rst_b = had_rst_req_reg[1];

// // pad_had_jtg_trst_b
// assign pad_had_jtg_trst_b = poweron_resetn & mcu_resetn;

endmodule