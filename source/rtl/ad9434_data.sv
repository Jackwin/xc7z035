`timescale 1ns/1ps
module ad9434_data (
    input [5:0]     adc0_din_p,
    input [5:0]     adc0_din_n,
    input           adc0_or_p,
    input           adc0_or_n,
    input           adc0_dco_p,
    input           adc0_dco_n
);

logic           dco;
logic           dco_bufr;
logic [5:0]     data_bufds;
logic [5:0]     adc_data_q1;
logic [5:0]     adc_data_q2;

/*                _ _ _         _ _ _
                 /     \       /     \
//          ___ /       \_ _ _/       \_ _ _
 // D0/D6          D6      D0     D6     
 // .              .       .      .
 // .              .       .      .
 // .              .       .      .
 // D5/D11         D11     D5     D11
*/


// adc_dco -> BUFDS -> IDELAY(?) -> BUFR 
// data: data -> IBUFDS -> IDELAY(?) -> IDDR -> FIFO
IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("LVDS")     // Specify the input I/O standard
) IBUFDS_dco (
    .O(dco),  // Buffer output
    .I(adc0_dco_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(adc0_dco_n) // Diff_n buffer input (connect directly to top-level port)
);

BUFR #(
    .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES" 
)
BUFR_dco (
    .O(dco_bufr),     // 1-bit output: Clock output port
    .CE(),   // 1-bit input: Active high, clock enable (Divided modes only)
    .CLR(), // 1-bit input: Active high, asynchronous clear (Divided modes only)
    .I(dco)      // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);


genvar var;
generate
    for (var = 0; var < 6; var = var + 1) begin: adc_data_bufds
        IBUFDS #(
            .DIFF_TERM("TRUE"),       // Differential Termination
            .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD("LVDS")     // Specify the input I/O standard
        ) IBUFDS_adc (
            .O(data_bufds[var]),  // Buffer output
            .I(adc0_din_p[var]),  // Diff_p buffer input (connect directly to top-level port)
            .IB(adc0_din_n[var]) // Diff_n buffer input (connect directly to top-level port)
        );
    end
endgenerate


generate

    for (var = 0; var < 8; var = var + 1) begin: adc_data_iddr
        IDDR #(
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE"
                                      //    or "SAME_EDGE_PIPELINED"
            .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
            .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
            .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
        ) IDDR_inst (
            .Q1(adc_data_q1[var]), // 1-bit output for positive edge of clock
            .Q2(adc_data_q2[var]), // 1-bit output for negative edge of clock
            .C(dco_bufr),   // 1-bit clock input
            .CE(iddr_ce), // 1-bit clock enable input
            .D(data_bufds[var]),   // 1-bit DDR data input
            .R(iddr_rst),   // 1-bit reset
            .S(1'b0)    // 1-bit set
        );
    end
endgenerate

endmodule