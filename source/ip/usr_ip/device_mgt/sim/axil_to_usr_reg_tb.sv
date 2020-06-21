module axil_to_usr_reg_tb();

logic   clk_200m;
logic   rst;

initial begin
    clk_200m = 0;
    forever begin
        # 2.5 clk_200m = ~clk_200m;
    end
end
initial begin
    rst = 1;
    #100;
    rst = 0;
end


logic [ADDR_WIDTH-1:0]      s_axil_awaddr;
logic [2 : 0]               s_axil_awprot;
logic                       s_axil_awvalid;
logic                       s_axil_awready;
logic [DATA_WIDTH-1:0]      s_axil_wdata;
logic [(DATA_WIDTH/8)-1:0]  s_axil_wstrb;
logic                       s_axil_wvalid;
logic                       s_axil_wready;
logic                       s_axil_bvalid;
logic [1:0]                 s_axil_bresp;
logic                       s_axil_bready;
logic [ADDR_WIDTH-1:0]      s_axil_araddr;
logic [2:0]                 s_axil_arprot;
logic                       s_axil_arvalid;
logic                       s_axil_arready;
logic [DATA_WIDTH-1:0]      s_axil_rdata;
logic [1:0]                 s_axil_rresp;
logic                       s_axil_rvalid;
logic                       s_axil_rready;
logic                       usr_reg_wen;
logic [31:0]                usr_reg_waddr;
logic [31:0]                usr_reg_wdata;
logic                       usr_reg_ren;
logic [31:0]                usr_reg_raddr;
logic [31:0]                usr_reg_rdata;

axil_to_usr_reg # (
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) axil_to_usr_reg_i (
    .clk(clk_200m),
    .rst(rst)
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil),
    .s_axil_rdata(),
    .s_axil_rresp(),
    .s_axil_rvalid(),
    
    .usr_reg_wen(),
    .usr_reg_waddr(),
    .usr_reg_wdata(),
    .usr_reg_ren(),
    .usr_reg_raddr(),
    .usr_reg_rdata()

);





endmodule
