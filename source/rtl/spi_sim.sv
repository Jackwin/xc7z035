`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2019 12:53:32 PM
// Design Name: 
// Module Name: spi_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_sim(

    );

logic sys_clk;
logic sys_rst;
logic spi_clk;

initial begin
    sys_clk = 0;
    forever begin
        #5 sys_clk = ~sys_clk;
    end
end

initial begin
    sys_rst = 1;
    # 120 sys_rst = 0;
end

logic [2:0]     sys_clk_cnt = 0;
always @(sys_clk) begin
    if (sys_rst) begin
        sys_clk_cnt <= 0;
    end
    else begin
        sys_clk_cnt <= sys_clk_cnt + 1;
    end
end
assign spi_clk = sys_clk_cnt[2];

logic           spi_wr_cmd;
logic           spi_rd_cmd;
logic           spi_busy;
logic [23:0]    spi_wr_data;
logic [7:0]    spi_rd_data;
logic           spi_sclk;
logic           spi_cs_n;
logic           spi_mosi;
logic           spi_oe;
logic           spi_miso;

initial begin
    spi_wr_cmd = 0;
    spi_rd_cmd = 0;
    #200;
    @(posedge sys_clk) begin
        if (~spi_busy) begin
            spi_wr_cmd <= 1;
            spi_wr_data <= 24'h5aa5cf;
        end
    end

    @(posedge sys_clk) begin
        spi_wr_cmd <= 1'b0;
    end

    wait(~spi_busy);
    #1500;
    @(posedge sys_clk) begin
        if (~spi_busy) begin
            spi_rd_cmd <= 1;
            spi_wr_data <= 24'h00a5ca;
        end
    end

    @(posedge sys_clk) begin
        spi_rd_cmd <= 0;
    end
end

spi_master #(
      .CPOL( 0 ),
      .FREE_RUNNING_SPI_CLK( 0 ),
      .MOSI_DATA_WIDTH( 24 ),
      .WRITE_MSB_FIRST( 1 ),
      .MISO_DATA_WIDTH( 8 ),
      .READ_MSB_FIRST( 1 ),
      .INSTR_HEADER_LEN(16)
    ) SM1 (
      .clk(sys_clk),
      .nrst(~sys_rst  ),
      .spi_clk(spi_clk),
      .spi_wr_cmd(spi_wr_cmd ),
      .spi_rd_cmd(spi_rd_cmd ),
      .spi_busy(spi_busy),
      .mosi_data(spi_wr_data),
      .miso_data(spi_rd_data),
      .clk_pin(spi_sclk),
      .ncs_pin(spi_cs_n),
      .mosi_pin(spi_mosi),
      .oe_pin(spi_oe),
      .miso_pin(spi_miso)
    );
endmodule
