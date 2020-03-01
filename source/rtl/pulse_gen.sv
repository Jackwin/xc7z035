`timescale 1ns/1ps

module pulse_gen (
input logic         clk,
input logic         clk_div,
input logic         rst,

input logic [10:0]  pulse_width_i,
input logic [10:0]  pulse_num_i,
input logic [15:0]  gap_us_i,
input logic         start_i,    

output logic        trig_o,
output logic        done_o,
output logic        q

);

enum logic [5:0] { 
    IDLE = 6'b00_0001,
    ZERO_INIT = 6'b00_0010,
    ONE_SEND = 6'b00_0100,
    F_SEND = 6'b00_1000,
    DELAY = 6'b01_0000,
    DONE = 6'b10_0000
} cs, ns;

logic [2:0]     remain_8;
logic [7:0]     multi_8;
logic [7:0]     data;
logic [7:0]     f_cnt;
logic [10:0]    pulse_cnt;
logic [6:0]     ns_cnt;
logic [15:0]    us_cnt;
logic           start_r1, start_r2, start;
logic [15:0]    gap_us;
logic [10:0]    pulse_num;
logic [10:0]    pulse_width;

logic           done;

always_ff @(posedge clk_div) begin
    start_r1 <= start_i;
    start_r2 <= start_r1;
    start <= ~start_r2 & start_r1;

    gap_us <= gap_us_i;
    pulse_num <= pulse_num_i;
    pulse_width <= pulse_width_i;
end

always_comb begin
    remain_8 = pulse_width[2:0];
    multi_8 = pulse_width[10:3];
    done_o = done;
    trig_o = (cs == ONE_SEND);
end

always_ff @(posedge clk_div) begin
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
            if (start) ns = ZERO_INIT;
            else ns = IDLE;
        end
        ZERO_INIT: begin
            ns = ONE_SEND;
        end
        ONE_SEND: begin
            if (multi_8 == 0) ns = DELAY;
            else ns = F_SEND;
        end
        F_SEND: begin
            if (f_cnt == multi_8 - 1) begin
                ns = DELAY;
            end
        end
        DELAY: begin
            if (ns_cnt == 7'd124 & (us_cnt == (gap_us - 1)) & (pulse_cnt != (pulse_num - 1))) begin
                ns = ZERO_INIT;
            end
            else if (ns_cnt == 7'd124 & (us_cnt == (gap_us - 1)) & (pulse_cnt == (pulse_num - 1)) begin
                ns = DONE;
            end
        end
        DONE: begin
            ns = IDLE;
        end
        default: begin
            ns = IDLE;
        end

    endcase
end



always_ff @(posedge clk_div) begin
    if (rst) begin
        data <= 0;
        f_cnt <= 0;
        ns_cnt <= 0;
        us_cnt <= 0;
        pulse_cnt <= 0;
        done <= 0;
    end
    else begin
        case(cs)
            IDLE: begin
                data <= 0;
                f_cnt <= 0;
                ns_cnt <= 0;
                us_cnt <= 0;
                pulse_cnt <= 0;
                done <= 0;
            end
            ZERO_INIT: begin
                data <= 0;
                f_cnt <= 0;
                ns_cnt <= 0;
                us_cnt <= 0;
            end

            ONE_SEND: begin
                case(remain_8)
                    3'd0: data <= 8'b0000_0000;
                    3'd1: data <= 8'b1000_0000;
                    3'd2: data <= 8'b1100_0000;
                    3'd3: data <= 8'b1110_0000;
                    3'd4: data <= 8'b1111_0000;
                    3'd5: data <= 8'b1111_1000;
                    3'd6: data <= 8'b1111_1100;
                    3'd7: data <= 8'b1111_1110;
                endcase
            end
            F_SEND: begin
                f_cnt <= f_cnt + 1;
                data <= 8'hff;
            end
            DELAY: begin
                data <= 8'h0;
                if (ns_cnt == 7'd124) begin // clk is 125MHz,
                    ns_cnt <= 0;
                    if (us_cnt == gap_us - 1) begin
                        pulse_cnt <= pulse_cnt + 1;
                        us_cnt <= 0;
                    end
                    else begin
                        us_cnt <= us_cnt + 1;
                    end
                end 
                else begin
                    ns_cnt <= ns_cnt + 1;
                end
            end
            DONE: begin
                done <= 1;
            end
            default: begin
                done <= 0;
                data <= 0;
            end
        endcase

    end
end

logic   q1;

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
    .D1(data[0]),
    .D2(data[1]),
    .D3(data[2]),
    .D4(data[3]),
    .D5(data[4]),
    .D6(data[5]),
    .D7(data[6]),
    .D8(data[7]),
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
 

ila_pulse_gen ila_pulse_gen_ila (
	.clk(clk_div), // input wire clk
	.probe0(cs), // input wire [5:0]  probe0  
	.probe1(multi_8), // input wire [7:0]  probe1 
	.probe2(remain_8), // input wire [2:0]  probe2 
	.probe3(f_cnt), // input wire [7:0]  probe3 
	.probe4(pulse_cnt), // input wire [10:0]  probe4 
	.probe5(ns_cnt), // input wire [6:0]  probe5 
	.probe6(start_i), // input wire [0:0]  probe6 
	.probe7(done) // input wire [0:0]  probe7
);



endmodule
