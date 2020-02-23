`timescale 1ns/1ps

module pulse_gen (
input           clk,
input           clk_div,
input           rst,

input [10:0]    pulse_width_i,
input [10:0]    pulse_num_i,
input [15:0]    gap_us_i,
input           start_i,    

input [10:0] pulse_width_in,

output  q

);

enum logic [5:0] { 
    IDLE = 5'b00001,
    ZERO_iNIT = 5'b0_0010,
    ONE_SEND = 5'b0_0100,
    F_SEND = 5'b0_1000,
    END = 5'b1_0000
} cs, ns;

logic [2:0]     remain_8;
logic [7:0]     multi_8;
logic [7:0]     data;
logic [7:0]     f_cnt;

always_comb begin
    remain_8 = pulse_width_i[2:0];
    multi_8 = pulse_width_i[10:3];
end

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs
    case(cs)
        IDLE: begin
            if (start_i) begin ns = ZERO_iNIT;
            else ns = IDLE;
        end
        ZERO_iNIT: begin
            ns = ONE_SEND;
        end
        ONE_SEND: begin
            ns = F_SEND;
        end
        F_SEND: begin
            if (f_cnt == multi_8) begin
                ns = END;
            end
        end
        END: begin
            ns = IDLE;
        end
    endcase
end

always_ff @(posedge clk) begin
    
end



wire    tq;
wire    q1;

 OSERDESE2 #(
      .DATA_RATE_OQ("DDR"),   // DDR, SDR
      .DATA_RATE_TQ("SDR"),   // DDR, BUF, SDR
      .DATA_WIDTH(8),         // Parallel data width (2-8,10,14)
      .INIT_OQ(1'b0),         // Initial value of OQ output (1'b0,1'b1)
      .INIT_TQ(1'b0),         // Initial value of TQ output (1'b0,1'b1)
      .SERDES_MODE("MASTER"), // MASTER, SLAVE
      .SRVAL_OQ(1'b0),        // OQ output value when SR is used (1'b0,1'b1)
      .SRVAL_TQ(1'b0),        // TQ output value when SR is used (1'b0,1'b1)
      .TBYTE_CTL("FALSE"),    // Enable tristate byte operation (FALSE, TRUE)
      .TBYTE_SRC("FALSE"),    // Tristate byte source (FALSE, TRUE)
      .TRISTATE_WIDTH(1)      // 3-state converter width (1,4)
   )
   OSERDESE2_inst (
      .OFB(),             // 1-bit output: Feedback path for data
      .OQ(q1),               // 1-bit output: Data path output
      // SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      .SHIFTOUT1(),
      .SHIFTOUT2(),
      .TBYTEOUT(),   // 1-bit output: Byte group tristate
      .TFB(),             // 1-bit output: 3-state control
      .TQ(),               // 1-bit output: 3-state control
      .CLK(clk),             // 1-bit input: High speed clock
      .CLKDIV(clk_div),       // 1-bit input: Divided clock
      // D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      .D1(1'b1),
      .D2(1'b0),
      .D3(1'b1),
      .D4(1'b0),
      .D5(1'b1),
      .D6(1'b0),
      .D7(1'b1),
      .D8(1'b0),
      .OCE(1'b1),             // 1-bit input: Output data clock enable
      .RST(rst),             // 1-bit input: Reset
      // SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      .SHIFTIN1(),
      .SHIFTIN2(),
      // T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      .T1(),
      .T2(),
      .T3(),
      .T4(),
      .TBYTEIN(),     // 1-bit input: Byte group tristate
      .TCE(1'b1)              // 1-bit input: 3-state clock enable
   );

   OBUF #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) OBUF_inst (
      .O(q),     // Buffer output (connect directly to top-level port)
      .I(q1)      // Buffer input 
   );

endmodule
