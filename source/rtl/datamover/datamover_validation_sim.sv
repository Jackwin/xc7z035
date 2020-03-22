`timescale 1ns/1ps

module datamover_validation_sim();

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
logic [7:0]     hp0_awlen;
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

wire            hp0_arready;
wire            hp0_awready;
wire [5:0]      hp0_bid;

wire [63:0]     hp0_rdata;
wire [5:0]      hp0_rid;
wire            hp0_rlast;
wire [1:0]      hp0_rresp;
wire            hp0_rvalid;
wire            hp0_rready;

wire            user_mm2s_rd_cmd_tvalid;
wire            user_mm2s_rd_cmd_tready;
wire [71:0]     user_mm2s_rd_cmd_tdata;
wire [63:0]     user_mm2s_rd_tdata;
wire [7:0]      user_mm2s_rd_tkeep;
wire            user_mm2s_rd_tlast;
wire            user_mm2s_rd_tready;

wire            user_s2mm_wr_cmd_tready;
wire            user_s2mm_wr_cmd_tvalid;
wire [71:0]     user_s2mm_wr_cmd_tdata;
wire            user_s2mm_wr_tvalid;
wire [63:0]     user_s2mm_wr_tdata;
wire            user_s2mm_wr_tready;
wire [7:0]      user_s2mm_wr_tkeep;
wire            user_s2mm_wr_tlast;

wire            user_s2mm_sts_tvalid;
wire [7:0]      user_s2mm_sts_tdata;
wire            user_s2mm_sts_tkeep;
wire            user_s2mm_sts_tlast;


logic           wr_data_valid;
logic [63:0]    wr_data;
logic           wr_data_ready;
logic           wr_data_finish;


logic [31:0]    start_addr;

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

datamover_validation  datamover_validation_inst(
    .clk(clk),
    .rst(rst),

    .i_s2mm_wr_cmd_tready(user_s2mm_wr_cmd_tready),
    .o_s2mm_wr_cmd_tdata(user_s2mm_wr_cmd_tdata),
    .o_s2mm_wr_cmd_tvalid(user_s2mm_wr_cmd_tvalid),

    .o_s2mm_wr_tdata(user_s2mm_wr_tdata),
    .o_s2mm_wr_tkeep(user_s2mm_wr_tkeep),
    .o_s2mm_wr_tvalid(user_s2mm_wr_tvalid),
    .o_s2mm_wr_tlast(user_s2mm_wr_tlast),
    .i_s2mm_wr_tready(user_s2mm_wr_tready),

    .s2mm_sts_tdata(user_s2mm_sts_tdata),
    .s2mm_sts_tvalid(user_s2mm_sts_tvalid),
    .s2mm_sts_tkeep(user_s2mm_sts_tkeep),
    .s2mm_sts_tlast(user_s2mm_sts_tlast),


    .i_mm2s_rd_cmd_tready(user_mm2s_rd_cmd_tready),
    .o_mm2s_rd_cmd_tdata(user_mm2s_rd_cmd_tdata),
    .o_mm2s_rd_cmd_tvalid(user_mm2s_rd_cmd_tvalid),

    .i_mm2s_rd_tdata(user_mm2s_rd_tdata),
    .i_mms2_rd_tkeep(user_mm2s_rd_tkeep),
    .i_mm2s_rd_tvalid(user_mm2s_rd_tvalid),
    .i_mm2s_rd_tlast(user_mm2s_rd_tlast),
    .i_mm2s_rd_tready(user_mm2s_rd_tready)
);



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
    
    .s_axis_mm2s_cmd_tvalid(user_mm2s_rd_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
    .s_axis_mm2s_cmd_tready(user_mm2s_rd_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
    .s_axis_mm2s_cmd_tdata(user_mm2s_rd_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata

    .m_axis_mm2s_tdata(user_mm2s_rd_tdata),                    // output wire [63 : 0] m_axis_mm2s_tdata
    .m_axis_mm2s_tkeep(user_mm2s_rd_tkeep),                    // output wire [7 : 0] m_axis_mm2s_tkeep
    .m_axis_mm2s_tlast(user_mm2s_rd_tlast),                    // output wire m_axis_mm2s_tlast
    .m_axis_mm2s_tvalid(user_mm2s_rd_tvalid),                  // output wire m_axis_mm2s_tvalid
    .m_axis_mm2s_tready(user_mm2s_rd_tready),                  // input wire m_axis_mm2s_tready
    // AXI4 interface
    .m_axi_s2mm_aclk(clk),                        // input wire m_axi_s2mm_aclk
    .m_axi_s2mm_aresetn(~rst),                  // input wire m_axi_s2mm_aresetn
    .s2mm_err(),                                      // output wire s2mm_err
    .m_axis_s2mm_cmdsts_awclk(clk),      // input wire m_axis_s2mm_cmdsts_awclk
    .m_axis_s2mm_cmdsts_aresetn(~rst),  // input wire m_axis_s2mm_cmdsts_aresetn
   
    .m_axis_s2mm_sts_tvalid(user_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
    .m_axis_s2mm_sts_tready(1'b1),          // input wire m_axis_s2mm_sts_tready
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
    .s_axis_s2mm_cmd_tvalid(user_s2mm_wr_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
    .s_axis_s2mm_cmd_tready(user_s2mm_wr_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
    .s_axis_s2mm_cmd_tdata(user_s2mm_wr_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata

    .s_axis_s2mm_tdata(user_s2mm_wr_tdata),                    // input wire [63 : 0] s_axis_s2mm_tdata
    .s_axis_s2mm_tkeep(user_s2mm_wr_tkeep),                    // input wire [7 : 0] s_axis_s2mm_tkeep
    .s_axis_s2mm_tlast(user_s2mm_wr_tlast),                    // input wire s_axis_s2mm_tlast
    .s_axis_s2mm_tvalid(user_s2mm_wr_tvalid),                  // input wire s_axis_s2mm_tvalid
    .s_axis_s2mm_tready(user_s2mm_wr_tready)                  // output wire s_axis_s2mm_tready
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


    .s_axi_arid(hp0_arid),
    .s_axi_araddr(hp0_araddr),
    .s_axi_arlen(hp0_arlen),
    .s_axi_arsize(hp0_arsize),
    .s_axi_arburst(hp0_arburst),
    .s_axi_arlock(hp0_arlock),
    .s_axi_arcache(hp0_arcache),
    .s_axi_arprot(hp0_arport),
    .s_axi_arvalid(hp0_arvalid),
    .s_axi_arready(hp0_arready),
    .s_axi_rid(hp0_rid),
    .s_axi_rdata(hp0_rdata),
    .s_axi_rresp(hp0_rresp),
    .s_axi_rlast(hp0_rlast),
    .s_axi_rvalid(hp0_rvalid),
    .s_axi_rready(hp0_rready)
);


endmodule