
`timescale 1ns/1ps

module datamover_ctrl (
    input           clk_dma,
    input           rst_dma,
    
    //read cmd interface 
    input [107:0]   i_rd_cmd_data,
    input           i_rd_cmd_req,
    output          o_rd_cmd_ack,
    
    //write cmd interface 
    input [107:0]   i_wr_cmd_data,
    input           i_wr_cmd_req,
    output          o_wr_cmd_ack,
    
    //read data interface
    input           i_rd_ready,
    output          o_rd_valid,
    output          o_rd_last,
    output [63:0]   o_rd_data,
    
    //write data interface
    input           i_wr_valid,
    input  [63:0]   i_wr_data,
    output          o_wr_ready,
    output  reg     o_write_finish,

    
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
    output [5:0]    hp0_awid,
    output [31:0]   hp0_awaddr,
    output [3:0]    hp0_awlen,
    output [2:0]    hp0_awsize,
    output [1:0]    hp0_awburst,
    output [2:0]    hp0_awprot,
    output [3:0]    hp0_awcache,
   // output [3:0]    hp0_awuser,   

    //AXI4 read data interface
    output [63:0]   hp0_wdata,
    output [15:0]   hp0_wstrb,
    output          hp0_wlast,
    output          hp0_wvalid,
    input           hp0_wready,

    input [1:0]     hp0_bresp,
    input           hp0_bvalid,
    output          hp0_bready

);

wire user_mm2s_cmd_tvalid;
    wire user_mm2s_cmd_tready;
    wire [71:0] user_mm2s_cmd_tdata;

datamover datamover_hp0 (
    .m_axi_mm2s_aclk(m_axi_mm2s_aclk),                        // input wire m_axi_mm2s_aclk
    .m_axi_mm2s_aresetn(m_axi_mm2s_aresetn),                  // input wire m_axi_mm2s_aresetn
    // AXI4 interface
    .mm2s_err(mm2s_err),                                      // output wire mm2s_err
    .m_axis_mm2s_cmdsts_aclk(m_axis_mm2s_cmdsts_aclk),        // input wire m_axis_mm2s_cmdsts_aclk
    .m_axis_mm2s_cmdsts_aresetn(m_axis_mm2s_cmdsts_aresetn),  // input wire m_axis_mm2s_cmdsts_aresetn
    
    .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
    .m_axis_mm2s_sts_tready(m_axis_mm2s_sts_tready),          // input wire m_axis_mm2s_sts_tready
    .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
    .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
    .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),            // output wire m_axis_mm2s_sts_tlast

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

    .m_axis_mm2s_tdata(m_axis_mm2s_tdata),                    // output wire [63 : 0] m_axis_mm2s_tdata
    .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),                    // output wire [7 : 0] m_axis_mm2s_tkeep
    .m_axis_mm2s_tlast(m_axis_mm2s_tlast),                    // output wire m_axis_mm2s_tlast
    .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),                  // output wire m_axis_mm2s_tvalid
    .m_axis_mm2s_tready(m_axis_mm2s_tready),                  // input wire m_axis_mm2s_tready
    // AXI4 interface
    .m_axi_s2mm_aclk(m_axi_s2mm_aclk),                        // input wire m_axi_s2mm_aclk
    .m_axi_s2mm_aresetn(m_axi_s2mm_aresetn),                  // input wire m_axi_s2mm_aresetn
    .s2mm_err(s2mm_err),                                      // output wire s2mm_err
    .m_axis_s2mm_cmdsts_awclk(m_axis_s2mm_cmdsts_awclk),      // input wire m_axis_s2mm_cmdsts_awclk
    .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn),  // input wire m_axis_s2mm_cmdsts_aresetn
   
    .m_axis_s2mm_sts_tvalid(m_axis_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
    .m_axis_s2mm_sts_tready(m_axis_s2mm_sts_tready),          // input wire m_axis_s2mm_sts_tready
    .m_axis_s2mm_sts_tdata(m_axis_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
    .m_axis_s2mm_sts_tkeep(m_axis_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
    .m_axis_s2mm_sts_tlast(m_axis_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast

    .m_axi_s2mm_awid(m_axi_s2mm_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
    .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr),                    // output wire [31 : 0] m_axi_s2mm_awaddr
    .m_axi_s2mm_awlen(m_axi_s2mm_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
    .m_axi_s2mm_awsize(m_axi_s2mm_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
    .m_axi_s2mm_awburst(m_axi_s2mm_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
    .m_axi_s2mm_awprot(m_axi_s2mm_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
    .m_axi_s2mm_awcache(m_axi_s2mm_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
    .m_axi_s2mm_awuser(m_axi_s2mm_awuser),                    // output wire [3 : 0] m_axi_s2mm_awuser
    .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid),                  // output wire m_axi_s2mm_awvalid
    .m_axi_s2mm_awready(m_axi_s2mm_awready),                  // input wire m_axi_s2mm_awready

    .m_axi_s2mm_wdata(m_axi_s2mm_wdata),                      // output wire [63 : 0] m_axi_s2mm_wdata
    .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb),                      // output wire [7 : 0] m_axi_s2mm_wstrb
    .m_axi_s2mm_wlast(m_axi_s2mm_wlast),                      // output wire m_axi_s2mm_wlast
    .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid),                    // output wire m_axi_s2mm_wvalid
    .m_axi_s2mm_wready(m_axi_s2mm_wready),                    // input wire m_axi_s2mm_wready
    .m_axi_s2mm_bresp(m_axi_s2mm_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
    .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid),                    // input wire m_axi_s2mm_bvalid
    .m_axi_s2mm_bready(m_axi_s2mm_bready),                    // output wire m_axi_s2mm_bready
    // User interface
    .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
    .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
    .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata

    .s_axis_s2mm_tdata(s_axis_s2mm_tdata),                    // input wire [63 : 0] s_axis_s2mm_tdata
    .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),                    // input wire [7 : 0] s_axis_s2mm_tkeep
    .s_axis_s2mm_tlast(s_axis_s2mm_tlast),                    // input wire s_axis_s2mm_tlast
    .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),                  // input wire s_axis_s2mm_tvalid
    .s_axis_s2mm_tready(s_axis_s2mm_tready)                  // output wire s_axis_s2mm_tready
);

endmodule