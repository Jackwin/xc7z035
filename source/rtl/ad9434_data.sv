`timescale 1ns/1ps
module ad9434_data (
    input           clk_200m_in,
    input           rst,
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
logic           adc_or;
logic [5:0]     data_idelay;

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

IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("LVDS")     // Specify the input I/O standard
) IBUFDS_or (
    .O(adc_or),  // Buffer output
    .I(adc0_or_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(adc0_or_n) // Diff_n buffer input (connect directly to top-level port)
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

localparam CLKIN_PERIOD = 4.00;
localparam CLKFBOUT_MULT_F = 4.00;
localparam DIVCLK_DIVIDE = 1;
localparam CLKOUT1_DIVIDE = 4;
localparam CLKOUT0_DIVIDE_F = 4;
wire    clkout0;
wire    clkoutbufg;
wire    clkfbout;
wire    clkfbin;
wire    mmcm_locked;
wire    clkin;
wire    adc_clk;
wire    dco_idelay;

//assign clkin = dco_idelay;
//assign clkin = dco;
//assign adc_clk = clkoutbufg;
assign adc_clk = dco_bufr;



 // (* IODELAY_GROUP = idelay1 *) // Specifies group name for associated IDELAYs/ODELAYs and IDELAYCTRL



/*
BUFG bufg_clkout0 (.I(clkout0), .O(clkoutbufg)) ;

BUFG bufg_fbout (.I(clkfbout), .O(clkfbin));



MMCME2_ADV #(
    .BANDWIDTH		("OPTIMIZED"),  		
    .CLKFBOUT_MULT_F	(CLKFBOUT_MULT_F),       			
    .CLKFBOUT_PHASE		(0.0),     			
    .CLKIN1_PERIOD		(CLKIN_PERIOD),  		
    .CLKIN2_PERIOD		(CLKIN_PERIOD),  		
    .CLKOUT0_DIVIDE_F	(CLKOUT0_DIVIDE_F),       			
    .CLKOUT0_DUTY_CYCLE	(0.5), 				
    .CLKOUT0_PHASE		(45.0),				
    .CLKOUT0_USE_FINE_PS	("FALSE"),
    .CLKOUT1_PHASE		(0),				
    .CLKOUT1_DIVIDE		(CLKOUT1_DIVIDE),   				
    .CLKOUT1_DUTY_CYCLE	(0.5), 				
    .CLKOUT1_USE_FINE_PS	("FALSE"),    			
    .COMPENSATION		("ZHOLD"),		
    .DIVCLK_DIVIDE		(DIVCLK_DIVIDE),        		
    .REF_JITTER1		(0.100))        		
rx_mmcm_adv_inst (
    .CLKFBOUT		(clkfbout),              		
    .CLKFBOUTB		(),              		
    .CLKFBSTOPPED		(),              		
    .CLKINSTOPPED		(),              		
    .CLKOUT0		(clkout0),      		
    .CLKOUT0B		(),      			
    .CLKOUT1		(),      		 
    .PSCLK			(1'b0),  
    .PSEN			(1'b0),  
    .PSINCDEC		(1'b0),  
    .PWRDWN			(1'b0), 
    .LOCKED			(mmcm_locked),        		
    .CLKFBIN		(clkfbin),			
    .CLKIN1			(clkin),     	
    .CLKIN2			(1'b0),		     		
    .CLKINSEL		(1'b1),             		
    .DADDR			(7'h00),            		
    .DCLK			(1'b0),               		
    .DEN			(1'b0),                		
    .DI			    (16'h0000),        		
    .DWE			(1'b0),                		
    .RST			(rst)
    );              	
*/
IDELAYCTRL IDELAYCTRL_dco (
    .RDY(),       // 1-bit output: Ready output
    .REFCLK(clk_200m_in), // 1-bit input: Reference clock input
    .RST(rst)        // 1-bit input: Active high reset input
 );
genvar i;

generate 
    for (i = 0; i < 6; i = i + 1) begin: idelay
   
    //(* IODELAY_GROUP = idelay1 *) // Specifies group name for associated IDELAYs/ODELAYs and IDELAYCTRL
    IDELAYE2 #(
        .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
        .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
        .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE(19),                // Input delay tap setting (0-31)
        .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
        .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
    )
    IDELAYE2_dco (
        .CNTVALUEOUT(), // 5-bit output: Counter value output
        .DATAOUT(data_idelay[i]),         // 1-bit output: Delayed data output
        .C(clk_200m_in),                     // 1-bit input: Clock input
        .CE(1'b0),                   // 1-bit input: Active high enable increment/decrement input
        .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
        .CNTVALUEIN(),   // 5-bit input: Counter value input
        .DATAIN(),           // 1-bit input: Internal delay data input
        .IDATAIN(data_bufds[i]),         // 1-bit input: Data input from the I/O
        .INC(1'b0),                 // 1-bit input: Increment / Decrement tap delay input
        .LD(1'b0),                   // 1-bit input: Load IDELAY_VALUE input
        .LDPIPEEN(1'b0),       // 1-bit input: Enable PIPELINE register to load data input
        .REGRST(rst)            // 1-bit input: Active-high reset tap-delay input
    );
    end
endgenerate
generate
    for (i = 0; i < 6; i = i + 1) begin: adc_data_bufds
        IBUFDS #(
            .DIFF_TERM("TRUE"),       // Differential Termination
            .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD("LVDS")     // Specify the input I/O standard
        ) IBUFDS_adc (
            .O(data_bufds[i]),  // Buffer output
            .I(adc0_din_p[i]),  // Diff_p buffer input (connect directly to top-level port)
            .IB(adc0_din_n[i]) // Diff_n buffer input (connect directly to top-level port)
        );
    end
endgenerate


generate

    for (i = 0; i < 6; i = i + 1) begin: adc_data_iddr
        IDDR #(
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE"
                                      //    or "SAME_EDGE_PIPELINED"
            .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
            .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
            .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
        ) IDDR_inst (
            .Q1(adc_data_q1[i]), // 1-bit output for positive edge of clock
            .Q2(adc_data_q2[i]), // 1-bit output for negative edge of clock
            .C(adc_clk),   // 1-bit clock input
            .CE(1'b1), // 1-bit clock enable input
            .D(data_idelay[i]),   // 1-bit DDR data input
            .R(rst),   // 1-bit reset
            .S(1'b0)    // 1-bit set
        );
    end
endgenerate

reg [5:0]   adc_data1;
reg [5:0]   adc_data2;

always @(posedge adc_clk) begin
    adc_data1 <= adc_data_q1;
    adc_data2 <= adc_data_q2;
end

ila_adc0_ddr your_instance_name (
	.clk(adc_clk), // input wire clk
	.probe0(adc_data1), // input wire [5:0]  probe0  
	.probe1(adc_data2), // input wire [5:0]  probe1 
	.probe2(adc_or), // input wire [0:0]  probe2 
	.probe3(rst), // input wire [0:0]  probe3 
	.probe4(adc_or), // input wire [0:0]  probe4 
	.probe5(adc_or) // input wire [0:0]  probe5
);

endmodule