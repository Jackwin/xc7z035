`timescale 1ns/1ps

module datamover_sim();

logic   clk;
logic   rst;

logic [31:0]    wr_cmd_addr;
logic [22:0]    wr_cmd_length;
logic           wr_cmd_req;
logic           wr_cmd_ack;

logic           hp0_awready;
logic           hp0_awvalid;
logic [3:0]     hp0_awid;
logic [31:0]    hp0_awaddr;
logic [3:0]     hp0_awlen;
logic [2:0]     hp0_awsize;
logic [1:0]     hp0_awburst;
logic [2:0]     hp0_awprot;
logic [3:0]     hp0_awcache;

logic [63:0]    hp0_wdata;
logic [7:0]     hp0_wstrb;
logic           hp0_wlast;
logic           hp0_wvalid;
logic           hp0_wready;

logic [1:0]     hp0_bresp;
logic           hp0_bvalid;
logic           hp0_bready;


logic           wr_data_valid;
logic [63:0]    wr_data;
logic           wr_data_ready;
logic           wr_data_finish;




initial begin
    clk = 0;
    forever begin
        # 2.5 clk = ~clk;
    end
end

initial begin
    rst = 1;
    #100;
    rst = 0;
end

initial begin
    wr_cmd_addr <= 0;
    wr_cmd_length <= 0;
    wr_cmd_req <= 0;
    wr_data_valid <= 0;
    wr_data <= 64'h0001020304050607;
    #100;

    @(posedge clk);
    wr_cmd_req <= 1;
    wr_cmd_length <= 16;
    wait (wr_cmd_ack);
    @(posedge clk);
    wr_cmd_req <= 0;

    for (int m = 0; m < 2; m++) begin
        wait (wr_data_ready);
        @(posedge clk) begin
            wr_data <= wr_data + 64'h0101010101010101;
            wr_data_valid <= 1;
        end
    end

    @(posedge clk);
    wr_data_valid <= 0;
    wr_data <= 0;

    #200;
    $stop;





end



datamover_ctrl datamover_ctrl_i (
    .clk(clk),
    .rst(rst),
    
    //read cmd interface 
    .i_rd_cmd_data(),
    .i_rd_cmd_req(),
    .o_rd_cmd_ack(),
    
    //write cmd interface 
    .i_s2mm_wr_cmd_addr(wr_cmd_addr),
    .i_s2mm_wr_cmd_length(wr_cmd_length),
    .i_wr_cmd_req(wr_cmd_req),
    .o_wr_cmd_ack(wr_cmd_ack),
    
    //read data interface
    .i_rd_ready(),
    .o_rd_valid(),
    .o_rd_last(),
    .o_rd_data(),
    
    //write data interface
    .i_wr_valid(wr_data_valid),
    .i_wr_data(wr_data),
    .o_wr_ready(wr_data_ready),
    .o_write_finish(wr_data_finish),

    
    //AXI4 read addr interface
    .hp0_arready(),
    .hp0_arvalid(),
    .hp0_arid(),
    .hp0_araddr(),
    .hp0_arlen(),
    .hp0_arsize(),
    .hp0_arburst(),
    .hp0_arprot(),
    .hp0_arcache(),
    //output [3:0]    hp0_aruser,
   
    //AXI4 read data interface 
    .hp0_rdata(),
    .hp0_rresp(),
    .hp0_rlast(),
    .hp0_rvalid(),
    .hp0_rready(),

    //AXI4 write addr interface
    .hp0_awready(hp0_awready),
    .hp0_awvalid(hp0_awvalid),
    .hp0_awid(hp0_awid),
    .hp0_awaddr(hp0_awaddr),
    .hp0_awlen(hp0_awlen),
    .hp0_awsize(hp0_awsize),
    .hp0_awburst(hp0_awburst),
    .hp0_awprot(hp0_awprot),
    .hp0_awcache(hp0_awcache),
   // output [3:0]    hp0_awuser,   

    //AXI4 read data interface
    .hp0_wdata(hp0_wdata),
    .hp0_wstrb(hp0_wstrb),
    .hp0_wlast(hp0_wlast),
    .hp0_wvalid(hp0_wvalid),
    .hp0_wready(hp0_wready),

    .hp0_bresp(hp0_bresp),
    .hp0_bvalid(hp0_bvalid),
    .hp0_bready(hp0_bready)

);



axi_ram #(
    // Width of data bus in bits
    .DATA_WIDTH(64),
    // Width of address bus in bits
    .ADDR_WIDTH(16),
    // Width of ID signal
    .ID_WIDTH(8),
    // Extra pipeline register on output
    .PIPELINE_OUTPUT(0)
) axi_ram_inst (
    .clk(clk),
    .rst(rst),

    .s_axi_awid(hp0_awid),
    .s_axi_awaddr(hp0_awaddr[15:0]),
    .s_axi_awlen(hp0_awlen),
    .s_axi_awsize(hp0_awsize),
    .s_axi_awburst(hp0_awburst),
    .s_axi_awlock(),
    .s_axi_awcache(hp0_awcache),
    .s_axi_awprot(hp0_awprot),
    .s_axi_awvalid(hp0_awvalid),
    .s_axi_awready(hp0_awready),

    .s_axi_wdata(hp0_wdata),
    .s_axi_wstrb(hp0_wstrb),
    .s_axi_wlast(hp0_wlast),
    .s_axi_wvalid(hp0_wvalid),
    .s_axi_wready(hp0_wready),

    .s_axi_bid(),
    .s_axi_bresp(hp0_bresp),
    .s_axi_bvalid(hp0_bvalid),
    .s_axi_bready(hp0_bready),


    .s_axi_arid(),
    .s_axi_araddr(),
    .s_axi_arlen(),
    .s_axi_arsize(),
    .s_axi_arburst(),
    .s_axi_arlock(),
    .s_axi_arcache(),
    .s_axi_arprot(),
    .s_axi_arvalid(),
    .s_axi_arready(),
    .s_axi_rid(),
    .s_axi_rdata(),
    .s_axi_rresp(),
    .s_axi_rlast(),
    .s_axi_rvalid(),
    .s_axi_rready()
);


endmodule