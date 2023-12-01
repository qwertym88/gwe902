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

//SYS MEM
`define S1_BASE_START 32'h60000000
`define S1_BASE_END   32'h600fffff
//APB
`define S2_BASE_START 32'h40000000
`define S2_BASE_END   32'h4fffffff
// //IMEM
// `define S3_BASE_START 32'h00000000
// `define S3_BASE_END   32'h0007ffff
//DMEM
`define S5_BASE_START 32'h20000000
`define S5_BASE_END   32'h207fffff

// &Depend("environment.h"); @35
// &ModuleBeg; @36
module ahb(
  input  wire [31:0]  biu_pad_haddr, // 
  input  wire [31:0]  biu_pad_hwdata, 
  input  wire [2 :0]  biu_pad_hburst, 
  input  wire [3 :0]  biu_pad_hprot,  
  input  wire [2 :0]  biu_pad_hsize,  
  input  wire [1 :0]  biu_pad_htrans, 
  input  wire         biu_pad_hwrite, 
  output reg  [31:0]  pad_biu_hrdata, //
  output reg          pad_biu_hready, 
  output reg  [1 :0]  pad_biu_hresp, 
  output wire         hsel_s1, // slave 1 smem
  output wire [31:0]  haddr_s1, 
  output wire [31:0]  hwdata_s1,  
  output wire [2 :0]  hburst_s1,  
  output wire [3 :0]  hprot_s1, 
  output wire [2 :0]  hsize_s1,
  output wire [1 :0]  htrans_s1,  
  input  wire [31:0]  hrdata_s1,    
  input  wire         hready_s1, 
  input  wire [1 :0]  hresp_s1, 
  output wire         hsel_s2, // slave 2 apb
  output wire [31:0]  haddr_s2, 
  output wire [31:0]  hwdata_s2,  
  output wire [2 :0]  hburst_s2,  
  output wire [3 :0]  hprot_s2, 
  output wire [2 :0]  hsize_s2,
  output wire [1 :0]  htrans_s2,  
  input  wire [31:0]  hrdata_s2,    
  input  wire         hready_s2, 
  input  wire [1 :0]  hresp_s2,  
  output wire         hsel_s3, // slave 3 dmem
  output wire [31:0]  haddr_s3, 
  output wire [31:0]  hwdata_s3,  
  output wire [2 :0]  hburst_s3,  
  output wire [3 :0]  hprot_s3, 
  output wire [2 :0]  hsize_s3,
  output wire [1 :0]  htrans_s3,  
  input  wire [31:0]  hrdata_s3,    
  input  wire         hready_s3, 
  input  wire [1 :0]  hresp_s3,
  output wire         hsel_s4, // slave 0 default-err_gen
  output wire [31:0]  haddr_s4, 
  output wire [31:0]  hwdata_s4,  
  output wire [2 :0]  hburst_s4,  
  output wire [3 :0]  hprot_s4, 
  output wire [2 :0]  hsize_s4,
  output wire [1 :0]  htrans_s4,  
  input  wire [31:0]  hrdata_s4,    
  input  wire         hready_s4, 
  input  wire [1 :0]  hresp_s4,
  input  wire         pad_cpu_rst_b,  
  input  wire         pll_core_cpuclk, 
  input  wire         smpu_deny,  // 有点用但又没用?       
  // output wire         hmastlock 
);

reg             busy_s4; 
reg             busy_s1;        
reg             busy_s2;               
reg             busy_s3;          

wire            arb_block;   

// Support AHB LITE
assign    hmastlock            =    1'b0; 

assign    haddr_s1[31:0]       =    biu_pad_haddr[31:0];  
assign    hburst_s1[2:0]       =    biu_pad_hburst[2:0]; 
assign    hprot_s1[3:0]        =    biu_pad_hprot[3:0];  
assign    hsize_s1[2:0]        =    biu_pad_hsize[2:0];  
assign    htrans_s1[1:0]       =    biu_pad_htrans[1:0]; 
assign    hwrite_s1            =    biu_pad_hwrite; 
assign    hwdata_s1[31:0]      =    biu_pad_hwdata[31:0]; 

assign    haddr_s2[31:0]       =    biu_pad_haddr[31:0];  
assign    hburst_s2[2:0]       =    biu_pad_hburst[2:0]; 
assign    hprot_s2[3:0]        =    biu_pad_hprot[3:0];  
assign    hsize_s2[2:0]        =    biu_pad_hsize[2:0];  
assign    htrans_s2[1:0]       =    biu_pad_htrans[1:0]; 
assign    hwrite_s2            =    biu_pad_hwrite; 
assign    hwdata_s2[31:0]      =    biu_pad_hwdata[31:0]; 

assign    haddr_s3[31:0]       =    biu_pad_haddr[31:0];  
assign    hburst_s3[2:0]       =    biu_pad_hburst[2:0]; 
assign    hprot_s3[3:0]        =    biu_pad_hprot[3:0];  
assign    hsize_s3[2:0]        =    biu_pad_hsize[2:0];  
assign    htrans_s3[1:0]       =    biu_pad_htrans[1:0]; 
assign    hwrite_s3            =    biu_pad_hwrite; 
assign    hwdata_s3[31:0]      =    biu_pad_hwdata[31:0]; 

assign    haddr_s4[31:0]       =    biu_pad_haddr[31:0];  
assign    hburst_s4[2:0]       =    biu_pad_hburst[2:0]; 
assign    hprot_s4[3:0]        =    biu_pad_hprot[3:0];  
assign    hsize_s4[2:0]        =    biu_pad_hsize[2:0];  
assign    htrans_s4[1:0]       =    biu_pad_htrans[1:0]; 
assign    hwrite_s4            =    biu_pad_hwrite; 
assign    hwdata_s4[31:0]      =    biu_pad_hwdata[31:0]; 

// ahb decoder
assign    hsel_s1 = (biu_pad_htrans[1]==1'b1) && (biu_pad_haddr >= `S1_BASE_START) && (biu_pad_haddr <= `S1_BASE_END) 
                  && !arb_block && !smpu_deny;
assign    hsel_s2 = (biu_pad_htrans[1]==1'b1) && (biu_pad_haddr >= `S2_BASE_START) && (biu_pad_haddr <= `S2_BASE_END) 
                  && !arb_block && !smpu_deny;
assign    hsel_s3 = (biu_pad_htrans[1]==1'b1) && (biu_pad_haddr >= `S5_BASE_START) && (biu_pad_haddr <= `S5_BASE_END) 
                  && !arb_block && !smpu_deny;

assign    hsel_s4 = (biu_pad_htrans[1]==1'b1) && (!hsel_s1 && !hsel_s2 && !hsel_s3 || smpu_deny) && !arb_block; // addr not match

assign    pre_busy_s1 = hsel_s1 || busy_s1 && !hready_s1;
assign    pre_busy_s2 = hsel_s2 || busy_s2 && !hready_s2;
assign    pre_busy_s3 = hsel_s3 || busy_s3 && !hready_s3;
assign    pre_busy_s4 = hsel_s4 || busy_s4 && !hready_s4;

always @(posedge pll_core_cpuclk or negedge pad_cpu_rst_b)
begin
  if(!pad_cpu_rst_b)begin
  busy_s1 <= 1'b0;
  busy_s2 <= 1'b0;
  busy_s3 <= 1'b0;
  busy_s4 <= 1'b0;
  end
  else begin
  busy_s1 <= pre_busy_s1;
  busy_s2 <= pre_busy_s2;
  busy_s3 <= pre_busy_s3;
  busy_s4 <= pre_busy_s4;
  end
end

assign arb_block = busy_s1 && !hready_s1 ||
                   busy_s2 && !hready_s2 ||
                   busy_s3 && !hready_s3 ||
                   busy_s4 && !hready_s4;

//ahb slave multiplexer
// &CombBeg; @182
always @(  hrdata_s1[31:0]
    or hresp_s1[1:0]
    or hready_s1
    or busy_s1
    or hrdata_s2[31:0]
    or hresp_s2[1:0]
    or hready_s2
    or busy_s2
    or hrdata_s3[31:0]
    or hresp_s3[1:0]
    or hready_s3
    or busy_s3 
    or hrdata_s4[31:0]
    or hresp_s4[1:0]
    or hready_s4
    or busy_s4
)
begin
  case({busy_s1,busy_s2,busy_s3,busy_s4})
    4'b1000:
    begin
      pad_biu_hrdata[31:0] = hrdata_s1[31:0];
      pad_biu_hready       = hready_s1;
      pad_biu_hresp[1:0]   = hresp_s1[1:0];
    end
    4'b0100:
    begin
      pad_biu_hrdata[31:0] = hrdata_s2[31:0];
      pad_biu_hready       = hready_s2;
      pad_biu_hresp[1:0]   = hresp_s2[1:0];
    end
    4'b0010:
    begin 
      pad_biu_hrdata[31:0] = hrdata_s3[31:0];
      pad_biu_hready       = hready_s3;
      pad_biu_hresp[1:0]   = hresp_s3[1:0];
    end
    4'b0001:
    begin 
      pad_biu_hrdata[31:0] = hrdata_s4[31:0];
      pad_biu_hready       = hready_s4;
      pad_biu_hresp[1:0]   = hresp_s4[1:0];
    end
    default:
    begin
      pad_biu_hrdata[31:0] = 32'b0;
      pad_biu_hready       = 1'b1;
      pad_biu_hresp[1:0]   = 2'b0;
    end
  endcase
end
endmodule


