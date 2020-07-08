/*
This module implements the user reg read switch function.
When the CPU issues a reg read operation, it will be swithed by this module, whether from
the status registers or from the control registers.
*/
module usr_reg_rd_switch #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
    )(
    input logic                   clk,
    input logic                   rst,
 
    input logic                   i_usr_reg_rd,
    input logic [ADDR_WIDTH-1:0]  i_usr_reg_addr,
    output logic [DATA_WIDTH-1:0] o_usr_reg_data,
 
    input logic [DATA_WIDTH-1:0]  i_status_reg_data,
    input logic                   i_status_reg_valid,

    input logic [DATA_WIDTH-1:0]  i_ctrl_reg_data,
    input logic                   i_ctrl_reg_valid
);

// The 8-bit low address is assgined to the status reg. The number of the status reg is 256/4 = 64
localparam STATUS_REG_MASK = {{DATA_WIDTH-8}{1'b1}};

logic rd_status_flag;

always_ff @(posedge clk) begin
    if (rst) begin
        rd_status_flag <= 0;
    end else begin
        if (i_usr_reg_rd) begin
            if (|(i_usr_reg_addr[ADDR_WIDTH-1:8] & STATUS_REG_MASK) == 0) begin
                rd_status_flag <= 1;    
            end else begin
                rd_status_flag <= 0;
            end   
        end 
    end
end

logic [DATA_WIDTH-1:0] usr_reg_data;

always_ff @(posedge clk) begin
    if (rd_status_flag & i_status_reg_valid) begin
        usr_reg_data <= i_status_reg_data;
    end else if (~rd_status_flag & i_ctrl_reg_valid) begin
        usr_reg_data <= i_ctrl_reg_data;
    end
end

always_comb begin
    o_usr_reg_data = usr_reg_data; 
end

endmodule