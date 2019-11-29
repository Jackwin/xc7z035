`timescale 1ns/1ps
module ad9517_cfg (
    input           clk,
    input           rst,

    output          o_spi_wr_cmd,
    output          o_spi_rd_cmd,
    output [23:0]   o_spi_wr_data,
    input  [7:0]    i_spi_rd_data,
    input           i_spi_busy,
    input           i_cfg_start

);

// read ID

localparam AD9517_ID = 8'h53;
logic [2:0]     cs, ns;
localparam  IDLE_s = 3'd0,
            READ_ID_s = 3'd1,
            CHECK_ID_s = 3'd2,
            RD_ROM_s = 3'd3,
            DELAY_s = 3'd4,
            SPI_CFG_s = 3'd5,
            SPI_CFG_ACK_s = 3'd6;
reg         cfg_start_r, cfg_start;
reg         timeout;
reg [5:0]   timer_cnt;
reg [6:0]   addr_next, addr;
reg         rom_ena;
wire [31:0] rom_data;

reg         spi_wr_cmd;
reg         spi_rd_cmd;
reg [23:0]  spi_wr_data;
reg [15:0]  spi_rd_data;
reg [5:0]   spi_cfg_cnt, spi_cfg_cnt_next;  

assign o_spi_wr_cmd = spi_wr_cmd;
assign o_spi_rd_cmd = spi_rd_cmd;
assign o_spi_wr_data = spi_wr_data;


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
    rom_ena = 1'b0;
    spi_rd_cmd = 1'b0;
    spi_wr_cmd = 1'b0;
    case(cs)
    IDLE_s: begin
        if (cfg_start & ~i_spi_busy) begin
            ns = READ_ID_s;
        end
    end
    READ_ID_s: begin
        spi_rd_cmd = 1'b1;
        spi_wr_data = 24'h100300;
        ns = CHECK_ID_s;
    end
    CHECK_ID_s: begin
        if (i_spi_rd_data[7:0] == AD9517_ID) begin
            ns = RD_ROM_s;            
        end
        else if (timeout) ns = IDLE_s;
        else ns = CHECK_ID_s;
    end
    RD_ROM_s: begin
        addr_next = addr + 1;
        spi_cfg_cnt_next = spi_cfg_cnt + 1;
        rom_ena = 1'b1;
        ns = DELAY_s;
    end
    DELAY_s: begin
        if (~i_spi_busy) ns = SPI_CFG_s;
    end
    SPI_CFG_s: begin
        spi_wr_cmd = 1'b1;
        spi_wr_data = {3'b000,rom_data[28:8]};
        ns = SPI_CFG_ACK_s;
    end
    SPI_CFG_ACK_s: begin
        if (~i_spi_busy & spi_cfg_cnt != 6'd62) ns = RD_ROM_s;
        else if (~i_spi_busy & spi_cfg_cnt != 6'd62) ns = IDLE_s;
    end

    default:
        ns = IDLE_s;
    endcase

end

//always_ff @(posedge clk) begin
    
//    if (cs == CHECK_ID_s) begin
//        spi_rd_cmd <= 1'b1;
//        spi_rd_data <= 16'h1003;
//    end


//end

wire timer_ena = cs == SPI_CFG_s;
always_ff @(posedge clk) begin
    if (rst) begin
        timer_cnt <= 'h0;
        timeout <= 1'b0;
    end
    else begin
        if (timer_ena) begin
            timer_cnt <= timer_cnt + 1;
            if (&timer_cnt == 1'b1) begin
                timeout <= 1'b1;
            end
        end
        else begin
            timeout <= 1'b0;
        end

    end
end

spi_config_rom spi_9517_config_rom (
  .clka(clk),    // input wire clka
  .ena(rom_ena),      // input wire ena
  .addra(addr),  // input wire [6 : 0] addra
  .douta(rom_data)  // output wire [31 : 0] douta
);


endmodule