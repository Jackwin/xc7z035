`define STA 8'b1000_0000
`define STO 8'b0100_0000
`define RD  8'b0010_0000
`define WR  8'b0001_0000
`define ACK 8'b0000_0000
`define NACK 8'b0000_1000
`define IACK 8'b0000_0001

`define PRE_L_ADDR 3'd0
`define PRE_H_ADDR 3'd1
`define CTR_ADDR 3'd2
`define TXR_RXR_ADDR 3'd3
`define CR_SR_ADDR 3'd4

module  ad5339_cfg (
    input logic             sys_clk,
    input logic             sys_rst,

    input logic [6:0]       device_addr,
    input logic [IIC_DATA_WIDTH-1:0]       iic_wr_data,
    input logic             iic_wr_req,
    output logic            iic_wr_ack,

    output logic            iic_wr_done,

    input logic             iic_rd_req,
   // input logic [7:0]       iic_rd_addr,
    output logic            iic_rd_ack,
    output logic            iic_rd_done,
    output logic [IIC_DATA_WIDTH-1:0]      iic_rd_data,
    output logic            iic_busy_o,

    inout reg                  scl,
    inout reg                   sda         
);

parameter IIC_DATA_WIDTH = 16;
parameter SLAVE_ADDR = 7'b0001100; //0C
parameter SCL_FRE = 100; //KHz
parameter WB_CLK_FRE = 20; //MHz

localparam AD5339_POINTER = 8'h1;


localparam  IDLE_s = 5'd0,
            PRE_L_s = 5'd1,
            PRE_H_s = 5'd2,
            WR_CTR_s = 5'd3,
            WR_CMD_s = 5'd4,
            WR_CR_s = 5'd5,
            WR_WAIT_INTR_s = 5'd6,
            WR_CLR_INTR_s = 5'd7,
            WR_SR_s = 5'd8,
            WR_END_s = 5'd9,

            RD_CTR_s = 5'd10,
            RD_CMD_s = 5'd11,
            RD_CR_s = 5'd12,
            RD_WAIT_INTR_s = 5'd13,
            RD_CLR_INTR_s = 5'd14,
            RD_SR_s = 5'd15,
            RD_ACK_s = 5'd16,
            RD_STOP_s = 5'd17,
            RD_DATA1_s = 5'd18,
            RD_DATA2_s = 5'd19,
            RD_END_s = 5'd20;



localparam PRE = 20 * 1000 / (5 * SCL_FRE) - 1;
localparam WR_RD_NUM = IIC_DATA_WIDTH/8;
/*
logic [7:0]     iic_wr_data;
logic [7:0]     iic_wr_addr;
logic [7:0]     iic_rd_data;
logic [7:0]     iic_rd_addr;
logic           iic_wr_req;
logic           iic_rd_req;
logic           iic_wr_ack;
logic           iic_rd_ack;

logic           iic_wr_done;
logic           iic_rd_done;
*/
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

logic [4:0]     cs, ns;
//logic           wr_slave_flag;
logic           wr_cmd_flag;
//logic           wr_addr_flag;
//logic           wr_data_flag;
logic           rd_slave_flag;
logic           rd_cmd_flag;
logic           rd_addr_flag;
logic           rd_data_flag;
logic [1:0]     wr_data_cnt;
logic [2:0]     rd_step;
logic [2:0]     wr_step;
 

always_ff @(posedge sys_clk) begin
    iic_wr_ack <= iic_wr_req & ~iic_wr_ack & (cs == IDLE_s);
end

always_ff @(posedge sys_clk) begin
    iic_rd_ack <= iic_rd_req & (cs == IDLE_s) & ~iic_rd_ack;
end

always_comb begin
    iic_busy_o = iic_wr_go | iic_rd_go;
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        iic_wr_go <= 0;
        iic_rd_go <= 0;
    end
    else begin
        if (iic_wr_req & iic_wr_ack) begin
            iic_wr_go <= 1;
        end 
        else if (cs == WR_END_s) begin
            iic_wr_go <= 0;
        end

        if (iic_rd_req & iic_rd_ack) begin
            iic_rd_go <= 1;
        end
        else if (cs == RD_END_s) begin
            iic_rd_go <= 0;
        end
    end
end


always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        cs <= IDLE_s;
    end
    else begin
        cs <= ns;
    end
end

/* Write: 
    1) write device addres
    2) wait interrupt
    3) read SR register
    4) write the target address
    5) wait interrupt
    6) read SR register
    7) write data 
    8) wait interrupt
    9) read SR register
    
*/
always_comb begin
    ns = cs;
    case(cs) 
        IDLE_s: begin
            if (iic_wr_req | iic_rd_req) begin
                ns = PRE_L_s;
            end
        end
        PRE_L_s: begin
            if (wb_ack) begin
                ns = PRE_H_s;
            end
        end
        PRE_H_s: begin
            if (wb_ack & iic_wr_go) begin
                ns = WR_CTR_s;
            end
            else if (wb_ack & iic_rd_go) begin
                ns = RD_CTR_s;
            end
        end
        WR_CTR_s: begin
            if (wb_ack) begin
               ns = WR_CMD_s;
            end
        end
        WR_CMD_s: begin
            if (wb_ack) begin
                ns = WR_CR_s;
            end
        end
        WR_CR_s: begin
            if (wb_ack) begin
                ns = WR_WAIT_INTR_s;
            end
        end
        WR_WAIT_INTR_s: begin
            if (wb_intr) begin
                ns = WR_CLR_INTR_s;
            end

        end
        WR_CLR_INTR_s: begin
            if (~wb_intr) begin
                ns = WR_SR_s;
            end
        end

        WR_SR_s: begin
            /*
            if (wb_rd_data[7] == 1'b0 & wr_slave_flag & wr_addr_flag & wr_data_flag & wr_data_cnt == WR_RD_NUM) begin
                ns = WR_END_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                ns = WR_CMD_s;
            end
            */
            if (wb_rd_data[7] == 1'b0 & wr_step == 4) begin
                ns = WR_END_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                ns = WR_CMD_s;
            end

        end
        WR_END_s: begin
            ns = IDLE_s;
        end

        RD_CTR_s: begin
            if (wb_ack) begin
               ns = RD_CMD_s;
            end
        end
        RD_CMD_s: begin
            /*
            if (wb_ack & (~(rd_slave_flag & rd_cmd_flag & rd_data_flag))) begin
                ns = RD_CR_s;
            end
            */
            if (wb_ack) begin
                ns = RD_CR_s;
            end   
        end
        RD_CR_s: begin
        /*
            if (wb_intr & (~(rd_slave_flag & rd_cmd_flag & rd_data_flag))) begin
                ns = RD_CMD_s;
            end
            else if (wb_intr) begin
                ns = RD_STOP_s;
            end
        */
            if (wb_ack) begin
                ns = RD_WAIT_INTR_s;
            end

        end
        RD_WAIT_INTR_s: begin
            if (wb_intr) begin
                ns = RD_CLR_INTR_s;
            end
        end

        RD_CLR_INTR_s: begin
            if (~wb_intr & rd_step == 3) begin // master ack
                ns = RD_ACK_s;
            end
            else if (~wb_intr & rd_step == 4) begin
                ns = RD_STOP_s;
            end
            else if (~wb_intr) begin
                ns = RD_SR_s;
            end
        end

        RD_SR_s: begin
        /*
            if (wb_rd_data[7] == 1'b0 & (~(rd_slave_flag & rd_cmd_flag & rd_data_flag)) && wr_rd_cnt == 2) begin
                ns = RD_STOP_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                ns = RD_CMD_s;
            end
            */
            if (wb_rd_data[7] == 1'b0 & rd_step == 3) begin
                ns = RD_WAIT_INTR_s;
            end
            else if (wb_rd_data[7] == 1'b0) begin
                ns = RD_CMD_s;
            end
        end

        RD_ACK_s: begin
            if (wb_ack) begin
                ns = RD_DATA1_s;
            end
        end

        
        RD_DATA1_s: begin
            if (wb_ack) begin
                ns = RD_WAIT_INTR_s;
            end
        end

        
        RD_STOP_s: begin
            if (wb_ack) begin
                ns = RD_DATA2_s;
            end  
        end

        RD_DATA2_s: begin
            if (wb_ack) begin
                ns = RD_END_s;
            end
        end

        RD_END_s: begin
            ns = IDLE_s;
        end
        default: ns = IDLE_s;
    endcase
end

always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
       // wr_slave_flag <= 0;
       // wr_addr_flag <= 0;
      //  wr_data_flag <= 0;
        rd_cmd_flag <= 0;
        rd_data_flag <= 0;
        rd_addr_flag <= 0;
        wb_we <= 0;
        wb_stb <= 0;
        wb_cyc <= 0;
        iic_wr_done <= 0;
        iic_rd_done <= 0;
        wr_data_cnt <= 0;;
    end
    else begin
        case(cs)
            IDLE_s: begin
               // wr_slave_flag <= 0;
                wr_cmd_flag <= 0;
               // wr_addr_flag <= 0;
               // wr_data_flag <= 0;
                rd_cmd_flag <= 0;
                rd_data_flag <= 0;
                rd_addr_flag <= 0;

                wr_data_cnt <= 0;
                rd_step <= 0;
                wr_step <= 0;
                iic_rd_data <= 0;

                wb_addr <= 0;
                wb_wr_data <= 0;
                wb_we <= 0;
                wb_stb <= 0;
                wb_cyc <= 0;
                iic_wr_done <= 0;
                iic_rd_done <= 0;
            end
            PRE_L_s: begin
                wb_addr <= `PRE_L_ADDR;
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
            PRE_H_s: begin
                wb_addr <= `PRE_H_ADDR;
                wb_wr_data <= (PRE & 16'hff00) >> 8;
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
                wb_addr <= `CTR_ADDR;
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
            case(wr_step)
                0: begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= {device_addr,1'b0};
                end
                1: begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= AD5339_POINTER;
                end
                2: begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= iic_wr_data[15:8];
                    wr_data_cnt <= wr_data_cnt + 1'b1;
                end
                3: begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= iic_wr_data[7:0];
                    wr_data_cnt <= wr_data_cnt + 1'b1;
                end
                4: begin
                    wb_addr <= 0;
                    wb_wr_data <= 0;
                end
                default: begin
                    wb_addr <= 0;
                    wb_wr_data <= 0;
                end

            endcase
                /*
                if (~wr_slave_flag) begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= {device_addr,1'b0}; 
                end
                else if (~wr_addr_flag) begin
                    wb_addr <= `TXR_RXR_ADDR;
                    wb_wr_data <= AD5339_POINTER; 
                end
                else if (~wr_data_flag) begin
                    if (wr_data_cnt == 'h0) begin
                        wb_addr <= `TXR_RXR_ADDR;
                        wb_wr_data <= iic_wr_data[7:0];
                        wr_data_cnt <= wr_data_cnt + 1'b1;
                    end
                    else if (wr_data_cnt == 'h1) begin
                        wb_addr <= `TXR_RXR_ADDR;
                        wb_wr_data <= iic_wr_data[7:0];
                        wr_data_cnt <= wr_data_cnt + 1'b1;
                    end

                end
                */
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wr_cmd_flag <= 1;
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end

            
            WR_CR_s: begin
                case(wr_step)
                    0: begin
                        wb_addr <= `CR_SR_ADDR; 
                        wb_wr_data <= `STA | `WR;
                    end
                    1: begin
                        wb_addr <= `CR_SR_ADDR; 
                        wb_wr_data <= `WR;
                    end
                    2: begin
                        wb_addr <= `CR_SR_ADDR; 
                        wb_wr_data <= `WR;
                    end
                    3: begin
                        wb_addr <= `CR_SR_ADDR; 
                        wb_wr_data <= `STO | `WR;
                    end
                    4: begin
                        wb_addr <= 0;
                        wb_wr_data <= 0;
                    end
                    default: begin
                        wb_addr <= 0;
                        wb_wr_data <= 0;
                    end
                endcase

            /*
                if (wr_slave_flag & ~wr_addr_flag & ~wr_data_flag) begin
                    wb_addr <= `CR_SR_ADDR; 
                    wb_wr_data <= `STA | `WR; 
                end
                else if (wr_slave_flag & wr_addr_flag & ~wr_data_flag) begin
                    wb_addr <= `CR_SR_ADDR; 
                    wb_wr_data <= `WR; 
                end
                else if (wr_slave_flag & wr_addr_flag & wr_data_flag & wr_data_cnt == 1) begin
                    wb_addr <= `CR_SR_ADDR; 
                    wb_wr_data <= `WR; 
                end
                else if (wr_slave_flag & wr_addr_flag & wr_data_flag & wr_data_cnt == 2) begin
                    wb_addr <= `CR_SR_ADDR; 
                    wb_wr_data <= `STO | `WR; 
                end
            */
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end

            WR_WAIT_INTR_s: begin
                wb_we <= 0;
                wb_stb <= 0;
                wb_cyc <= 0;
                if (wb_intr) begin
                    wr_step <= wr_step + 1;
                end
                
            end

            WR_CLR_INTR_s: begin
                wb_addr <= `CR_SR_ADDR; 
                wb_wr_data <= `IACK;
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
                wb_addr <= `CR_SR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            WR_END_s: begin
                iic_wr_done <= 1;
            end

            RD_CTR_s: begin
                wb_addr <= `CTR_ADDR;
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
            RD_CMD_s: begin
                case(rd_step)
                    0: begin
                        wb_addr <= `TXR_RXR_ADDR;
                        wb_wr_data <= {device_addr,1'b0}; // select device
                    end
                    1: begin
                        wb_addr <= `TXR_RXR_ADDR;
                        wb_wr_data <= AD5339_POINTER;  // config wr address
                    end
                    2: begin
                        wb_addr <= `TXR_RXR_ADDR;
                        wb_wr_data <= {device_addr,1'b1};  // config rd address
                    end
                    3,4: begin
                        wb_addr <= 0;
                        wb_wr_data <= 0;
                    end

                    default: begin
                        wb_addr <= 0;
                        wb_wr_data <= 0;
                    end
                endcase
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    rd_addr_flag <= 1; 
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            RD_CR_s: begin
                case(rd_step)
                    0: begin
                        wb_addr <= `CR_SR_ADDR;
                        wb_wr_data <= `STA | `WR; 
                    end
                    1: begin
                        wb_addr <= `CR_SR_ADDR;
                        wb_wr_data <= `WR;
                    end
                    2: begin
                        wb_addr <= `CR_SR_ADDR;
                        wb_wr_data <= `STA | `WR;
                    end
                    default: begin
                        wb_addr <= 0;
                        wb_wr_data <= 0;
                    end
                  
                endcase
               
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            RD_WAIT_INTR_s: begin
                wb_we <= 0;
                wb_stb <= 0;
                wb_cyc <= 0;
                if (wb_intr)
                    rd_step <= rd_step + 1;
            end
            RD_CLR_INTR_s: begin
                wb_addr <= `CR_SR_ADDR; 
                wb_wr_data <= `IACK;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 1;
                    wb_stb <= 1;
                    wb_cyc <= 1;
                end
            end
            RD_SR_s: begin
                wb_addr <= `CR_SR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            RD_ACK_s: begin
                wb_addr <= `CR_SR_ADDR;
                wb_wr_data <= `RD | `ACK;
                
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                rd_step <= rd_step + 1;
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end

            
            RD_DATA1_s: begin
                wb_addr <= `TXR_RXR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                iic_rd_data[15:8] <= wb_rd_data;
                if (wb_ack) begin 
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            RD_DATA2_s: begin
                wb_addr <= `TXR_RXR_ADDR;
                wb_we <= 0;
                wb_stb <= 1;
                wb_cyc <= 1;
                iic_rd_data[7:0] <= wb_rd_data;
                if (wb_ack) begin 
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end

            RD_STOP_s: begin
                wb_addr <= `CR_SR_ADDR;
                wb_wr_data <= `RD| `ACK | `STO;
                wb_we <= 1;
                wb_stb <= 1;
                wb_cyc <= 1;
                if (wb_ack) begin
                    wb_we <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end

            RD_END_s: begin
                iic_rd_done <= 1;
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

    .sda_pad_i(sda),
    .sda_pad_o(sda_pad_o),
    .sda_padoen_o(sda_padoen_o) 
);

/*
 OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
 ) scl_OBUFT_inst (
      .O(scl),     // Buffer output (connect directly to top-level port)
      .I(scl_pad_o),     // Buffer input
      .T(scl_padoen_o)      // 3-state enable input 
   );


    OBUFT #(
      .DRIVE(12),   // Specify the output drive strength
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW") // Specify the output slew rate
 ) sda_OBUFT_inst (
      .O(sda),     // Buffer output (connect directly to top-level port)
      .I(sda_pad_o),     // Buffer input
      .T(sda_padoen_o)      // 3-state enable input 
   );
   */

//always_comb begin
assign    scl = ~scl_padoen_o? scl_pad_o : 1'bz;
 assign   scl_pad_i = scl;

assign    sda = ~sda_padoen_o? sda_pad_o : 1'bz;
 assign   sda_pad_i = sda;
//end
/*
ila_ad5339_cfg ila_ad5339_cfg_i (
	.clk(sys_clk), // input wire clk

	.probe0(cs), // input wire [4:0]  probe0  
	.probe1(ns), // input wire [4:0]  probe1 
	.probe2(wb_wr_data), // input wire [7:0]  probe2 
	.probe3(wb_rd_data), // input wire [7:0]  probe3 
	.probe4(wb_addr), // input wire [2:0]  probe4 
	.probe5(rd_step), // input wire [1:0]  probe5 
	.probe6(wb_we), // input wire [0:0]  probe6 
	.probe7(wb_stb), // input wire [0:0]  probe7 
	.probe8(wb_cyc), // input wire [0:0]  probe8 
	.probe9(wb_ack), // input wire [0:0]  probe9 
	.probe10(wb_intr), // input wire [0:0]  probe10 
	.probe11(wr_step), // input wire [1:0]  probe11 
	.probe12(wr_cmd_flag), // input wire [0:0]  probe12 
	.probe13(wr_data_flag), // input wire [0:0]  probe13 
	.probe14(scl_pad_i), // input wire [0:0]  probe14 
	.probe15(scl_padoen_o), // input wire [0:0]  probe15
    .probe16(scl_pad_o), // input wire [0:0]  probe16 
	.probe17(sda_pad_i), // input wire [0:0]  probe17 
	.probe18(sda_pad_o), // input wire [0:0]  probe18 
	.probe19(sda_padoen_o) // input wire [0:0]  probe19
);
*/

endmodule
