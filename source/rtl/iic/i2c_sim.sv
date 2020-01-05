
`define STA 8'h1000_0000
`define STO 8'h0100_0000
`define RD  8'h0010_0000
`define WR  8'h0001_0000
module i2c_sim();

localparam  CLK_PERIOD = 50; //20M
logic       sys_clk;
logic       sys_rst;

initial begin
    clk = 0;
    forever begin
        #CLK_PERIOD/2 sys_clk = ~sys_clk;
    end
end

initial begin
    sys_rst = 1;
    #140;
    sys_rst = 0;
end

localparam  IDLE_s = 3'b000,
            CFG_PRE_L_s = 3'b001,
            CFG_PRE_H_s = 3'b010,
            CFG_CTR_s = 3'b011,
            CFG_TXR_s = 3'b100,
            CFG_RXR_s = 3'b101,
            CFG_CR_s = 3'b110,
            CFG_SR_s = 3'b111;

localparam  WR_IDLE_s = 4'd0,
            WR_PRE_L_s = 4'd1,
            WR_PRE_H_s = 4'd2,
            WR_CTR_s = 4'd3,
            WR_CMD_s = 4'd4,
            WR_CR_s = 4'd5,
            WR_SR_s = 4'd6,
            WR_DATA_s = 4'd7,
            WR_END_s = 4'd8;

localparam  RD_IDLE_s = 4'd0,
            RD_PRE_L_s = 4'd1,
            RD_PRE_H_s = 4'd2,
            RD_CTR_s = 4'd3,
            RD_CMD_s = 4'd4,
            RD_CR_s = 4'd5,
            RD_SR_s = 4'd6,
            RD_DATA_s = 4'd7,
            RD_CR2_s = 4'd8,
            RD_SR2_s = 4'd9;



localparam SCL_FRE = 100; //KHz
localparam WB_CLK_FRE = 20; //MHz
localparam PRE = 20 * 1000 / (5 * SCL_FRE) - 1; 
localparam SLAVE_ADDR = 7'b0001100;

localparam PRE_L_ADDR = 3'd0;
localparam PRE_H_ADDR = 3'd1;
localparam CTR_ADDR = 3'd2;
localparam TXR_RXR_ADDR = 3'd3;
localparam CR_SR_ADDR = 3'd4;


logic           iic_wr_strobe;
logic [7:0]     iic_wr_data;
logic [7:0]     iic_rd_data;
logic           iic_wr_ack;
logic           iic_wr_done;
logic           iic_rd_done;
logic           iic_wr_go;
logic           iic_rd_go;

logic [2:0]     wb_addr; // control registers address
logic [7:0]     wb_wr_data;
logic [7:0]     wb_rd_data;
logic           wb_we;
logic           wb_stb;
logic           wb_cyc;
logic           wb_ack;
logic           wb_intr;

logic           scl_pad_i;
logic           scl_pad_o;
logic           scl_padoen_o;

logic           sda_pad_i;
logic           sda_pad_o;
logic           sda_padoen_o;

logic [2:0]     cs, ns;
logic [2:0]     wr_cs, wr_ns;
logic [2:0]     rd_cs, rd_ns;
logic [1:0]     cnt;
logic           wr_cmd_flag;
logic           rd_cmd_flag
logic           rd_data_flag;

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        iic_wr_ack <= 0;
    end
    else begin
        iic_wr_ack <= iic_wr_strobe & ~iic_wr_ack & (cs == IDLE_s);
    end
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        iic_wr_go <= 0;
        iic_rd_go <= 0;
    end
    else begin
        if (iic_wr_strobe & (cs == IDLE_s)) begin
            iic_wr_go <= 1;
        end
        else if (cs == END_s) begin
            iic_wr_go <= 0;
        end

        if (iic_rd_strobe & (cs == IDLE_s)) begin
            iic_rd_go <= 1;
        end
        else if (cs == END_s) begin
            iic_rd_go <= 0;
        end
    end
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        wr_cs <= WR_IDLE_s;
    end
    else begin
        wr_cs <= wr_ns;
    end
end

always_comb begin
    wr_ns = wr_cs;
    case(wr_cs) 
        WR_IDLE_s: begin
            if (iic_wr_strobe) begin
                wr_ns = WR_PRE_L_s;
            end
        end
        WR_PRE_L_s: begin
            if (wb_ack) begin
                wr_ns = WR_PRE_H_s;
            end
        end
        WR_PRE_H_s: begin
            if (wb_ack) begin
                wr_ns = WR_CTR_s;
            end
        end
        WR_CTR_s: begin
            if (wb_ack) begin
               wr_ns = WR_CMD_s；
            end
        end
        WR_CMD_s: begin
            if (wb_ack) begin
                wr_ns = WR_CR_s;
            end
        end
        WR_CR_s: begin
            if (wb_intr) begin
                wr_ns = WR_SR_s;
            end
        end
        WR_SR_s: begin
            if (wb_rd_data[7] == 1'b0 & wr_cmd_flag) begin
                wr_ns = WR_END_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                wr_ns = WR_DATA_s;
            end
        end
        WR_DATA_s: begin
            if (wb_ack) begin
                wr_ns = WR_CR_s;
            end
        end
        WR_END_s: begin
            wr_ns = WR_IDLE_s;
        end
        default: wr_ns = WR_IDLE_s;
    endcase
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        wr_cmd_flag <= 0;
        wr_data_flag <= 0;
        wb_we <= 0;
        wb_stb <= 0;
        wb_cyc <= 0;
        iic_wr_done <= 0;
    end
    else begin
        case(wr_cs)
            WR_IDLE_s: begin
                wr_cmd_flag <= 0;
                wb_addr <= 0;
                wb_wr_data <= 0;
                wb_we <= 0;
                wb_stb <= 0;
                wb_cyc <= 0;
                iic_wr_done <= 0;
            end
            WR_PRE_L_s: begin
                wb_addr <= PRE_L_ADDR;
                wb_wr_data <= PRE & 8'hff;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_PRE_H_s: begin
                wb_addr <= PRE_H_ADDR;
                wb_wr_data <= (PRE & 8'hff00) >> 8;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CTR_s: begin
                wb_addr <= CTR_ADDR;
                wb_wr_data <= 8'hc0; // Enable the core and enable the interrupt
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CMD_s: begin
                wr_cmd_flag <= 1;
                wb_addr <= TXR_RXR_ADDR;
                wb_wr_data <= {SLAVE_ADDR,1'b0}; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CR_s: begin
                wb_addr <= CR_SR_ADDR;
                wb_wr_data <= `STA | `WR; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_SR_s: begin
                wb_addr <= CR_SR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_DATA_s: begin
                wb_addr <= TXR_RXR_ADDR;
                wb_wr_data <= iic_wr_data; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_END_s: begin
                iic_wr_done <= 0;
            end
        endcase
    end
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        rd_cs <= RD_IDLE_s;
    end
    else begin
        rd_cs <= rd_ns;
    end
end

always_comb begin
    rd_ns = rd_cs;
    case(rd_cs) 
        RD_IDLE_s: begin
            if (iic_rd_strobe) begin
                rd_ns = RD_PRE_L_s;
            end
        end
        RD_PRE_L_s: begin
            if (wb_ack) begin
                rd_ns = RD_PRE_H_s;
            end
        end
        RD_PRE_H_s: begin
            if (wb_ack) begin
                rd_ns = RD_CTR_s;
            end
        end
        RD_CTR_s: begin
            if (wb_ack) begin
               rd_ns = RD_CMD_s；
            end
        end
        RD_CMD_s: begin
            if (wb_ack) begin
                rd_ns = RD_CR_s;
            end
        end
        RD_CR_s: begin
            if (wb_intr) begin
                rd_ns = RD_SR_s;
            end
        end
        RD_SR_s: begin
            if (wb_rd_data[7] == 1'b0 & rd_cmd_flag) begin
                rd_ns = RD_END_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                rd_ns = RD_DATA_s;
            end
        end
        RD_DATA_s: begin
            if (wb_ack) begin
                rd_ns = RD_CR_s;
            end
        end
        RD_END_s: begin
            rd_ns = RD_IDLE_s;
        end
        default: rd_ns = RD_IDLE_s;
    endcase
end
always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        rd_cmd_flag <= 0;
        rd_data_flag <= 0;
        wb_we <= 0;
        wb_stb <= 0;
        wb_cyc <= 0;
        iic_rd_done <= 0;
    end
    else begin
        case(wr_cs)
            WR_IDLE_s: begin
                wr_cmd_flag <= 0;
                wb_addr <= 0;
                wb_wr_data <= 0;
                wb_we <= 0;
                wb_stb <= 0;
                wb_cyc <= 0;
                iic_wr_done <= 0;
            end
            WR_PRE_L_s: begin
                wb_addr <= PRE_L_ADDR;
                wb_wr_data <= PRE & 8'hff;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_PRE_H_s: begin
                wb_addr <= PRE_H_ADDR;
                wb_wr_data <= (PRE & 8'hff00) >> 8;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CTR_s: begin
                wb_addr <= CTR_ADDR;
                wb_wr_data <= 8'hc0; // Enable the core and enable the interrupt
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CMD_s: begin
                wr_cmd_flag <= 1;
                wb_addr <= TXR_RXR_ADDR;
                wb_wr_data <= {SLAVE_ADDR,1'b0}; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_CR_s: begin
                wb_addr <= CR_SR_ADDR;
                wb_wr_data <= `STA | `WR; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_SR_s: begin
                wb_addr <= CR_SR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_DATA_s: begin
                wb_addr <= TXR_RXR_ADDR;
                wb_wr_data <= iic_wr_data; 
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_END_s: begin
                iic_wr_done <= 0;
            end
        endcase
    end
end










i2c_master_top  #(
    .ARST_LVL(1'b1)
) i2c_master(
    .wb_clk_i(sys_clk),
    .wb_rst_i(sys_rst),
    .arst_i(sys_rst),
    .wb_adr_i(wb_addr),
    .wb_dat_i(wb_wr_data),
    .wb_dat_o(wb_rd_data),
    .wb_we_i(wb_we),
    .wb_stb_i(wb_stb),
    .wb_cyc_i(wb_cyc),
    .wb_ack_o(wb_ack),
    .wb_inta_o(wb_intr),

    .scl_pad_i(scl_pad_i),
    .scl_pad_o(scl_pad_o),
    .scl_padoen_o(scl_padoen_o),

    .sda_pad_i(sda_pad_i),
    .sda_pad_o(sda_pad_o),
    .sda_padoen_o(sda_padoen_o)

);






endmodule