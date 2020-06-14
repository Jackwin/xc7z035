`timescale 1ns/1ps

module device_cfg # (
    parameter MOSI_DATA_WIDTH = 24,
    parameter MISO_DATA_WIDTH = 8,
    parameter INSTR_HEADER_LEN = 16
    )(
    input logic     clk_20,
    input logic     rst,
    input logic     soft_rst,

    input logic     i_cfg_start,
    input logic     i_ad9517_locked,

    output logic    o_cfg_done,
    
    output logic    ad9517_cs_n,
    output logic    adc0_cs_n,
    output logic    adc1_cs_n,

    output logic    spi_sclk,
    inout  logic    spi_sdio

);

enum logic [2:0] {
    IDLE = 3'd0,
    AD9517_CFG = 3'd1,
    ADC0_CFG = 3'd2,
    ADC1_CFG = 3'd3,
    DONE = 3'd4

} cs, ns;

logic cfg_start_r, cfg_start;
logic done;
logic ad9517_cfg_start;
logic adc0_cfg_start;
logic adc1_cfg_start;
logic adc0_cfg_done;
logic adc1_cfg_done;

logic        spi_mosi;
logic        spi_miso;
logic        spi_oe, spi_oe_n;
logic [5:0]   cnt;
logic        spi_clk;
logic         spi_wr_cmd;
logic         spi_rd_cmd;
logic        spi_busy;
logic [MOSI_DATA_WIDTH-1:0] spi_wr_data;
logic [MISO_DATA_WIDTH:0]  spi_rd_data;

logic    ad9517_spi_wr_cmd;
logic    ad9517_spi_rd_cmd;
logic [MOSI_DATA_WIDTH-1:0] ad9517_spi_wr_data;
logic [MISO_DATA_WIDTH:0]  ad9517_spi_rd_data;
logic    ad9517_spi_busy;
//logic    ad9517_cfg_start;
logic    ad9517_cfg_go;

always_ff @(posedge clk_20) begin
    cfg_start_r <= i_cfg_start;
    cfg_start <= ~cfg_start_r & i_cfg_start;
end

always_ff @(posedge clk_20) begin
    if (rst | soft_rst) begin
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
            if (cfg_start) begin
                if(i_ad9517_locked) ns <= ADC0_CFG;
                else ns = AD9517_CFG;
            end
        end
        AD9517_CFG: begin
            if (i_ad9517_locked) ns = ADC0_CFG;
        end
        ADC0_CFG: begin
            if (adc0_cfg_done) ns = ADC1_CFG;
        end
        ADC1_CFG: begin
            if (adc1_cfg_done) ns = DONE;
        end
        DONE: begin
            ns = IDLE;
        end
        default: ns = IDLE;
    endcase
end

always_comb begin
    ad9517_cfg_start = 0;
    adc0_cfg_start = 0;
    adc1_cfg_start = 0;
    o_cfg_done = 0;
    case(cs)
        IDLE: begin
            ad9517_cfg_start = 0;
            adc0_cfg_start = 0;
            adc1_cfg_start = 0;
            o_cfg_done = 0;
        end
        AD9517_CFG: begin
            ad9517_cfg_start = 1;
        end
        ADC0_CFG: begin
            adc0_cfg_start = 1;
        end
        ADC1_CFG: begin
                adc1_cfg_start = 1;
        end
        DONE: begin
            o_cfg_done = 1;
        end
        default: begin
            ad9517_cfg_start = 0;
            adc0_cfg_start = 0;
            adc1_cfg_start = 0;
            o_cfg_done = 0;
        end
    endcase
end
/*
ila_device_cfg ila_device_cfg_inst (
	.clk(clk_20), // input wire clk
	.probe0(cs), // input wire [1:0]  probe0  
	.probe1(ad9517_cfg_start), // input wire [0:0]  probe1 
	.probe2(adc0_cfg_start), // input wire [0:0]  probe2 
	.probe3(adc1_cfg_start), // input wire [0:0]  probe3 
	.probe4(o_cfg_done) // input wire [0:0]  probe4
);
*/
// ------------------------------------------------------------------------

ad9517_cfg ad9517_cfg_i(
    .clk(clk_20),
    .rst(rst),
    .o_spi_wr_cmd(ad9517_spi_wr_cmd),
    .o_spi_rd_cmd(ad9517_spi_rd_cmd),
    .o_spi_wr_data(ad9517_spi_wr_data),
    .i_spi_rd_data(ad9517_spi_rd_data),
    .i_spi_busy(ad9517_spi_busy),
    .i_cfg_start(ad9517_cfg_start)
);

assign ad9517_spi_rd_data = spi_rd_data;
assign ad9517_spi_busy = spi_busy;

logic    adc0_spi_wr_cmd;
logic    adc0_spi_rd_cmd;
logic [MOSI_DATA_WIDTH-1:0] adc0_spi_wr_data;
logic [MISO_DATA_WIDTH:0]  adc0_spi_rd_data;
logic    adc0_spi_busy;
//logic    adc0_cfg_start;
logic    adc0_cfg_go;

logic    adc1_spi_wr_cmd;
logic    adc1_spi_rd_cmd;
logic [MOSI_DATA_WIDTH-1:0] adc1_spi_wr_data;
logic [MISO_DATA_WIDTH:0]  adc1_spi_rd_data;
logic    adc1_spi_busy;
//logic    adc1_cfg_start;
logic    adc1_cfg_go;

adc_cfg adc0_cfg(
    .clk(clk_20),
    .rst(rst),
    .o_spi_wr_cmd(adc0_spi_wr_cmd),
    .o_spi_rd_cmd(adc0_spi_rd_cmd),
    .o_spi_wr_data(adc0_spi_wr_data),
    .i_spi_rd_data(adc0_spi_rd_data),
    .i_spi_busy(adc0_spi_busy),
    .i_cfg_start(adc0_cfg_start),
    .o_cfg_go(adc0_cfg_go),
    .o_cfg_done(adc0_cfg_done)
);

adc_cfg adc1_cfg(
    .clk(clk_20),
    .rst(rst),
    .o_spi_wr_cmd(adc1_spi_wr_cmd),
    .o_spi_rd_cmd(adc1_spi_rd_cmd),
    .o_spi_wr_data(adc1_spi_wr_data),
    .i_spi_rd_data(adc1_spi_rd_data),
    .i_spi_busy(adc1_spi_busy),
    .i_cfg_start(adc1_cfg_start),
    .o_cfg_go(adc1_cfg_go),
    .o_cfg_done(adc1_cfg_done)
);

assign adc0_spi_rd_data = spi_rd_data;
assign adc0_spi_busy = spi_busy;
assign adc1_spi_rd_data = spi_rd_data;
assign adc1_spi_busy = spi_busy;

always @(*) begin
    if (adc0_cfg_go) begin
        spi_wr_cmd = adc0_spi_wr_cmd;
        spi_rd_cmd = adc0_spi_rd_cmd;
        spi_wr_data = adc0_spi_wr_data;
        adc0_cs_n = spi_cs_n;
        ad9517_cs_n = 1'b1;
        adc1_cs_n = 1'b1;
    end
    else if (adc1_cfg_go) begin
        spi_wr_cmd = adc1_spi_wr_cmd;
        spi_rd_cmd = adc1_spi_rd_cmd;
        spi_wr_data = adc1_spi_wr_data;
        adc1_cs_n = spi_cs_n;
        ad9517_cs_n = 1'b1;
        adc0_cs_n = 1'b1;
    end
    else begin
        spi_wr_cmd = ad9517_spi_wr_cmd;
        spi_rd_cmd = ad9517_spi_rd_cmd;
        spi_wr_data = ad9517_spi_wr_data;
        ad9517_cs_n = spi_cs_n;
        adc0_cs_n = 1'b1;
        adc1_cs_n = 1'b1;
    end
end


always @(posedge clk_20) begin
    if (rst) begin
        cnt <= 'h0;
    end
    else begin
        cnt <= cnt + 1'd1;
    end
end

assign spi_clk = cnt[5];

spi_master #(
      .CPOL( 0 ),
      .FREE_RUNNING_SPI_CLK( 1 ),
      .MOSI_DATA_WIDTH( MOSI_DATA_WIDTH),
      .WRITE_MSB_FIRST( 1 ),
      .MISO_DATA_WIDTH( MISO_DATA_WIDTH ),
      .READ_MSB_FIRST( 1 ),
      .INSTR_HEADER_LEN(INSTR_HEADER_LEN)
    ) SM1 (
      .clk(clk_20),
      .nrst(~rst  ),
      .spi_clk(spi_clk),
      .spi_wr_cmd(spi_wr_cmd ),
      .spi_rd_cmd(spi_rd_cmd ),
      .spi_busy(spi_busy),
      .mosi_data(spi_wr_data),
      .miso_data(spi_rd_data),
      .clk_pin(spi_sclk),
      .ncs_pin(spi_cs_n),
      .mosi_pin(spi_mosi),
      .oe_pin(spi_oe_n),
      .miso_pin(spi_miso)
    );

assign spi_oe = ~spi_oe_n;

IOBUF #(
    .DRIVE(12), // Specify the output drive strength
    .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
    .IOSTANDARD("DEFAULT"), // Specify the I/O standard
    .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_spi_mosi (
    .O(spi_miso),     // Buffer output
    .IO(spi_sdio),   // Buffer inout port (connect directly to top-level port)
    .I(spi_mosi),     // Buffer input
    .T(spi_oe)      // 3-state enable input, high=input, low=output
   );

ila_spi ila_spi_i (
	.clk(spi_clk), // input wire clk
	.probe0(spi_cs_n), // input wire [0:0]  probe0  
	.probe1(spi_mosi), // input wire [0:0]  probe1 
	.probe2(spi_oe), // input wire [0:0]  probe2 
	.probe3(spi_miso), // input wire [0:0]  probe3 
	.probe4(spi_sclk) // input wire [0:0]  probe4
);

endmodule