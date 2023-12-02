module ahb_decoder(
    input wire [31:0] HADDR,
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


assign HSEL0 = (HADDR >= `S0_BASE_START) && (HADDR <= `S0_BASE_END);
// assign HSEL1 = (HADDR >= `S1_BASE_START) && (HADDR <= `S1_BASE_END);
assign HSEL1 = !HSEL0; // && !HSEL1;

endmodule