
`timescale 1ns/1ps
module ad9434_data #(
    parameter WR_EOF_VAL = 4'b1010
    ) (
    input           clk_200m,
    input           rst,
    input           i_trig,
    input [9:0]     i_us_capture,

    output          o_cap_done,

    input [5:0]     i_adc0_din_p,
    input [5:0]     i_adc0_din_n,
    input           i_adc0_or_p,
    input           i_adc0_or_n,
    input           i_adc0_dco_p,
    input           i_adc0_dco_n,
    /*
    output logic    o_bram_clk,
    output logic    o_bram_rst,
    output logic [31:0] o_bram_addr,
    output logic [31:0] o_bram_data,
    output logic    o_bram_ena,
    output logic    o_bram_wea,
    */
    // datamover interface
    input                   dm_clk,
    input                   dm_rst,
    input                   i_s2mm_wr_cmd_tready,
    output logic [71:0]     o_s2mm_wr_cmd_tdata,
    output logic            o_s2mm_wr_cmd_tvalid,

    output logic [63:0]     o_s2mm_wr_tdata,
    output logic [7:0]      o_s2mm_wr_tkeep,
    output logic            o_s2mm_wr_tvalid,
    output logic            o_s2mm_wr_tlast,
    input  logic            i_s2mm_wr_tready,

    input  logic [7:0]      s2mm_sts_tdata,
    input  logic            s2mm_sts_tvalid,
    input  logic            s2mm_sts_tkeep,
    input  logic            s2mm_sts_tlast

);

localparam      CLK_MODE = "BUR";
logic           dco;
logic           dco_bufr;
logic [5:0]     data_bufds;
logic [5:0]     adc_data_q1;
logic [5:0]     adc_data_q2;
logic           adc_or;
logic [5:0]     data_idelay;
/*
logic [31:0]    ram_addr;
logic [31:0]    ram_data;
logic           ram_ena;
logic           ram_wea;
*/

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
    .I(i_adc0_dco_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(i_adc0_dco_n) // Diff_n buffer input (connect directly to top-level port)
);

IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("LVDS")     // Specify the input I/O standard
) IBUFDS_or (
    .O(adc_or),  // Buffer output
    .I(i_adc0_or_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(i_adc0_or_n) // Diff_n buffer input (connect directly to top-level port)
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


if (CLK_MODE == "MMCM") begin :mmcm_mode
    assign clkin = dco_idelay;
    //assign adc_clk = clkoutbufg;
   // BUFG bufg_clkout0 (.I(clkout0), .O(clkoutbufg)) ;
   // BUFG bufg_fbout (.I(clkfbout), .O(clkfbin));
    
      clk_wiz_0 clk_wiz_inst
     (
      // Clock out ports
      .adc_clk_90(adc_clk),     // output adc_clk_90
      // Status and control signals
      .reset(rst), // input reset
      .locked(),       // output locked
     // Clock in ports
      .clk_in1(clkin));      // input clk_in1

/*
    MMCME2_ADV #(
        .BANDWIDTH		("OPTIMIZED"),  		
        .CLKFBOUT_MULT_F	(CLKFBOUT_MULT_F),       			
        .CLKFBOUT_PHASE		(0.0),     			
        .CLKIN1_PERIOD		(CLKIN_PERIOD),  		
        .CLKIN2_PERIOD		(CLKIN_PERIOD),  		
        .CLKOUT0_DIVIDE_F	(CLKOUT0_DIVIDE_F),       			
        .CLKOUT0_DUTY_CYCLE	(0.5), 				
        .CLKOUT0_PHASE		(90.0),				
        .CLKOUT0_USE_FINE_PS	("FALSE"),
        .CLKOUT1_PHASE		(0),				
        .CLKOUT1_DIVIDE		(CLKOUT1_DIVIDE),   				
        .CLKOUT1_DUTY_CYCLE	(0.5), 				
        .CLKOUT1_USE_FINE_PS	("FALSE"),    			
        .COMPENSATION		("ZHOLD"),		
        .DIVCLK_DIVIDE		(DIVCLK_DIVIDE),        		
        .REF_JITTER1		(0.100))        		
    mmcm_adv_inst (
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
end

else begin:idelay_mode
    
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
/*

    IDELAYE2 #(
        .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
        .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
        .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE(1),                // Input delay tap setting (0-31)
        .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
        .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        .SIGNAL_PATTERN("CLOCK")          // DATA, CLOCK input signal
    )
    IDELAYE2_clk (
        .CNTVALUEOUT(), // 5-bit output: Counter value output
        .DATAOUT(dco_idelay),         // 1-bit output: Delayed data output
        .C(clk_200m),                     // 1-bit input: Clock input
        .CE(1'b0),                   // 1-bit input: Active high enable increment/decrement input
        .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
        .CNTVALUEIN(),   // 5-bit input: Counter value input
        .DATAIN(),           // 1-bit input: Internal delay data input
        .IDATAIN(dco),         // 1-bit input: Data input from the I/O
        .INC(1'b0),                 // 1-bit input: Increment / Decrement tap delay input
        .LD(1'b0),                   // 1-bit input: Load IDELAY_VALUE input
        .LDPIPEEN(1'b0),       // 1-bit input: Enable PIPELINE register to load data input
        .REGRST(rst)            // 1-bit input: Active-high reset tap-delay input
    );
    */

    assign adc_clk = dco_bufr;
end

IDELAYCTRL IDELAYCTRL_dco (
    .RDY(),       // 1-bit output: Ready output
    .REFCLK(clk_200m), // 1-bit input: Reference clock input
    .RST(rst)        // 1-bit input: Active high reset input
 );
 


genvar i;
generate
    for (i = 0; i < 6; i = i + 1) begin: adc_data_bufds
        IBUFDS #(
            .DIFF_TERM("TRUE"),       // Differential Termination
            .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
            .IOSTANDARD("LVDS")     // Specify the input I/O standard
        ) IBUFDS_adc (
            .O(data_bufds[i]),  // Buffer output
            .I(i_adc0_din_p[i]),  // Diff_p buffer input (connect directly to top-level port)
            .IB(i_adc0_din_n[i]) // Diff_n buffer input (connect directly to top-level port)
        );
    end
endgenerate

generate 
    for (i = 0; i < 6; i = i + 1) begin: idelay
   
    //(* IODELAY_GROUP = idelay1 *) // Specifies group name for associated IDELAYs/ODELAYs and IDELAYCTRL
    IDELAYE2 #(
        .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
        .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
        .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        .IDELAY_VALUE(1),                // Input delay tap setting (0-31)
        .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
        .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
    )
    IDELAYE2_data (
        .CNTVALUEOUT(), // 5-bit output: Counter value output
        .DATAOUT(data_idelay[i]),         // 1-bit output: Delayed data output
        .C(clk_200m),                     // 1-bit input: Clock input
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

//assign data_idelay = data_bufds;

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
//-------------------------------------
enum logic [3:0] {
    IDLE = 4'b001,
    CAPTURE = 4'b010,
    DONE = 4'b100,
    END = 4'b1000
} cs, ns;

enum logic [1:0] {
    DM_IDLE_s = 2'd0,
    DM_CMD_s = 2'd1,
    DM_DATA_s = 2'd2,
    DM_WAIT_s = 2'd3
} dm_cs, dm_ns;
logic [11:0]    adc_data;
logic [7:0]     cnt;
logic [9:0]     us_cnt;
logic           store_ena;
logic           store_done; // store data to DDR in PS
logic           cap_done;
logic           trig;
logic           i_trig_r;

logic           fifo_wr_ena;
logic [15:0]    fifo_din;
logic           fifo_full;
logic [6:0]     fifo_wr_cnt;

logic           fifo_rd_ena;
logic           fifo_empty;
logic [63:0]    fifo_dout;
logic [4:0]     fifo_rd_cnt;
logic [4:0]     fifo_rd_cnt_next;



// clock domain crossing
always_ff @(posedge clk_200m) begin
    i_trig_r <= i_trig;
    trig <= i_trig_r;
end


always_ff @(posedge clk_200m) begin
    if (rst) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs;
    case(cs)
        IDLE: begin
            if (trig) begin
                ns = CAPTURE;
            end
        end
        CAPTURE: begin
            if (us_cnt == i_us_capture) begin
                ns = DONE;
            end
        end
        DONE: begin
            ns = END;
        end
        END: begin
            ns = IDLE;
        end
        default: ns = IDLE;
    endcase
end

always_ff @(posedge clk_200m) begin
    if (rst) begin
        cnt <= 0;
        us_cnt <= 0;
        cap_done <= 0;
        store_ena <= 0;
      //  fifo_wr_cnt <= 0;
    end
    else begin
        case(cs)
            IDLE: begin
                cnt <= 0;
                us_cnt <= 0;
                cap_done <= 0;
                store_ena <= 0;
              //  fifo_wr_cnt <= 0;
            end
            CAPTURE: begin
                if (cnt == 8'd199) begin  // 1us
                    cnt <= 0;
                    us_cnt <= us_cnt + 1'b1;
                end
                else begin
                    cnt <= cnt + 1;
                end

                //fifo_wr_cnt <= fifo_wr_cnt + 1;

            end
            DONE: begin
                cap_done <= 1;
            end
            default: begin
                cnt <= 0;
                us_cnt <= 0;
                cap_done <= 0;
                store_ena <= 0;
            end
        endcase
    end
end

assign o_cap_done = cap_done;

// When fifo stores 256B data, assert the fifo_256b_done
logic fifo_256b_done;
logic fifo_256b_done_r1;
logic fifo_256b_done_r2;
logic fifo_256b_done_cdc;
logic fifo_256b_done_sync;
logic fifo_256b_done_dm;
always_comb begin
    adc_data = {adc_data1, adc_data2};
   // fifo_din = {4'h0, adc_data};
    fifo_wr_ena = (cs == CAPTURE);
    fifo_256b_done = (cs == CAPTURE) & (fifo_wr_cnt == 7'h7f);
end

always_ff @(posedge adc_clk) begin
    if (rst) begin
        fifo_din <= 16'h0001;
    end else begin
        if (cs == CAPTURE) begin
            fifo_din <= fifo_din + 16'h0202;
        end
    end
end

always_ff @(posedge adc_clk) begin
    if (rst) begin
        fifo_wr_cnt <= 0;
    end else begin
        if (cs == IDLE) begin
            fifo_wr_cnt <= 'h0;
        end else if (cs == CAPTURE) begin
            fifo_wr_cnt <= fifo_wr_cnt + 1; // use fifo_count
        end
    end
end

always_ff @(posedge adc_clk) begin
    fifo_256b_done_r2 <= fifo_256b_done_r1;
    fifo_256b_done_r1 <= fifo_256b_done;
    fifo_256b_done_cdc <= fifo_256b_done | fifo_256b_done_r1 | fifo_256b_done_r2;
end
// clock domain crossing from 400M to 300MHz
always_ff @(posedge dm_clk) begin
    fifo_256b_done_sync <= fifo_256b_done_cdc;
    fifo_256b_done_dm <= fifo_256b_done_sync;
end

always_ff @(posedge dm_clk) begin
    if (dm_rst) begin
        dm_cs <= DM_IDLE_s;
        fifo_rd_cnt <= 'h0;
    end else begin
        dm_cs <= dm_ns;
        fifo_rd_cnt <= fifo_rd_cnt_next;
    end
end

always_comb begin
    dm_ns = dm_cs;
    case(dm_cs)
        DM_IDLE_s: begin
            if (fifo_256b_done_dm) dm_ns = DM_CMD_s;
            else dm_ns = DM_IDLE_s;
        end
        DM_CMD_s: begin
            if (i_s2mm_wr_cmd_tready) dm_ns = DM_DATA_s;
            else dm_ns = DM_CMD_s;
        end
        DM_DATA_s: begin
            if (fifo_rd_cnt == 5'h1f & i_s2mm_wr_tready) dm_ns = DM_WAIT_s; // i_s2mm_wr_tready?
            else dm_ns = DM_DATA_s;
        end
        DM_WAIT_s: begin
            if (s2mm_sts_tdata[3:0] == WR_EOF_VAL & s2mm_sts_tvalid & s2mm_sts_tlast) begin
                dm_ns = DM_IDLE_s;
            end else begin
                dm_ns = DM_WAIT_s;
            end
        end
        default: dm_ns = DM_IDLE_s;
    endcase
end

always_comb begin
    fifo_rd_cnt_next = fifo_rd_cnt;
    fifo_rd_ena = 0;
    o_s2mm_wr_cmd_tdata = 'h0;
    o_s2mm_wr_cmd_tvalid = 0;
    case(dm_cs)
        DM_IDLE_s: begin
            fifo_rd_cnt_next = 0;
            fifo_rd_ena = 0;
        end
        DM_CMD_s: begin
            o_s2mm_wr_cmd_tdata = {4'd0, WR_EOF_VAL, 32'h04000000, 1'b0, 8'd1, 14'd0, 9'd256};
            o_s2mm_wr_cmd_tvalid = 1;
        end
        DM_DATA_s: begin
            if (i_s2mm_wr_tready & ~fifo_empty) begin
                fifo_rd_cnt_next = fifo_rd_cnt + 1;
                fifo_rd_ena = 1;
            end
        end
        DM_WAIT_s: begin
            fifo_rd_cnt_next = 0;
            fifo_rd_ena = 0;
        end
        default: begin
            fifo_rd_cnt_next = 0;
            fifo_rd_ena = 0;
        end
    endcase
end

always_comb begin
    o_s2mm_wr_tdata = fifo_dout;
    o_s2mm_wr_tvalid = ~fifo_empty & (dm_cs == DM_DATA_s);
    o_s2mm_wr_tkeep = 'hff;
    o_s2mm_wr_tlast = (fifo_rd_cnt == 5'h1f);
end


xpm_fifo_async # (

  .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (2048),             //positive integer
  .WRITE_DATA_WIDTH          (16),               //positive integer
  .WR_DATA_COUNT_WIDTH       (12),               //positive integer
  .PROG_FULL_THRESH          (2040),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .USE_ADV_FEATURES          ("0002"),           //string; "0000" to "1F1F"; 
  .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (1),                //positive integer;
  .READ_DATA_WIDTH           (64),               //positive integer
  .RD_DATA_COUNT_WIDTH       (10),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

) fifo_adc (

  .rst              (rst),
  .wr_clk           (adc_clk),
  .wr_en            (fifo_wr_ena),
  .din              (fifo_din),
  .full             (fifo_full),
  .overflow         (),
  .prog_full        (),
  .wr_data_count    (),
  .almost_full      (),
  .wr_ack           (),
  .wr_rst_busy      (),
  .rd_clk           (dm_clk),
  .rd_en            (fifo_rd_ena),
  .dout             (fifo_dout),
  .empty            (fifo_empty),
  .underflow        (),
  .rd_rst_busy      (),
  .prog_empty       (),
  .rd_data_count    (),
  .almost_empty     (),
  .data_valid       (),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

);


ila_adc0_ddr ila_adc0_ddr_i (
	.clk(adc_clk), // input wire clk
	.probe0(adc_data1), // input wire [5:0]  probe0  
	.probe1(adc_data2), // input wire [5:0]  probe1 
	.probe2(adc_or), // input wire [0:0]  probe2 
	.probe3(trig), // input wire [0:0]  probe3 
	.probe4(cap_done), // input wire [0:0]  probe4 
	.probe5(store_ena) // input wire [0:0]  probe5
);

endmodule