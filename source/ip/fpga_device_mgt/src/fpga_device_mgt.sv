/*
For the heterogenous system, FPGA is treated as a device, which should support register access 
and interrupt handling.
*/
`timescale 1ns/1ps

module fpga_device_mgt #(
    parameter integer DATA_WIDTH = 32,
    parameter integer ADDR_WIDTH = 12,
    parameter integer TEMPER_WIDTH = 12,
    parameter integer INTR_MSG_WIDTH = 8
)
(
    // Users to add ports here

    output logic [DATA_WIDTH-1:0]       o_status_reg_data,            
    output logic                        o_status_reg_valid,
    
    output logic                        o_intr_ready,
    input  logic [INTR_MSG_WIDTH-1:0]   i_intr_msg,        
   
    input logic                         i_temper_valid,
    input logic [TEMPER_WIDTH-1:0]      i_temper,
    input logic [DATA_WIDTH-1:0]        i_version,
    output logic                        soft_rst,

    output logic                        o_usr_reg_wen,
    output logic [ADDR_WIDTH-1:0]       o_usr_reg_waddr,
    output logic [DATA_WIDTH-1:0]       o_usr_reg_wdata,
    output logic                        o_usr_reg_ren,
    output logic [ADDR_WIDTH-1:0]       o_usr_reg_raddr,
    input  logic [DATA_WIDTH-1:0]       i_usr_reg_rdata,
       
    input logic                         s_axil_aclk,
    input logic                         s_axil_aresetn,
    input logic [ADDR_WIDTH-1:0]        s_axil_awaddr,
    input logic [2:0]                   s_axil_awprot,
    input logic                         s_axil_awvalid,
    output logic                        s_axil_awready,
    input logic [DATA_WIDTH-1:0]        s_axil_wdata,
    input logic [(DATA_WIDTH/8)-1:0]    s_axil_wstrb,
    input logic                         s_axil_wvalid,
    output logic                        s_axil_wready,
    output logic [1:0]                  s_axil_bresp,
    output logic                        s_axil_bvalid,
    input logic                         s_axil_bready,
    input logic [ADDR_WIDTH-1:0]        s_axil_araddr,
    input logic [2:0]                   s_axil_arprot,
    input logic                         s_axil_arvalid,
    output logic                        s_axil_arready,
    output logic [DATA_WIDTH-1:0]       s_axil_rdata,
    output logic [1:0]                  s_axil_rresp,
    output logic                        s_axil_rvalid,
    input logic                         s_axil_rready
);
    
axil_to_usr_reg # ( 
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
) axil_to_usr_reg_inst (
    .usr_reg_wen(o_usr_reg_wen),
    .usr_reg_waddr(o_usr_reg_waddr),
    .usr_reg_wdata(o_usr_reg_wdata),
    .usr_reg_ren(o_usr_reg_ren),
    .usr_reg_raddr(o_usr_reg_raddr),
    .usr_reg_rdata(i_usr_reg_rdata),
    
    .clk(s_axil_aclk),
    .rst(~s_axil_aresetn),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready)
);


status_intr_mgt # (
    .DATA_WDITH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .INTR_MSG_WIDTH(INTR_MSG_WIDTH),
    .TMEPER_WIDTH(TEMPER_WIDTH)
)status_intr_mgt_inst
    (
    .clk(s_axil_aclk),
    .i_intr_msg(i_intr_msg),
    .i_temper_valid(i_temper_valid),

    .i_reg_data(o_usr_reg_wdata),
    .i_reg_rd_addr(o_usr_reg_raddr),
    .i_reg_ren(o_usr_reg_ren),
    .i_reg_wen(o_usr_reg_wen),
    .i_reg_wr_addr(o_usr_reg_waddr),

    .i_temper(i_temper),
    .i_version(i_version),
    .o_intr_ready(o_intr_ready),
    .o_reg_data(o_status_reg_data),
    .o_reg_valid(o_status_reg_valid),
    .rstn(s_axil_aresetn),
    .soft_rst(soft_rst)
    );

        
endmodule

