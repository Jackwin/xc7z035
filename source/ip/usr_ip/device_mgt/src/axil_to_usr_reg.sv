
module axil_to_usr_reg #
    (
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32
    )
    (
        input logic                         clk,
        input logic                         rst,

        input logic [ADDR_WIDTH-1:0]        s_axil_awaddr,
        input logic [2 : 0]                 s_axil_awprot,
        input logic                         s_axil_awvalid,
        output logic                        s_axil_awready,
        input logic [DATA_WIDTH-1:0]        s_axil_wdata,
        input logic [(DATA_WIDTH/8)-1:0]    s_axil_wstrb,
        input logic                         s_axil_wvalid,
        output logic                        s_axil_wready,
        output logic                        s_axil_bvalid,
        output logic [1:0]                  s_axil_bresp,
        input logic                         s_axil_bready,
        input logic [ADDR_WIDTH-1:0]        s_axil_araddr,
        input logic [2:0]                   s_axil_arprot,
        input logic                         s_axil_arvalid,
        output logic                        s_axil_arready,
        output logic [DATA_WIDTH-1:0]       s_axil_rdata,
        output logic [1:0]                  s_axil_rresp,
        output logic                        s_axil_rvalid,
        input  logic                        s_axil_rready,
            
        output logic                        usr_reg_wen,
        output logic [31:0]                 usr_reg_waddr,
        output logic [31:0]                 usr_reg_wdata,
        output logic                        usr_reg_ren,
        output logic [31:0]                 usr_reg_raddr,
        input  logic [31:0]                 usr_reg_rdata
    );

    logic                   axil_awready;
    logic [ADDR_WIDTH-1:0]  axil_awaddr;
    logic                   axil_wready;
    logic                   axil_bvalid;
    logic [1:0]             axil_bresp;
    logic                   axil_arready;
    logic [ADDR_WIDTH-1:0]  axil_araddr;
    logic                   axil_rvalid;
    logic [1:0]             axil_rresp;
    logic [DATA_WIDTH-1:0]  axil_rdata;
    logic [DATA_WIDTH-1:0]  axil_wdata;

    logic                   reg_rden;
    logic                   reg_rden_r;
    logic                   reg_rden_2r;
    

    always_comb begin
        s_axil_awready	<= axil_awready;
        s_axil_wready	= axil_wready;
        s_axil_bresp	= axil_bresp;
        s_axil_bvalid	= axil_bvalid;
        s_axil_arready	= axil_arready;
        s_axil_rdata	= axil_rdata;
        s_axil_rresp	= axil_rresp;
        s_axil_rvalid	= axil_rvalid;  
    end

    // slave handshakes with master for the write addr channel
    // axil_awready is asserted one clock cycle when s_axil_awvalid
    // is asserted
    always @(posedge clk) begin
        if (rst)
            axil_awready <= 1'b0;
        else if (~axil_awready && s_axil_awvalid)
            axil_awready <= 1'b1;
        else
            axil_awready <= 1'b0;
    end

    // latch the address
    always @(posedge clk)
    begin
        if (~axil_awready && s_axil_awvalid)
            axil_awaddr <= s_axil_awaddr;
    end


    // slave handshakes with master for the write data channel
    // axil_wready is asserted one clock cycle when s_axil_wvalid
    // is asserted
    always @(posedge clk)begin
        if (rst)
            axil_wready <= 1'b0;
        else if(~axil_wready && s_axil_wvalid)
            axil_wready <= 1'b1;
        else
            axil_wready <= 1'b0;
    end

    // write response channel
    // axi_wready & s_axil_wvalid indicates that slave has received the data
    // Handshake by the assertion of axil_bvalid for one clock cycle
    always @(posedge clk)begin
        if (rst)begin
            axil_bvalid  <= 0;
            axil_bresp   <= 2'b0;
        end else if (~axil_bvalid && axil_wready && s_axil_wvalid)begin
            axil_bvalid <= 1'b1;
            axil_bresp  <= 2'b0; // 'OKAY' response
        end else if (s_axil_bready && axil_bvalid) begin
            axil_bvalid <= 1'b0;
            axil_bresp  <= 2'b0;
        end
    end

    // slave handshakes with master for the read addr channel
    // axil_arready is asserted for one clock cycle when s_axil_arvalid
    // is asserted
    
    always @(posedge clk) begin
        if (rst)
            axil_arready <= 'b0;
        else if (~axil_arready && s_axil_arvalid)
            axil_arready <= 1'b1; // indicates that the slave has acceped the valid read address
        else
            axil_arready <= 1'b0;
    end

    // Latch the read addr
    always @(posedge clk)begin
        if (~axil_arready && s_axil_arvalid)
            axil_araddr  <= s_axil_araddr; 
    end

    // read data logic
    always @(posedge clk) begin
        if (rst) begin
            axil_rvalid <= 0;
            axil_rresp  <= 0;
        end else begin
            if (reg_rden_2r && ~axil_rvalid) begin
                axil_rvalid <= 1'b1;
                axil_rresp  <= 2'b0; 
            end else if (axil_rvalid && s_axil_rready) begin
                axil_rvalid <= 1'b0; 
                axil_rresp  <= 2'b0; 
            end
        end
    end

    
    logic reg_wren;
    logic reg_wren_r;
    always_comb begin
        reg_wren = axil_wready && s_axil_wvalid;
    end
    always @(posedge clk) begin
        if (~axil_wready && s_axil_wvalid)
            axil_wdata <= s_axil_wdata;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            usr_reg_waddr <= 'h0;
            usr_reg_wdata <= 'h0;
        end else if (reg_wren) begin
            usr_reg_wdata <= axil_wdata;
            usr_reg_waddr <= axil_awaddr; 
        end
    end

    always_ff @(posedge clk) begin
        usr_reg_wen <= reg_wren;
    end

    // read user reg logic
    always @(posedge clk)begin
        if (~axil_arready && s_axil_arvalid)
            reg_rden <= 1'b1;
        else
            reg_rden <= 1'b0;
    end

    always_ff @(posedge clk) begin
        reg_rden_r <= reg_rden;
        reg_rden_2r <= reg_rden_r;
    end

    assign usr_reg_ren = reg_rden;
    assign usr_reg_raddr = {axil_araddr[ADDR_WIDTH-1:2], 2'b0}; // 32-bit address
    assign axil_rdata = usr_reg_rdata;


endmodule
