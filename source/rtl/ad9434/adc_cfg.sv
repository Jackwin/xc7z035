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
    input  logic                        i_cfg_start,
    output logic                        o_cfg_go,
    output logic                        o_cfg_done

);

localparam AD9434_ID = 8'h6A;
localparam AD9434_ID_ADDR = 8'h1;
localparam TEST_IO = 8'h00;
localparam TEST_IO_ADDR = 8'h0D;
localparam AIN_CFG = 8'h08; // Enable analog input
localparam AIN_CFG_ADDR = 8'h0F;
localparam OUTPUT_MODE = 8'h18; //Enable output, DDR enable, offset binary
localparam OUTPUT_MODE_ADDR = 8'h14;
localparam OUTPUT_ADJUST = 8'h1; // LVDS 3.5mA,
localparam OUTPUT_ADJUST_ADDR = 8'h15;
localparam OUTPUT_PHASE = 8'h0; // output clock polarity non-inverted
localparam OUTPUT_PHASE_ADDR = 8'h16;
localparam FLEX_OUTPUT_DELAY = 8'h0;
localparam FLEX_OUTPUT_DELAY_ADDR = 8'h17;
localparam FLEX_VREF = 8'h1C; //internal Vref, 1.6V input voltage range
localparam FLEX_VREF_ADDR = 8'h18;
localparam OVR_CFG = 8'h03; //OVR PIN 21,22
localparam OVR_CFG_ADDR = 8'h2A;
localparam INPUT_COUPLING = 8'h00; // AC coupling
localparam INPUT_COUPLING_ADDR = 8'h2C;
localparam DEVICE_UPDATE = 8'h01; // Update the data to the registers
localparam DEVICE_UPDATE_ADDR = 8'hFF;
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

logic           cfg_start_r, cfg_start;
logic           timeout;
logic [15:0]    timer_cnt;
logic [3:0]     addr_next, addr;
logic           spi_wr_cmd;
logic           spi_rd_cmd;
logic [MOSI_DATA_WIDTH-1:0]  spi_wr_data;
logic [15:0]    spi_rd_data;
logic [3:0]     spi_cfg_cnt, spi_cfg_cnt_next;
logic           cfg_done;
logic           timer_ena;
logic           timer_clr;
logic [23:0]    rom_data;

always_comb begin
    o_spi_wr_cmd = spi_wr_cmd;
    o_spi_rd_cmd = spi_rd_cmd;
    o_spi_wr_data = spi_wr_data;
    o_cfg_done = cfg_done;
end

/*
always_ff @(posedge clk) begin
    cfg_start_r <= i_cfg_start;
    cfg_start <= ~cfg_start_r & i_cfg_start;
end
*/

always_ff @(posedge clk) begin
    cfg_start <= i_cfg_start;
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
        if (cfg_start & ~i_spi_busy) begin
            ns = READ_ID_s;
        end
    end
    READ_ID_s: begin
        spi_rd_cmd = 1'b1;
        spi_wr_data = {16'h0080, AD9434_ID_ADDR};
        ns = CHECK_ID_s;
    end
    CHECK_ID_s: begin
        if (i_spi_rd_data[7:0] == AD9434_ID) begin
            //ns = IDLE_s;
            ns = RD_ROM_s;
        end
        else if (timeout) ns = IDLE_s;
        else ns = CHECK_ID_s;
    end

    RD_ROM_s: begin
        spi_cfg_cnt_next = spi_cfg_cnt + 1;
        //rom_ena = 1'b1;
        ns = DELAY_s;
    end
    DELAY_s: begin
        if (~i_spi_busy) ns = SPI_CFG_s;
    end
    SPI_CFG_s: begin
        spi_wr_cmd = 1'b1;
        spi_wr_data = rom_data;
        //spi_wr_data = 0;
        if (~i_spi_busy)
            ns = SPI_CFG_ACK_s;
    end
    SPI_CFG_ACK_s: begin
        if (~i_spi_busy & spi_cfg_cnt != 4'd14) begin //9
            ns = RD_ROM_s;
            addr_next = addr + 1;
        end
        else if (~i_spi_busy & spi_cfg_cnt == 4'd14) ns = READ_CFG_s;//9
    end
    READ_CFG_s: begin
        spi_rd_cmd = 1'b1;
        spi_wr_data = 24'h00802A;
        //spi_wr_data = {16'h0080, AD9434_ID_ADDR};
        ns = CONFIRM_CFG_s;
    end
    CONFIRM_CFG_s: begin
        if (i_spi_rd_data[7:0] == 8'h03) begin
        //if (i_spi_rd_data[7:0] == AD9434_ID) begin
            cfg_done = 1;
            ns = IDLE_s;            
        end

        if (timeout) begin
            ns = READ_CFG_s;
        end
    end
    default: ns = IDLE_s;
    endcase
end


always_comb begin
    o_cfg_go = cs != IDLE_s;
    timer_ena = (cs == CONFIRM_CFG_s) | (cs == CHECK_ID_s);
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

ad9434_cfg_rom ad9434_cfg_rom_i (
  .clka(clk),    
  .ena(1'b1),      
  .addra(addr),  
  .douta(rom_data)  
);


ila_ad9434 ila_ad9434_i (
	.clk(clk), // input wire clk
	.probe0(spi_wr_data), // input wire [23:0]  probe0  
	.probe1(i_spi_rd_data), // input wire [7:0]  probe1 
	.probe2(spi_wr_cmd), // input wire [0:0]  probe2 
	.probe3(spi_rd_cmd), // input wire [0:0]  probe3 
	.probe4(i_spi_busy), // input wire [0:0]  probe4 
	.probe5(i_cfg_start), // input wire [0:0]  probe5 
	.probe6(cfg_done), // input wire [0:0]  probe6 
	.probe7(addr), // input wire [3:0]  probe7 
	.probe8(rom_data), // input wire [23:0]  probe8 
	.probe9(timeout), // input wire [0:0]  probe9 
	.probe10(timer_ena), // input wire [0:0]  probe10
    .probe11(cs) // input wire [1:0]  probe11
);

endmodule