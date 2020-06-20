`timescale 1ns/1ps

module datamover_rd (
    input                   clk,
    input                   rst,

    input                   i_start,
    input [8:0]             i_length,
    input [31:0]            i_start_addr,

    input                   i_mm2s_rd_cmd_tready,
    output logic [71:0]     o_mm2s_rd_cmd_tdata,
    output logic            o_mm2s_rd_cmd_tvalid,

    input [63:0]            i_mm2s_rd_tdata,
    input [7:0]             i_mm2s_rd_tkeep,
    input                   i_mm2s_rd_tvalid,
    input                   i_mm2s_rd_tlast,
    output                  o_mm2s_rd_tready
);

logic           start_r;
logic           start_p;

logic [31:0]    s2mm_rd_saddr;
logic [8:0]     s2mm_rd_length;

assign o_mm2s_rd_tready = 1;

always_ff @(posedge clk) begin
    start_r <= i_start;
    start_p <= ~start_r & i_start;
end

always_comb begin
    s2mm_rd_saddr = i_start_addr;
    s2mm_rd_length = i_length;
end

enum logic [2:0] {
    IDLE_s = 'd0,
    RD_CMD_s = 'd1,
    RD_DATA_s = 'd2
} cs, ns;

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= IDLE_s;
    end else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs;
    case(cs)
        IDLE_s: begin
            if (start_p) begin
                ns = RD_CMD_s;
            end     
        end
        RD_CMD_s: begin
            if (i_mm2s_rd_cmd_tready) begin
                ns = RD_DATA_s;
            end
        end
        RD_DATA_s: begin
            if (i_mm2s_rd_tvalid & i_mm2s_rd_tlast) begin
                ns = IDLE_s;
            end
        end
        default: ns = IDLE_s;
    endcase
end

always_comb begin
    o_mm2s_rd_cmd_tvalid = 0;
    o_mm2s_rd_cmd_tdata = 0;
    case(cs)
        IDLE_s, RD_DATA_s: begin
            o_mm2s_rd_cmd_tvalid = 0;
        end
        RD_CMD_s: begin
            o_mm2s_rd_cmd_tvalid = 1;
            o_mm2s_rd_cmd_tdata = {8'd0, s2mm_rd_saddr, 1'b0, 1'b1, 7'd1, 14'd0, s2mm_rd_length};
        end
        default: begin
            o_mm2s_rd_cmd_tvalid = 0;
        end
    endcase
end

ila_datamover_rd ila_dm_rd (
	.clk(clk), // input wire clk
	.probe0(i_start), // input wire [0:0]  probe0  
	.probe1(i_length), // input wire [8:0]  probe1 
	.probe2(i_start_addr), // input wire [31:0]  probe2 
	.probe3(i_mm2s_rd_cmd_tready), // input wire [0:0]  probe3 
	.probe4(o_mm2s_rd_cmd_tdata), // input wire [71:0]  probe4 
	.probe5(o_mm2s_rd_cmd_tvalid), // input wire [0:0]  probe5 
	.probe6(i_mm2s_rd_tdata), // input wire [63:0]  probe6 
	.probe7(i_mm2s_rd_tkeep), // input wire [7:0]  probe7 
	.probe8(i_mm2s_rd_tvalid), // input wire [0:0]  probe8 
	.probe9(i_mm2s_rd_tlast), // input wire [0:0]  probe9 
	.probe10(o_mm2s_rd_tready) // input wire [0:0]  probe10
);


endmodule