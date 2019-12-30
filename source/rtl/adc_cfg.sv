`timescale 1ns/1ps
module adc_cfg # (parameter
    bit [4:0] MOSI_DATA_WIDTH = 24,
    bit [4:0] MISO_DATA_WIDTH = 8
    )
     (
    input logic                         clk,
    input logic                         rst,

    output logic                        o_spi_wr_cmd,
    output logic                        o_spi_rd_cmd,
    output logic [MOSI_DATA_WIDTH-1:0]  o_spi_wr_data,
    input  logic [MISO_DATA_WIDTH-1:0]  i_spi_rd_data,
    input  logic                        i_spi_busy,
    input  logic                        i_cfg_start

);

localparam AD9434_ID = 8'h6A;
localparam TEST_IO = 8'h00;
localparam AIN_CFG = 8'08; // Enable analog input
localparam OUTPUT_MODE = 8'h18; //Enable output, DDR enable, offset binary
localparam OUTPUT_ADJUST = 8'h1; // LVDS 3.5mA,
localparam OUTPUT_PHASE = 8'h0; // output clock polarity non-inverted
localparam FLEX_OUTPUT_DELAY = 8'h0;
localparam FLEX_VREF = 8'h1C; //internal Vref, 1.6V input voltage range
localparam OVR_CFG = 8'h07; //OVR PIN 21,22
localparam INPUT_COUPLING = 8'h00; // AC coupling
logic [3:0]     cs, ns;
localparam  IDLE_s = 1,
            READ_ID_s = 2,
            CHECK_ID_s = 3,
            RD_ROM_s = 4,
            DELAY_s = 5,
            SPI_CFG_s = 6,
            SPI_CFG_ACK_s = 7,
            READ_CFG_s = 8,
            CONFIRM_CFG_s= 9;

logic         cfg_start_r, cfg_start;
logic         timeout;

logic           spi_wr_cmd;
logic           spi_rd_cmd;
logic [MOSI_DATA_WIDTH-1:0]  spi_wr_data;
logic [15:0]    spi_rd_data;
logic [5:0]     spi_cfg_cnt, spi_cfg_cnt_next;
logic           cfg_done;
logic           timer_ena;
logic           timer_clr;

always_comb begin
    o_spi_wr_cmd = spi_wr_cmd;
    o_spi_rd_cmd = spi_rd_cmd;
    o_spi_wr_data = spi_wr_data;
end


always_ff @(posedge clk) begin
    cfg_start_r <= i_cfg_start;
    cfg_start <= ~cfg_start_r & i_cfg_start;
end

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= IDLE_s;
        addr <= 'h0;
        spi_cfg_cnt <= 'h0;
    end
    else begin
        cs <= ns;
        addr <= addr_next;
        spi_cfg_cnt <= spi_cfg_cnt_next;
    end
end


always_comb begin
    ns = cs;
    addr_next = addr;
    spi_cfg_cnt_next = spi_cfg_cnt;
    spi_rd_cmd = 1'b0;
    spi_wr_cmd = 1'b0;
    spi_wr_data = 0;
    cfg_done = 0;
    case(cs)
    IDLE_s: begin
        addr_next = 0;
        if (cfg_start & ~i_spi_busy) begin
            ns = READ_ID_s;
        end
    end
    READ_ID_s: begin
        spi_rd_cmd = 1'b1;
        spi_wr_data = 24'h008001;
        ns = CHECK_ID_s;
    end
    CHECK_ID_s: begin
        if (i_spi_rd_data[7:0] == AD9434_ID) begin
            ns = RD_ROM_s;            
        end
        else if (timeout) ns = IDLE_s;
        else ns = CHECK_ID_s;
    end
    endcase
end

always_comb begin
    timer_ena = cs == CONFIRM_CFG_s;
    timer_clr = cs == IDLE_s;
end
always_ff @(posedge clk) begin
    if (rst | timer_clr) begin
        timer_cnt <= 'h0;
        timeout <= 1'b0;
    end
    else begin
        if (timer_ena) begin
            timer_cnt <= timer_cnt + 1;
            if (&timer_cnt == 1'b1) begin
                timeout <= 1'b1;
                timer_cnt <= 0;
            end
        end
        else begin
            timeout <= 1'b0;
        end

    end
end