
module ad5339 (

    input logic             sys_clk,
    input logic             sys_rst,

    input logic             wr_start_i,
    input logic [11:0]      wr_data_i,

    input logic             rd_start_i,
    output logic [11:0]     rd_data_o,
    output logic            busy_o,

    output logic [6:0]      device_addr_o,
    output logic [7:0]      iic_wr_data_o,
    output logic [7:0]      iic_wr_addr_o,
    output logic            iic_wr_req_o,
    input logic             iic_wr_ack_i,
    input logic             iic_wr_go_i,
    input logic             iic_wr_done_i,

    output logic            iic_rd_req_o,
    output logic [7:0]      iic_rd_addr_o,
    input logic             iic_rd_ack_i,
    input logic             iic_rd_done_i,
    input logic [7:0]       iic_rd_data_i,
    input logic             iic_rd_go_o

);



parameter SLAVE_ADDR = 7'b0001100;
localparam IDLE_s = 2'd0,
           WR_s = 2'd1,
           RD_s = 2'd2,
           END_s = 2'd3;


logic [1:0] cs;
logic       busy;

always_comb begin
    device_addr_o = SLAVE_ADDR;
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        cs <= IDLE_s;
    end
    else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs;
    case(cs)
    IDLE_s: begin
        if (wr_start_i & ~busy ) begin
            ns = WR_s;
        end
        else if (rd_start_i & ~busy) begin
            ns = RD_s;
        end
        else begin
            ns = IDLE_s;
        end
    end
    WR_s: begin
        if (iic_wr_ack_i) begin
            ns = END_s;
        end
        else begin
            ns = WR_s;
        end
    end
    RD_s: begin
        if (iic_rd_ack_i) begin
            ns = END_s;
        end
    end
    END_s: begin
        if (iic_wr_done_i | iic_rd_done_i) begin
            ns = IDLE_s;
        end
    end
end

always_ff @(posedge sys_clk) begin
    if (rst) begin
        iic_wr_req_o <= 0;
        iic_rd_req_o <= 0;
    end
    else begin
        case(cs) 
        IDLE_s: begin
            iic_wr_req_o <= 0;
            iic_rd_req_o <= 0;
        end
        WR_s: begin
            iic_wr_req_o <= 1;
            iic_wr_addr_o <= 8'h1;
            iic_wr_addr_o <= {4'b0, wr_data_i[11:8]};
            iic_wr_data_o <= {wr_data_i[7:0]};
        end











endmodule