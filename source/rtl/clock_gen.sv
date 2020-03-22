
module clock_gen #(
    parameter   REF_CLK_PERIOD = 2,
    parameter   CLKBOUT_MULT_F = 4,
    parameter   DIVCLK_DIVIDE = 1,
    parameter   CLK0_DIVIDE = 4,
    parameter   CLK1_DIVIDE = 1,
    parameter   CLK2_DIVIDE = 2

    )(
    input       ref_clk,
    input       rst,

    output      locked_o,
    output      clk0_o,
    output      clk1_o,
    output      clk2_o

);

logic       clk_fb;
logic       clk_fb_bufg;
logic       clk0;
logic       clk0_buf;
logic       clk1;
logic       clk1_buf;
logic       clk2;
logic       clk2_buf;


MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
    .CLKFBOUT_MULT_F(CLKBOUT_MULT_F),     // Multiply value for all CLKOUT (2.000-64.000).
    .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
    .CLKIN1_PERIOD(REF_CLK_PERIOD),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
    .CLKOUT1_DIVIDE(CLK1_DIVIDE),
    .CLKOUT2_DIVIDE(CLK2_DIVIDE),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT0_DIVIDE_F(CLK0_DIVIDE),    // Divide amount for CLKOUT0 (1.000-128.000).
    // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT6_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(0.0),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_PHASE(0.0),
    .CLKOUT6_PHASE(0.0),
    .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
    .DIVCLK_DIVIDE(DIVCLK_DIVIDE),         // Master division value (1-106)
    .REF_JITTER1(0.01),         // Reference input jitter in UI (0.000-0.999).
    .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
)
MMCME2_BASE_inst (
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0(clk0),     // 1-bit output: CLKOUT0
    .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
    .CLKOUT1(clk1),     // 1-bit output: CLKOUT1
    .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
    .CLKOUT2(clk2),     // 1-bit output: CLKOUT2
    .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
    .CLKOUT3(),     // 1-bit output: CLKOUT3
    .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
    .CLKOUT4(),     // 1-bit output: CLKOUT4
    .CLKOUT5(),     // 1-bit output: CLKOUT5
    .CLKOUT6(),     // 1-bit output: CLKOUT6
    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT(clk_fb),   // 1-bit output: Feedback clock
    .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
    // Status Ports: 1-bit (each) output: MMCM status ports
    .LOCKED(locked_o),       // 1-bit output: LOCK
    // Clock Inputs: 1-bit (each) input: Clock input
    .CLKIN1(ref_clk),       // 1-bit input: Clock
    // Control Ports: 1-bit (each) input: MMCM control ports
    .PWRDWN(1'b0),       // 1-bit input: Power-down
    .RST(rst),             // 1-bit input: Reset
    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN(clk_fb_bufg)      // 1-bit input: Feedback clock
);


BUFG BUFG_clkfb (
    .O(clk_fb_bufg), // 1-bit output: Clock output
    .I(clk_fb)  // 1-bit input: Clock input
);

BUFR #(
    .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES" 
)
BUFR_clk0 (
    .O(clk0_buf),     // 1-bit output: Clock output port
    .CE(1'b1),   // 1-bit input: Active high, clock enable (Divided modes only)
    .CLR(1'b0), // 1-bit input: Active high, asynchronous clear (Divided modes only)
    .I(clk0)      // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);

assign clk0_o = clk0_buf;

BUFR #(
    .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES" 
)
BUFR_clk1 (
    .O(clk1_buf),     // 1-bit output: Clock output port
    .CE(1'b1),   // 1-bit input: Active high, clock enable (Divided modes only)
    .CLR(1'b0), // 1-bit input: Active high, asynchronous clear (Divided modes only)
    .I(clk1)      // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);

assign clk1_o = clk1_buf;

BUFG BUFG_clk2 (
      .O(clk2_buf), // 1-bit output: Clock output
      .I(clk2)  // 1-bit input: Clock input
   );

assign clk2_o = clk2_buf;

endmodule