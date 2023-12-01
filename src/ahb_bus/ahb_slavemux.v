module ahb_slavemux (
input wire HCLK, // Clock
input wire HRESETn, // Reset
input wire HREADY, // Bus system level HREADY
input wire HSEL0, // HSEL for AHB Slave #0
input wire HREADYOUT0, // HREADY for Slave connection #0
input wire HRESP0, // HRESP for slave connection #0
input wire [31:0] HRDATA0, // HRDATA for slave connection #0
input wire HEXOKAY0, // HEXOKAY for slave connection#0
input wire HSEL1, // HSEL for AHB Slave #1
input wire HREADYOUT1, // HREADY for Slave connection #1
input wire HRESP1, // HRESP for slave connection #1
input wire [31:0] HRDATA1, // HRDATA for slave connection #1
input wire HEXOKAY1, // HEXOKAY for slave connection#1
input wire HSEL2, // HSEL for AHB Slave #2
input wire HREADYOUT2, // HREADY for Slave connection #2
input wire HRESP2, // HRESP for slave connection #2
input wire [31:0] HRDATA2, // HRDATA for slave connection #2
input wire HEXOKAY2, // HEXOKAY for slave connection#2
input wire HSEL3, // HSEL for AHB Slave #3
input wire HREADYOUT3, // HREADY for Slave connection #3
input wire HRESP3, // HRESP for slave connection #3
input wire [31:0] HRDATA3, // HRDATA for slave connection #3
input wire HEXOKAY3, // HEXOKAY for slave connection#3
output wire HREADYOUT, // HREADY output to AHB master and AHB slaves
output wire HRESP, // HRESP to AHB master
output wire [31:0] HRDATA, // Read data to AHB master
output wire HEXOKAY // Exclusive okay
);
// Internal signals
reg [3:0] SampledHselReg;
// Registering select
always @(posedge HCLK or negedge HRESETn)
begin
if (~HRESETn)
   SampledHselReg <= {4{1'b0}};
else if (HREADY) // advance pipeline if multiplexed HREADY is 1
   SampledHselReg <= {HSEL3, HSEL2, HSEL1, HSEL0};
end
assign HREADYOUT = 
    (SampledHselReg[0] & HREADYOUT0)|
    (SampledHselReg[1] & HREADYOUT1)|
    (SampledHselReg[2] & HREADYOUT2)|
    (SampledHselReg[3] & HREADYOUT3)|
    (SampledHselReg ==4'b0000);
assign HRDATA = 
    ({32{SampledHselReg[0]}} & HRDATA0)|
    ({32{SampledHselReg[1]}} & HRDATA1)|
    ({32{SampledHselReg[2]}} & HRDATA2)|
    ({32{SampledHselReg[3]}} & HRDATA3);
assign HRESP =
    (SampledHselReg[0] & HRESP0)|
    (SampledHselReg[1] & HRESP1)|
    (SampledHselReg[2] & HRESP2)|
    (SampledHselReg[3] & HRESP3);

assign HEXOKAY = 
    (SampledHselReg[0] & HEXOKAY0)|
    (SampledHselReg[1] & HEXOKAY1)|
    (SampledHselReg[2] & HEXOKAY2)|
    (SampledHselReg[3] & HEXOKAY3);
endmodule