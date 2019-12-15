`timescale 1ns/1ps
module ad9517_cfg # (parameter
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

// read ID

localparam AD9517_ID = 8'h53;
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
logic [15:0]   timer_cnt;
logic [6:0]   addr_next, addr;
logic         rom_ena;
logic [MOSI_DATA_WIDTH-1:0] rom_data;

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
    //rom_ena = 1'b0;
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
        spi_wr_data = 24'h008003;
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
        if (~i_spi_busy & spi_cfg_cnt != 6'd63) begin
            ns = RD_ROM_s;
            addr_next = addr + 1;
        end
        else if (~i_spi_busy & spi_cfg_cnt == 6'd63) ns = READ_CFG_s;
    end
    READ_CFG_s: begin
        spi_rd_cmd = 1'b1;
        spi_wr_data = 24'h00801c;
        ns = CONFIRM_CFG_s;
    end
    CONFIRM_CFG_s: begin
        if (i_spi_rd_data[7:0] == 8'h01) begin
            cfg_done = 1;
            ns = IDLE_s;            
        end

        if (timeout) begin
            ns = IDLE_s;
        end
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


always_comb begin
    timer_ena = cs == CONFIRM_CFG_s;
    timer_clr = cs == IDLE_s | cs == RD_ROM_s;
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

spi_config_rom spi_9517_config_rom (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .addra(addr),  // input wire [6 : 0] addra
  .douta(rom_data)  // output wire [31 : 0] douta
);

ila_ad9517 your_instance_name (
	.clk(clk), // input wire clk
	.probe0(cs), // input wire [2:0]  probe0  
	.probe1(spi_wr_data), // input wire [23:0]  probe1 
	.probe2(i_spi_rd_data), // input wire [7:0]  probe2 
	.probe3(spi_wr_cmd), // input wire [0:0]  probe3 
	.probe4(spi_rd_cmd), // input wire [0:0]  probe4 
	.probe5(i_spi_busy), // input wire [0:0]  probe5 
	.probe6(i_cfg_start), // input wire [0:0]  probe6 
	.probe7(timer_cnt), // input wire [5:0]  probe7 
	.probe8(addr), // input wire [6:0]  probe8 
	.probe9(timeout), // input wire [0:0]  probe9 
	.probe10(timer_ena) // input wire [0:0]  probe10
);


endmodule