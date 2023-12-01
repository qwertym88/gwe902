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
module mem_ctrl(
  haddr_s1,
  hburst_s1,
  hprot_s1,
  hrdata_s1,
  hready_s1,
  hresp_s1,
  hsel_s1,
  hsize_s1,
  htrans_s1,
  hwdata_s1,
  hwrite_s1,
  pad_cpu_rst_b,
  pll_core_cpuclk
);

// &Ports; @25
input   [31:0]  haddr_s1;             
input   [2 :0]  hburst_s1;            
input   [3 :0]  hprot_s1;             
input           hsel_s1;              
input   [2 :0]  hsize_s1;             
input   [1 :0]  htrans_s1;            
input   [31:0]  hwdata_s1;            
input           hwrite_s1;            
input           pad_cpu_rst_b;        
input           pll_core_cpuclk;      
output  [31:0]  hrdata_s1;            
output          hready_s1;            
output  [1 :0]  hresp_s1;             

// &Wires; @26
wire            ahb_trans_clear;      
wire            ahb_trans_valid;      
wire            bypass_if_write_byte; 
wire            bypass_if_write_hword; 
wire            bypass_if_write_word; 
wire    [31:0]  haddr;                
wire    [31:0]  haddr_s1;             
wire            hclk;                 
wire    [31:0]  hrdata;               
wire    [31:0]  hrdata_pre;           
wire    [31:0]  hrdata_s1;            
wire            hready_s1;            
wire    [1 :0]  hresp_s1;             
wire            hrst_b;               
wire            hsel;                 
wire            hsel_s1;              
wire    [2 :0]  hsize;                
wire    [2 :0]  hsize_s1;             
wire    [1 :0]  htrans;               
wire    [1 :0]  htrans_s1;            
wire    [31:0]  hwdata;               
wire    [31:0]  hwdata_s1;            
wire            hwrite;               
wire            hwrite_s1;            
wire            pad_cpu_rst_b;        
wire            pll_core_cpuclk;      
wire    [15:0]  ram0_addr;            
wire    [7 :0]  ram0_din;             
wire    [7 :0]  ram0_dout;            
wire    [15:0]  ram1_addr;            
wire    [7 :0]  ram1_din;             
wire    [7 :0]  ram1_dout;            
wire    [15:0]  ram2_addr;            
wire    [7 :0]  ram2_din;             
wire    [7 :0]  ram2_dout;            
wire    [15:0]  ram3_addr;            
wire    [7 :0]  ram3_din;             
wire    [7 :0]  ram3_dout;            
wire    [31:0]  ram_addr;             
wire            ram_clk;              
wire    [3 :0]  ram_wen_byte;         
wire    [3 :0]  ram_wen_hword;        
wire    [3 :0]  ram_wen_word;         
wire            raw_bypass_en;        
wire            raw_en;               
wire            raw_no_bypass;        
wire            rdata_vld;            
wire            read_en;              
wire            write_en;             

// &Regs; @27
reg     [31:0]  haddr_ff;             
reg     [31:0]  hrdata_raw;           
reg             hread_ff;             
reg             hready;               
reg     [1 :0]  hresp;                
reg     [2 :0]  hsize_ff;             
reg             hwrite_ff;            
reg     [3 :0]  ram_wen;              
reg     [3 :0]  ram_wen_pre;          
reg             raw_data_vld;         

parameter MEM_ADDR_WIDTH = 18;

assign hclk             = pll_core_cpuclk;
assign hrst_b           = pad_cpu_rst_b;
assign hsel             = hsel_s1;
assign htrans[1:0]      = htrans_s1[1:0];
assign hsize[2:0]       = hsize_s1[2:0]; // 000 byte 001 hw 010 word
assign haddr[31:0]      = haddr_s1[31:0];
assign hwrite           = hwrite_s1;
assign hresp_s1[1:0]    = hresp[1:0];
assign hready_s1        = hready;
assign hwdata[31:0]     = hwdata_s1[31:0];
assign hrdata_s1[31:0]  = hrdata[31:0];

assign ahb_trans_valid = hsel && hready &&
                         ((htrans[1:0] == 2'b10) || (htrans[1:0] == 2'b11));

assign ahb_trans_clear = hready && !hsel;

/* 
以下冗长的代码实现了“如果前一周期写和该周期读的是同样的位置，则直接返回hwdata”
这个功能真的有用吗？
*/
always @(posedge hclk or negedge hrst_b) // 有毛用啊，不明所以
begin
  if (!hrst_b)
  begin
    hwrite_ff      <= 1'b0;
    hread_ff       <= 1'b0;
    hsize_ff[2:0]  <= 3'd0;
    haddr_ff[31:0] <= 32'd0;
    raw_data_vld   <= 1'b0;
  end
  else if (ahb_trans_valid)
  begin
    hwrite_ff      <= hwrite;
    hread_ff       <= !hwrite;
    hsize_ff[2:0]  <= hsize[2:0];
    haddr_ff[31:0] <= haddr[31:0];
    raw_data_vld   <= raw_bypass_en;
  end
  else if (ahb_trans_clear)
  begin
    hwrite_ff      <= 1'b0;
    hread_ff       <= 1'b0;
    hsize_ff[2:0]  <= 3'd0;
    haddr_ff[31:0] <= 32'd0;
    raw_data_vld   <= 1'b0;
  end
end

assign write_en  = hwrite_ff; // if(ahb_trans_valid) hwrite_ff <= hwrite;
assign read_en   = ahb_trans_valid && !hwrite; // =!write_en，异步信号
assign rdata_vld = hread_ff; // =!write_en，你敢信这个才是和write_en相反的信号，而不是上面的？就不能对调一下命名吗？
assign raw_en    = write_en && read_en; // ahb_trans_valid==1 hwrite=1->0 的那一个时钟周期内=1，异步置1同步归0

// 如果不“通过”，则表示地址不同，则ahb_trans_valid为假。那为啥不直接判断ahb_trans_valid？不纯粹多余？
assign bypass_if_write_word = (haddr_ff[MEM_ADDR_WIDTH-1:2] == haddr[MEM_ADDR_WIDTH-1:2]) &&
                              (hsize_ff[1:0] == 2'b10);
assign bypass_if_write_hword = (haddr_ff[MEM_ADDR_WIDTH-1:1] == haddr[MEM_ADDR_WIDTH-1:1]) &&
                               (hsize_ff[1:0] == 2'b01) && (!hsize[1]);
assign bypass_if_write_byte = (haddr_ff[MEM_ADDR_WIDTH-1:0] == haddr[MEM_ADDR_WIDTH-1:0]) &&
                              (hsize[1:0] == 2'b00);

// ahb_trans_valid==1 hwrite=1->0时=1 此时 haddr_ff 表示旧写入的地址 haddr 表示新读入的地址，如果相同说明写的就是上次读的地方。所以还判断三种情况不纯粹多余吗?
assign raw_bypass_en = raw_en && (bypass_if_write_word ||
                                  bypass_if_write_hword ||
                                  bypass_if_write_byte);
// 从ram里读数据，写立刻读则为0
assign hrdata_pre[31:0] = rdata_vld ? {ram3_dout[7:0], ram2_dout[7:0], ram1_dout[7:0], ram0_dout[7:0]} : 32'b0;

always @(posedge hclk or negedge hrst_b)
begin
  if (!hrst_b)
    hrdata_raw[31:0] <= 32'd0;
  else if (raw_bypass_en)
    hrdata_raw[31:0] <= hwdata[31:0];
  else
    hrdata_raw[31:0] <= hrdata_raw[31:0];
end

// if(ahb_trans_valid) raw_data_vld <= raw_bypass_en; 为啥还要再弄一个符号，直接用raw_bypass_en判断不就行了吗？或者说是要和时钟同步？
assign hrdata[31:0] = raw_data_vld ? hrdata_raw[31:0] : hrdata_pre[31:0];

// =============================================
// AHB bus response
// =============================================
always @(posedge hclk or negedge hrst_b)
begin
  if (!hrst_b)
    hresp[1:0] <= 2'b00;
  else
    hresp[1:0] <= 2'b00;
end

// ahb_trans_valid=1->0 的那一个时钟周期内=1
assign raw_no_bypass = raw_en && (!raw_bypass_en);

always @(posedge hclk or negedge hrst_b)
begin
  if (!hrst_b)
    hready <= 1'b0;
  else if (raw_no_bypass)
    hready <= 1'b0;
  else
    hready <= 1'b1;
end

assign ram_addr[31:0] = (write_en || !hready) ? haddr_ff[31:0] : haddr[31:0];
// =============================================
// data input and output distribution and reform
// =============================================
assign ram_clk = hclk;
assign ram0_addr[MEM_ADDR_WIDTH-3:0]  = ram_addr[MEM_ADDR_WIDTH-1:2];
assign ram1_addr[MEM_ADDR_WIDTH-3:0]  = ram_addr[MEM_ADDR_WIDTH-1:2];
assign ram2_addr[MEM_ADDR_WIDTH-3:0]  = ram_addr[MEM_ADDR_WIDTH-1:2];
assign ram3_addr[MEM_ADDR_WIDTH-3:0]  = ram_addr[MEM_ADDR_WIDTH-1:2];
assign ram_wen_byte[0] = (haddr[1:0] == 2'h0);
assign ram_wen_byte[1] = (haddr[1:0] == 2'h1);
assign ram_wen_byte[2] = (haddr[1:0] == 2'h2);
assign ram_wen_byte[3] = (haddr[1:0] == 2'h3);
assign ram_wen_hword[0] = (haddr[1] == 1'd0);
assign ram_wen_hword[1] = (haddr[1] == 1'd0);
assign ram_wen_hword[2] = (haddr[1] == 1'd1);
assign ram_wen_hword[3] = (haddr[1] == 1'd1);
assign ram_wen_word[3:0] = 4'hf;

always @( * )
begin
  case (hsize[2:0])
    3'b000: // byte
      ram_wen_pre[3:0] = ram_wen_byte[3:0];
    3'b001: // half-word
      ram_wen_pre[3:0] = ram_wen_hword[3:0];
    3'b010: // word
      ram_wen_pre[3:0] = ram_wen_word[3:0];
    default:
      ram_wen_pre[3:0] = 4'b0;
  endcase
end

always @(posedge hclk or negedge hrst_b)
begin
  if (!hrst_b)
    ram_wen[3:0] <= 4'b0;
  else if (ahb_trans_valid && hwrite)
    ram_wen[3:0] <= ram_wen_pre[3:0];
  else
    ram_wen[3:0] <= 4'b0;
end

assign ram0_din[7:0]  = hwdata[7:0];
assign ram1_din[7:0]  = hwdata[15:8];
assign ram2_din[7:0]  = hwdata[23:16];
assign ram3_din[7:0]  = hwdata[31:24];


// memory unit is in DPTHx8 size, 4 units are instanced
soc_fpga_ram #(8, MEM_ADDR_WIDTH-2) ram0(
  .PortAClk (ram_clk),
  .PortAAddr(ram0_addr),
  .PortADataIn (ram0_din),
  .PortAWriteEnable(ram_wen[0]),
  .PortADataOut(ram0_dout));

soc_fpga_ram #(8, MEM_ADDR_WIDTH-2) ram1(
  .PortAClk (ram_clk),
  .PortAAddr(ram1_addr),
  .PortADataIn (ram1_din),
  .PortAWriteEnable(ram_wen[1]),
  .PortADataOut(ram1_dout));

soc_fpga_ram #(8, MEM_ADDR_WIDTH-2) ram2(
  .PortAClk (ram_clk),
  .PortAAddr(ram2_addr),
  .PortADataIn (ram2_din),
  .PortAWriteEnable(ram_wen[2]),
  .PortADataOut(ram2_dout));

soc_fpga_ram #(8, MEM_ADDR_WIDTH-2) ram3(
  .PortAClk (ram_clk),
  .PortAAddr(ram3_addr),
  .PortADataIn (ram3_din),
  .PortAWriteEnable(ram_wen[3]),
  .PortADataOut(ram3_dout));

// &ModuleEnd; @227
endmodule



