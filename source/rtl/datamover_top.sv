
`timescale 1ns/1ps

module datamover_top (
    input           clk,
    input           rst,
    
    //read cmd interface 
    input [31:0]    i_mm2s_rd_cmd_addr,
    input [8:0]     i_mm2s_rd_cmd_length,
    
    input           i_rd_cmd_req,
    output          o_rd_cmd_ack,
    
    //write cmd interface
    input [3:0]     i_s2mm_wr_cmd_eof;
    input [31:0]    i_s2mm_wr_cmd_addr,
    input [8:0]     i_s2mm_wr_cmd_length,//512byte

    input           i_s2mm_wr_cmd_tvalid,
    input [71:0]    i_s2mm_wr_cmd_tdata,
    output          o_s2mm_wr_cmd_tready,

    //read data interface
    input           i_mm2s_rd_tready,
    output          o_mm2s_rd_tvalid,
    output          o_mm2s_rd_tlast,
    output [7:0]    o_mm2s_rd_tkeep,
    output [63:0]   o_mm2s_rd_tdata,
    
    //write data interface
    input logic         i_s2mm_wr_tvalid,
    input logic [63:0]  i_s2mm_wr_tdata,
    input logic [7:0]   i_s2mm_wr_tkeep,
    output logic        o_s2mm_wr_tready,

    //write status
    output              o_s2mm_sts_tvalid,
    output [7:0]        o_s2mm_sts_tdata,
    output              o_s2mm_sts_tkeep,
    output              o_s2mm_sts_tlast,

    
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
    output [7:0]    hp0_awlen,
    output [2:0]    hp0_awsize,
    output [1:0]    hp0_awburst,
    output [2:0]    hp0_awprot,
    output [3:0]    hp0_awcache,
    output [3:0]    hp0_awuser,   

    //AXI4 write data interface
    output [63:0]   hp0_wdata,
    output [7:0]    hp0_wstrb,
    output          hp0_wlast,
    output          hp0_wvalid,
    input           hp0_wready,

    input [1:0]     hp0_bresp,
    input           hp0_bvalid,
    output          hp0_bready

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
    
    .s_axis_mm2s_cmd_tvalid(i_mm2s_rd_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
    .s_axis_mm2s_cmd_tready(o_mm2s_rd_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
    .s_axis_mm2s_cmd_tdata(i_mm2s_rd_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata

    .m_axis_mm2s_tdata(o_mm2s_rd_tdata),                    // output wire [63 : 0] m_axis_mm2s_tdata
    .m_axis_mm2s_tkeep(o_mm2s_rd_tkeep),                    // output wire [7 : 0] m_axis_mm2s_tkeep
    .m_axis_mm2s_tlast(o_mm2s_rd_tlast),                    // output wire m_axis_mm2s_tlast
    .m_axis_mm2s_tvalid(o_mm2s_rd_tvalid),                  // output wire m_axis_mm2s_tvalid
    .m_axis_mm2s_tready(i_mm2s_rd_tready),                  // input wire m_axis_mm2s_tready
    // AXI4 interface
    .m_axi_s2mm_aclk(clk),                        // input wire m_axi_s2mm_aclk
    .m_axi_s2mm_aresetn(~rst),                  // input wire m_axi_s2mm_aresetn
    .s2mm_err(),                                      // output wire s2mm_err
    .m_axis_s2mm_cmdsts_awclk(clk),      // input wire m_axis_s2mm_cmdsts_awclk
    .m_axis_s2mm_cmdsts_aresetn(~rst),  // input wire m_axis_s2mm_cmdsts_aresetn
   
    .m_axis_s2mm_sts_tvalid(o_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
    .m_axis_s2mm_sts_tready(1'b1),          // input wire m_axis_s2mm_sts_tready
    .m_axis_s2mm_sts_tdata(o_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
    .m_axis_s2mm_sts_tkeep(o_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
    .m_axis_s2mm_sts_tlast(o_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast
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
    .s_axis_s2mm_cmd_tvalid(i_s2mm_wr_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
    .s_axis_s2mm_cmd_tready(o_s2mm_wr_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
    .s_axis_s2mm_cmd_tdata(i_s2mm_wr_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata

    .s_axis_s2mm_tdata(i_s2mm_wr_tdata),                    // input wire [63 : 0] s_axis_s2mm_tdata
    .s_axis_s2mm_tkeep(i_s2mm_wr_ttkeep),                    // input wire [7 : 0] s_axis_s2mm_tkeep
    .s_axis_s2mm_tlast(),                    // input wire s_axis_s2mm_tlast
    .s_axis_s2mm_tvalid(i_s2mm_wr_tvalid),                  // input wire s_axis_s2mm_tvalid
    .s_axis_s2mm_tready(o_s2mm_wr_tready)                  // output wire s_axis_s2mm_tready
);


endmodule