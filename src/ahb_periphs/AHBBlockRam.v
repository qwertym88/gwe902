module AHBBlockRam #(
        // --------------------------------------
        // Parameter Declarations
        // --------------------------------------
        parameter AWIDTH = 12
    )
    (
        // --------------------------------------
        // Port Definitions
        // --------------------------------------
        input HCLK, // system bus clock
        input HRESETn, // system bus reset
        input HSEL, // AHB peripheral select
        input HREADY, // AHB ready input
        input [1:0] HTRANS, // AHB transfer type
        input [1:0] HSIZE, // AHB hsize
        input HWRITE, // AHB hwrite
        input [AWIDTH-1:0] HADDR, // AHB address bus
        input [31:0] HWDATA, // AHB write data bus
        output HREADYOUT, // AHB ready output to S->M mux
        output HRESP, // AHB response
        output [31:0] HRDATA // AHB read data bus
    );
    localparam AWT = ((1<<(AWIDTH-2))-1); // index max value
    // --- Memory Array ---
    reg [7:0] BRAM0 [0:AWT];
    reg [7:0] BRAM1 [0:AWT];
    reg [7:0] BRAM2 [0:AWT];
    reg [7:0] BRAM3 [0:AWT];
    // --- Internal signals ---
    reg [AWIDTH-2-1:0] haddrQ;
    wire Valid;
    reg [3:0] WrEnQ;
    wire [3:0] WrEnD;
    wire WrEn;
    // --------------------------------------
    // Main body of code
    // --------------------------------------
    assign Valid = HSEL & HREADY & HTRANS[1];
    // --- RAM Write Interface ---
    assign WrEn = (Valid & HWRITE) | (|WrEnQ);
    assign WrEnD[0] = (((HADDR[1:0]==2'b00) && (HSIZE[1:0]==2'b00)) ||
                       ((HADDR[1]==1'b0) && (HSIZE[1:0]==2'b01)) ||
                       ((HSIZE[1:0]==2'b10))) ? Valid & HWRITE : 1'b0;
    assign WrEnD[1] = (((HADDR[1:0]==2'b01) && (HSIZE[1:0]==2'b00)) ||
                       ((HADDR[1]==1'b0) && (HSIZE[1:0]==2'b01)) ||
                       ((HSIZE[1:0]==2'b10))) ? Valid & HWRITE : 1'b0;
    assign WrEnD[2] = (((HADDR[1:0]==2'b10) && (HSIZE[1:0]==2'b00)) ||
                       ((HADDR[1]==1'b1) && (HSIZE[1:0]==2'b01)) ||
                       ((HSIZE[1:0]==2'b10))) ? Valid & HWRITE : 1'b0;
    assign WrEnD[3] = (((HADDR[1:0]==2'b11) && (HSIZE[1:0]==2'b00)) ||
                       ((HADDR[1]==1'b1) && (HSIZE[1:0]==2'b01)) ||
                       ((HSIZE[1:0]==2'b10))) ? Valid & HWRITE : 1'b0;
    always @ (negedge HRESETn or posedge HCLK)
        if (~HRESETn)
            WrEnQ <= 4'b0000;
        else if (WrEn)
            WrEnQ <= WrEnD;
    // --- Infer RAM ---
    always @ (posedge HCLK)
    begin
        if (WrEnQ[0])
            BRAM0[haddrQ] <= HWDATA[7:0];
        if (WrEnQ[1])
            BRAM1[haddrQ] <= HWDATA[15:8];
        if (WrEnQ[2])
            BRAM2[haddrQ] <= HWDATA[23:16];
        if (WrEnQ[3])
            BRAM3[haddrQ] <= HWDATA[31:24];
        // do not use enable on read interface.
        haddrQ <= HADDR[AWIDTH-1:2];
    end
// `ifdef CM_SRAM_INIT
//     initial begin
//         $readmemh(“itcm3”, BRAM3);
//         $readmemh(“itcm2”, BRAM2);
//         $readmemh(“itcm1”, BRAM1);
//         $readmemh(“itcm0”, BRAM0);
//     end
// `endif
    // --- AHB Outputs ---
    assign HRESP = 1'b0; // OKAY
    assign HREADYOUT = 1'b1; // always ready
    assign HRDATA = {BRAM3[haddrQ],BRAM2[haddrQ],BRAM1[haddrQ],BRAM0[haddrQ]};
endmodule
