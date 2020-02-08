module trig (
    input logic     sys_clk, // 20MHz
    input logic     sys_rst,

    input  logic    trig_in,
    output logic    trig_d_o,
    output logic    trig_rst_o

);
parameter TRIG_PULSE_WIDTH = 50;
localparam CNT_NUM = 20 * TRIG_PULSE_WIDTH; // us

logic [15:0]    cnt;
logic           trig_d;
logic           cnt_ena;
logic           trig_in_r;
(* keep = "true" *)logic [2:0]     trig_rst;


always_ff @(posedge sys_clk) begin
    trig_in_r <= trig_in;
end

always_comb begin
    trig_d_o = 0;
    trig_rst_o = | trig_rst;
end
/*
always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        cnt_ena <= 0;
    end
    else begin
        if (trig_in) begin
            cnt_ena <= 1;
        end
        else if (cnt == CNT_NUM) begin
            cnt_ena <= 0;
        end
    end
end
*/
always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        cnt <= 0;
    end
    else begin
        /*
        if (cnt == CNT_NUM) begin
            cnt <= 0;
        end
        */
        if (trig_in_r) begin
            cnt <= cnt + 1;
        end
        else begin
            cnt <= 0;
        end
    end
end

always_ff @(posedge sys_clk) begin
    trig_rst <= {trig_rst[1:0],(cnt == CNT_NUM)};
end

ila_trig ila_trig_i (
	.clk(sys_clk), // input wire clk

	.probe0(trig_in), // input wire [0:0]  probe0  
	.probe1(trig_rst), // input wire [2:0]  probe1 
	.probe2(cnt), // input wire [15:0]  probe2 
	.probe3(trig_in_r) // input wire [0:0]  probe3
);

endmodule