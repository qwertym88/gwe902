module ahb_decoder(
    input wire [31:1] HADDR,
    input wire EN,
    output wire HSEL0,
    output wire HSEL1
);


//SYS MEM
`define S0_BASE_START 32'h20000000
`define S0_BASE_END   32'h207fffff

// //APB
// `define S1_BASE_START 32'h40000000
// `define S1_BASE_END   32'h4fffffff


assign HSEL0 = (biu_pad_haddr >= `S0_BASE_START) && (biu_pad_haddr <= `S0_BASE_END);
// assign HSEL1 = (biu_pad_haddr >= `S1_BASE_START) && (biu_pad_haddr <= `S1_BASE_END);
assign HSEL1 = !HSEL0; // && !HSEL1;

endmodule