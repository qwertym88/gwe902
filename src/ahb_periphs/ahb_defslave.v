module ahb_defslave (
 input wire HCLK, // Clock
 input wire HRESETn, // Reset
 input wire HSEL, // connect to HSEL_DefSlave from AHB decoder
 input wire [1:0] HTRANS, // Transfer command
 input wire HREADY, // System-wide HREADY
 output wire HREADYOUT, // Slave ready output
 output wire HRESP // Slave response output
 );
// Internal signals
wire TransReq; // Transfer Request
reg [1:0] RespState; // FSM for two cycle error response
wire [1:0] NextState; // next state for RespState
// Start of main code
assign TransReq = HSEL & HTRANS[1] & HREADY; // a transfer is issued
 // to default slave because address is invalid
// Generate next state for the FSM
// Encoding : 01 - Idle (bit 0 is HREADYOUT, bit 1 is RESP[0])
// 10 - 1st cycle of error response 
// 11 - 2nd cycle of error response
assign NextState = {(TransReq | (~RespState[0])),(~TransReq)};
// Registering FSM state
always @(posedge HCLK or negedge HRESETn)
begin
    if (~HRESETn)
        RespState <= 2'b01; // bit 0 is reset to 1, ensuring HREADYOUT is 1 
    else // at reset
        RespState <= NextState;
end
// Connect to output
assign HREADYOUT = RespState[0];
assign HRESP = RespState[1];
endmodule