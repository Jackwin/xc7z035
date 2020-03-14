
`timescale 1ns/1ps

module datamover_ctrl (
    input           clk,
    input           rst,
    
    //read cmd interface 
    input [31:0]    i_rd_cmd_data,
    input           i_rd_cmd_req,
    output          o_rd_cmd_ack,
    
    //write cmd interface 
    input [31:0]    i_s2mm_wr_cmd_addr,
    input [22:0]    i_s2mm_wr_cmd_length,
    input           i_wr_cmd_req,
    output logic    o_wr_cmd_ack,
    
    //read data interface
    input           i_rd_ready,
    output          o_rd_valid,
    output          o_rd_last,
    output [63:0]   o_rd_data,
    
    //write data interface
    input           i_wr_valid,
    input  [63:0]   i_wr_data,
    output logic    o_wr_ready,
    output logic    o_write_finish,

    
    //AXI4 read addr interface
    input           hp0_arready,
    output          hp0_arvalid,
    output [3:0]    hp0_arid,
    output [31:0]   hp0_araddr,
    output [7:0]    hp0_arlen,
    output [2:0]    hp0_arsize,
    output [1:0]    hp0_arburst,
    output [2:0]    hp0_arprot,
    output [3:0]    hp0_arcache,
    //output [3:0]    hp0_aruser,
   
    //AXI4 read data interface 
    input [63:0]    hp0_rdata,
    input [1:0]     hp0_rresp,
    input           hp0_rlast,
    input           hp0_rvalid,
    output          hp0_rready,

    //AXI4 write addr interface
    input           hp0_awready,
    output          hp0_awvalid,
    output [3:0]    hp0_awid,
    output [31:0]   hp0_awaddr,
    output [3:0]    hp0_awlen,
    output [2:0]    hp0_awsize,
    output [1:0]    hp0_awburst,
    output [2:0]    hp0_awprot,
    output [3:0]    hp0_awcache,
   // output [3:0]    hp0_awuser,   

    //AXI4 write data interface
    output [63:0]   hp0_wdata,
    output [15:0]   hp0_wstrb,
    output          hp0_wlast,
    output          hp0_wvalid,
    input           hp0_wready,

    input [1:0]     hp0_bresp,
    input           hp0_bvalid,
    output          hp0_bready

);

logic           user_mm2s_cmd_tvalid;
logic           user_mm2s_cmd_tready;
logic [71:0]    user_mm2s_cmd_tdata;
logic [63:0]    user_mm2s_tdata;
logic [7:0]     user_mm2s_tkeep;
logic           user_mm2s_tlast;
logic           user_mm2s_tvalid;
logic           user_mm2s_tready;

logic           user_s2mm_cmd_tvalid;
logic           user_s2mm_cmd_tready;
logic [71:0]    user_s2mm_cmd_tdata;
logic [63:0]    user_s2mm_tdata;
logic [7:0]     user_s2mm_tkeep;
logic           user_s2mm_tlast;
logic           user_s2mm_tvalid;
logic           user_s2mm_tready;

logic           user_s2mm_sts_tvalid;
logic           user_s2mm_sts_tready;
logic [7:0]     user_s2mm_sts_tdata;
logic           user_s2mm_sts_tkeep;
logic           user_s2mm_sts_tlast;

//FIFO signals
logic           fifo_s2mm_rd_en;
logic           fifo_s2mm_wr_en;
logic           fifo_s2mm_full;
logic           fifo_s2mm_empty;
  
logic [63:0]    fifo_s2mm_din;        
logic [63:0]    fifo_s2mm_dout; 

// s2mm write cmd
logic   wr_cmd_ack;
logic   wr_cmd_ena;
logic   s2mm_wr_done;

localparam   WR_EOF_VAL = 4'b1101;

always_comb begin
    fifo_s2mm_din = i_wr_data;
    fifo_s2mm_wr_en = i_wr_valid;
    o_wr_ready = ~fifo_s2mm_full;

    fifo_s2mm_rd_en = hp0_wready & ~fifo_s2mm_empty;
    //hp0_wdata = fifo_s2mm_dout;
   // hp0_wlast = 0;
end

always_comb begin
    o_wr_cmd_ack = wr_cmd_ack;
end

logic [20:0]    s2mm_wr_cmd_num;
logic [2:0]     s2mm_last_wr_cmd_byte_num;
logic [31:0]    s2mm_wr_start_addr;
logic           s2mm_wr_last_btt_flag;
logic [23:0]    s2mm_wr_length;

always_ff @(posedge clk) begin
    if (rst) begin
        s2mm_wr_cmd_num <= 0;
        s2mm_last_wr_cmd_byte_num <= 0;
        s2mm_wr_start_addr <= 0;
    end
    else begin
        if (i_wr_cmd_req & wr_cmd_ack) begin
            s2mm_wr_start_addr <= i_s2mm_wr_cmd_addr;
            s2mm_wr_length = i_s2mm_wr_cmd_length;
            s2mm_wr_cmd_num <= i_s2mm_wr_cmd_length[23:8] + |i_s2mm_wr_cmd_length[7:0];
            s2mm_last_wr_cmd_byte_num <= i_s2mm_wr_cmd_length[2:0];
            s2mm_wr_last_btt_flag <= |i_s2mm_wr_cmd_length[2:0];
        end
    end
end
always_ff @(posedge clk) begin
    if (rst) begin
        s2mm_wr_done <= 0;
    end
    else begin
        if (s2mm_wr_done) s2mm_wr_done <= 0;
        else if (user_s2mm_sts_tvalid & (user_s2mm_cmd_tdata[3:0] == WR_EOF_VAL) & (&user_s2mm_sts_tkeep == 1)) begin
            s2mm_wr_done <= 1;
        end
    end
end
always_ff @(posedge clk) begin
    if (rst) begin
    	wr_cmd_ack <= 1'b0;
        wr_cmd_ena   <= 1'b1;
    end
    else begin
        if (s2mm_wr_done)
            wr_cmd_ena <= 1'b1;
        else if(wr_cmd_ack)
            wr_cmd_ena <= 1'b0;
                
        if (wr_cmd_ack)
            wr_cmd_ack <= 1'b0;
        else if (i_wr_cmd_req & wr_cmd_ena)
            wr_cmd_ack <= 1'b1;        
    end
end

logic           s2mm_wr_eof;
logic [31:0]    s2mm_wr_saddr;
logic [7:0]     s2mm_wr_btt;
logic [15:0]    s2mm_wr_cmd_cnt;
logic           s2mm_wr_cmd_valid;
always_comb begin
    user_s2mm_cmd_tdata = {4'd0, s2mm_wr_eof, s2mm_wr_saddr, 1'b0, 8'd1, 15'd0, s2mm_wr_btt};
end
    

always_ff @(posedge clk) begin
    if (rst) begin
        s2mm_wr_cmd_valid <= 0;
        user_s2mm_cmd_tvalid <= 0;
        s2mm_wr_cmd_cnt <= 0;
    end
    else begin
        if (i_wr_cmd_req & wr_cmd_ack) begin
            if (i_s2mm_wr_cmd_length == 0) begin // data length equals to 0, no s2mm write operation
                s2mm_wr_cmd_valid <= 0;
            end
            else begin
                s2mm_wr_cmd_valid <= 1;
            end
        end
        else if ((s2mm_wr_cmd_cnt == s2mm_wr_cmd_num - 1) & user_s2mm_cmd_tready) begin
            s2mm_wr_cmd_valid <= 0;
        end


        if (s2mm_wr_cmd_valid & user_s2mm_cmd_tready) begin
            if (s2mm_wr_cmd_cnt == s2mm_wr_cmd_num - 1) begin
                s2mm_wr_cmd_cnt <= 0;
            end
            else begin
                s2mm_wr_cmd_cnt <= s2mm_wr_cmd_cnt + 1;
            end
        end

        if (user_s2mm_cmd_tready) begin
            user_s2mm_cmd_tvalid <= s2mm_wr_cmd_valid;
        end
    end
end

logic           s2mm_wr_eof;
logic [31:0]    s2mm_wr_saddr;
logic [7:0]     s2mm_wr_btt;
always_ff @(posedge clk) begin
    if (rst) begin
        s2mm_wr_eof <= 0;
        s2mm_wr_saddr <= 0;
        s2mm_wr_btt <= 0;
    end
    else begin
        if (s2mm_wr_cmd_valid & user_s2mm_cmd_tready) begin
            if (s2mm_wr_cmd_cnt == 0) begin
                s2mm_wr_saddr <= s2mm_wr_start_addr;
            end
            else begin
                s2mm_wr_saddr <= s2mm_wr_saddr + 32'd256;
            end

            if (s2mm_wr_last_btt_flag && s2mm_wr_cmd_cnt == s2mm_wr_cmd_num - 1) begin
                s2mm_wr_btt <= s2mm_wr_length[7:0];
            end
            else begin
                s2mm_wr_btt <= 8'd256;
            end

            if (s2mm_wr_cmd_cnt == s2mm_wr_cmd_num - 1) begin
                s2mm_wr_eof <= WR_EOF_VAL;
            end
            else begin
                s2mm_wr_eof <= 0;
            end
            
        end
        else if (user_s2mm_cmd_tready) begin
            s2mm_wr_eof <= 0;
        end
    end
end

// ----------------- Data logics --------------------------------------
// Move data from FIFO to memory, which is called as s2mm write

logic [15:0]    s2mm_wr_burst_cnt; // the number of burst and the burst length is 32. 8B*32 = 256B
logic [2:0]     s2mm_wr_data_cnt;
logic [7:0]     s2mm_wr_last_btt;

always_comb begin
    s2mm_wr_last_btt = i_s2mm_wr_cmd_length[7:0];
end

always_ff @(posedge clk) begin
    if (rst) begin
        s2mm_wr_burst_cnt <= 0;
        user_s2mm_tvalid <= 0;
        user_s2mm_tkeep <= 0;
    end
    else begin
        if (fifo_s2mm_rd_en) begin
            if (s2mm_wr_burst_cnt == s2mm_wr_cmd_num - 1 & s2mm_wr_data_cnt == (s2mm_last_wr_cmd_byte_num - 1)) begin // The last write
                user_s2mm_tvalid <= 0;
            end
            else begin
                user_s2mm_tvalid <= 1;
            end

            if (s2mm_wr_burst_cnt == (s2mm_wr_cmd_num - 1) & s2mm_wr_data_cnt == (s2mm_last_wr_cmd_byte_num - 1)) begin
                s2mm_wr_burst_cnt <= 0;
                s2mm_wr_data_cnt <= 0;
            end
            else if (s2mm_wr_burst_cnt != (s2mm_wr_cmd_num - 1) & s2mm_wr_data_cnt == 7) begin // one burst operation equals to 8 wr_data
                s2mm_wr_burst_cnt <= s2mm_wr_burst_cnt + 1;
                s2mm_wr_data_cnt <= 0;
            end
            else begin
                s2mm_wr_data_cnt <= s2mm_wr_data_cnt + 1;
            end

            if (s2mm_wr_burst_cnt == (s2mm_wr_cmd_num - 1) & s2mm_wr_data_cnt == s2mm_wr_last_btt[7:3] & s2mm_wr_last_btt[2:0] != 0) begin
                case(s2mm_wr_last_btt[2:0]) 		                  
                    1: user_s2mm_tkeep <= 8'h01;
                    2: user_s2mm_tkeep <= 8'h03;
                    3: user_s2mm_tkeep <= 8'h07;
                    4: user_s2mm_tkeep <= 8'h0f;
                    5: user_s2mm_tkeep <= 8'h1f;
                    6: user_s2mm_tkeep <= 8'h3f;
                    7: user_s2mm_tkeep <= 8'h7f;
                    default: user_s2mm_tkeep <= 8'h0;
    		    endcase
            end
            else begin
                user_s2mm_tkeep <= 8'h7f;   
            end
        end
    end
end


datamover datamover_hp0 (
    .m_axi_mm2s_aclk(clk),                        // input wire m_axi_mm2s_aclk
    .m_axi_mm2s_aresetn(~rst),                  // input wire m_axi_mm2s_aresetn
    // AXI4 interface
    .mm2s_err(),                                      // output wire mm2s_err
    .m_axis_mm2s_cmdsts_aclk(clk),        // input wire m_axis_mm2s_cmdsts_aclk
    .m_axis_mm2s_cmdsts_aresetn(~rst),  // input wire m_axis_mm2s_cmdsts_aresetn
    
    .m_axis_mm2s_sts_tvalid(),          // output wire m_axis_mm2s_sts_tvalid
    .m_axis_mm2s_sts_tready(1'b1),          // input wire m_axis_mm2s_sts_tready
    .m_axis_mm2s_sts_tdata(),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
    .m_axis_mm2s_sts_tkeep(),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
    .m_axis_mm2s_sts_tlast(),            // output wire m_axis_mm2s_sts_tlast

    //AXI4 read addr interface

    .m_axi_mm2s_arid(hp0_arid),                        // output wire [3 : 0] m_axi_mm2s_arid
    .m_axi_mm2s_araddr(hp0_araddr),                    // output wire [31 : 0] m_axi_mm2s_araddr
    .m_axi_mm2s_arlen(hp0_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
    .m_axi_mm2s_arsize(hp0_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
    .m_axi_mm2s_arburst(hp0_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
    .m_axi_mm2s_arprot(hp0_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
    .m_axi_mm2s_arcache(hp0_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
    .m_axi_mm2s_aruser(),                    // output wire [3 : 0] m_axi_mm2s_aruser
    .m_axi_mm2s_arvalid(hp0_arvalid),                  // output wire m_axi_mm2s_arvalid
    .m_axi_mm2s_arready(hp0_arready),                  // input wire m_axi_mm2s_arready

    .m_axi_mm2s_rdata(hp0_rdata),                      // input wire [63 : 0] m_axi_mm2s_rdata
    .m_axi_mm2s_rresp(hp0_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
    .m_axi_mm2s_rlast(hp0_rlast),                      // input wire m_axi_mm2s_rlast
    .m_axi_mm2s_rvalid(hp0_rvalid),                    // input wire m_axi_mm2s_rvalid
    .m_axi_mm2s_rready(hp0_rready),                    // output wire m_axi_mm2s_rready
    // User interface
    
    .s_axis_mm2s_cmd_tvalid(user_mm2s_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
    .s_axis_mm2s_cmd_tready(user_mm2s_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
    .s_axis_mm2s_cmd_tdata(user_mm2s_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata

    .m_axis_mm2s_tdata(user_mm2s_tdata),                    // output wire [63 : 0] m_axis_mm2s_tdata
    .m_axis_mm2s_tkeep(user_mm2s_tkeep),                    // output wire [7 : 0] m_axis_mm2s_tkeep
    .m_axis_mm2s_tlast(user_mm2s_tlast),                    // output wire m_axis_mm2s_tlast
    .m_axis_mm2s_tvalid(user_mm2s_tvalid),                  // output wire m_axis_mm2s_tvalid
    .m_axis_mm2s_tready(user_mm2s_tready),                  // input wire m_axis_mm2s_tready
    // AXI4 interface
    .m_axi_s2mm_aclk(clk),                        // input wire m_axi_s2mm_aclk
    .m_axi_s2mm_aresetn(~rst),                  // input wire m_axi_s2mm_aresetn
    .s2mm_err(),                                      // output wire s2mm_err
    .m_axis_s2mm_cmdsts_awclk(clk),      // input wire m_axis_s2mm_cmdsts_awclk
    .m_axis_s2mm_cmdsts_aresetn(~rst),  // input wire m_axis_s2mm_cmdsts_aresetn
   
    .m_axis_s2mm_sts_tvalid(user_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
    .m_axis_s2mm_sts_tready(user_s2mm_sts_tready),          // input wire m_axis_s2mm_sts_tready
    .m_axis_s2mm_sts_tdata(user_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
    .m_axis_s2mm_sts_tkeep(user_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
    .m_axis_s2mm_sts_tlast(user_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast
    // AXI4 addr interface
   
    .m_axi_s2mm_awid(hp0_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
    .m_axi_s2mm_awaddr(hp0_awaddr),                    // output wire [31 : 0] m_axi_s2mm_awaddr
    .m_axi_s2mm_awlen(hp0_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
    .m_axi_s2mm_awsize(hp0_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
    .m_axi_s2mm_awburst(hp0_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
    .m_axi_s2mm_awprot(hp0_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
    .m_axi_s2mm_awcache(hp0_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
    .m_axi_s2mm_awuser(hp0_awuser),                    // output wire [3 : 0] m_axi_s2mm_awuser
    .m_axi_s2mm_awvalid(hp0_awvalid),                  // output wire m_axi_s2mm_awvalid
    .m_axi_s2mm_awready(hp0_awready),                  // input wire m_axi_s2mm_awready
    
    //AXI4 data interface
    .m_axi_s2mm_wdata(hp0_wdata),                      // output wire [63 : 0] m_axi_s2mm_wdata
    .m_axi_s2mm_wstrb(hp0_wstrb),                      // output wire [7 : 0] m_axi_s2mm_wstrb
    .m_axi_s2mm_wlast(hp0_wlast),                      // output wire m_axi_s2mm_wlast
    .m_axi_s2mm_wvalid(hp0_wvalid),                    // output wire m_axi_s2mm_wvalid
    .m_axi_s2mm_wready(hp0_wready),                    // input wire m_axi_s2mm_wready
    .m_axi_s2mm_bresp(hp0_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
    .m_axi_s2mm_bvalid(hp0_bvalid),                    // input wire m_axi_s2mm_bvalid
    .m_axi_s2mm_bready(hp0_bready),                    // output wire m_axi_s2mm_bready
    // User interface
    .s_axis_s2mm_cmd_tvalid(user_s2mm_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
    .s_axis_s2mm_cmd_tready(user_s2mm_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
    .s_axis_s2mm_cmd_tdata(user_s2mm_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata

    .s_axis_s2mm_tdata(user_s2mm_tdata),                    // input wire [63 : 0] s_axis_s2mm_tdata
    .s_axis_s2mm_tkeep(user_s2mm_tkeep),                    // input wire [7 : 0] s_axis_s2mm_tkeep
    .s_axis_s2mm_tlast(user_s2mm_tlast),                    // input wire s_axis_s2mm_tlast
    .s_axis_s2mm_tvalid(user_s2mm_tvalid),                  // input wire s_axis_s2mm_tvalid
    .s_axis_s2mm_tready(user_s2mm_tready)                  // output wire s_axis_s2mm_tready
);


xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    
    .ECC_MODE("no_ecc"),       
    .FIFO_MEMORY_TYPE("block"), 
    .FIFO_READ_LATENCY(1),     
    .FIFO_WRITE_DEPTH(1024),   
    .FULL_RESET_VALUE(0),      
    .PROG_EMPTY_THRESH(),    
    .PROG_FULL_THRESH(),     
    .RD_DATA_COUNT_WIDTH(10),   
    .READ_DATA_WIDTH(64),      
    .READ_MODE("std"),         
    .USE_ADV_FEATURES("0000"), //enable almost full
    .WAKEUP_TIME(0),           
    .WRITE_DATA_WIDTH(64),     
    .WR_DATA_COUNT_WIDTH(10)    
)
fifo_s2mm_hp0 (
    .almost_empty(),   
    .almost_full(),                     
    .dout(fifo_s2mm_dout),                   
    .empty(fifo_s2mm_empty),                
    .full(fifo_s2mm_full),                                   
    .din(fifo_s2mm_din),    
    .rd_en(fifo_s2mm_rd_en),                 
    .rst(rst),                                     
    .wr_clk(clk),               
    .wr_en(fifo_s2mm_wr_en)                 
);

endmodule