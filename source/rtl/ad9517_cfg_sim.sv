`timescale 1ns/1ps
module ad9517_cfg_sim();

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
logic [7:0]     spi_rd_data;
logic           spi_sclk;
logic           spi_cs_n;
logic           spi_mosi;
logic           spi_oe;
logic           spi_miso;
logic           cfg_start;


initial begin
    cfg_start = 0;

    #400;
    @(posedge sys_clk) cfg_start <= 1;
    @(posedge sys_clk) cfg_start <= 0;
end

ad9517_cfg ad9517_cfg_i(
    .clk(sys_clk),
    .rst(sys_rst),
    .o_spi_wr_cmd(spi_wr_cmd),
    .o_spi_rd_cmd(spi_rd_cmd),
    .o_spi_wr_data(spi_wr_data),
    .i_spi_rd_data(spi_rd_data),
    .i_spi_busy(spi_busy),
    .i_cfg_start(cfg_start)
);


spi_master #(
      .CPOL( 0 ),
      .FREE_RUNNING_SPI_CLK( 0 ),
      .MOSI_DATA_WIDTH( 24 ),
      .WRITE_MSB_FIRST( 1 ),
      .MISO_DATA_WIDTH( 8 ),
      .READ_MSB_FIRST( 1 )
    ) SM1 (
      .clk(sys_clk),
      .nrst(~sys_rst),
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
