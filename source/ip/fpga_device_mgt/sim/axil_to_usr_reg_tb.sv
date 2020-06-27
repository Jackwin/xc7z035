module axil_to_usr_reg_tb();

logic   clk;
logic   rst;

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

localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;

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


localparam WR_REG_ADDR = 32'h04;
localparam WR_REG_DATA = 32'h5a5a_8989;


localparam RD_REG_ADDR = 32'h04;
localparam RD_REG_DATA = 32'h5a5a_8989;

logic [DATA_WIDTH-1:0][0:31] reg_file;

initial begin
    s_axil_awaddr = 0;
    s_axil_awvalid = 0;
    s_axil_awprot = 0;

    #150;
    @(posedge clk);
    wr_addr(WR_REG_ADDR);
    wr_data(WR_REG_DATA);
    wait_resp();
   
    @(posedge clk);
    @(posedge clk);

    read_addr(RD_REG_ADDR);
    read_data();

    wait(s_axil_rvalid & (s_axil_rdata== WR_REG_DATA));
    #40;
    $stop;
    

end

always @(posedge clk) begin
    if (usr_reg_wen) begin
        if (usr_reg_waddr == WR_REG_ADDR & usr_reg_wdata == WR_REG_DATA) begin
            reg_file[usr_reg_waddr[ADDR_WIDTH-1:2]] <= usr_reg_wdata;
            $display("Write data %x to addr %x", usr_reg_waddr[ADDR_WIDTH-1:2], usr_reg_wdata);
        end
    end
end

always @(posedge clk) begin
    if (usr_reg_ren) begin
            usr_reg_rdata <= reg_file[usr_reg_raddr[ADDR_WIDTH-1:2]];
        end
end


always @(posedge clk) begin
    if (s_axil_rvalid) begin
        $display("Read data is %x", s_axil_rdata);
        if (s_axil_rdata== WR_REG_DATA) begin
            $display("Verification done\n");
        end
    end
end


task wr_addr;
    input [ADDR_WIDTH-1:0] w_addr;
    begin
        s_axil_awaddr <= 0;
        s_axil_awvalid <= 0;
        s_axil_awprot <= 0;

        @(posedge clk);
        s_axil_awvalid <= 1;
        s_axil_awaddr <= w_addr;

        wait(s_axil_awready);
        @(posedge clk);
        s_axil_awvalid <= 0;
    end
endtask

task wr_data;
    input [DATA_WIDTH-1:0]  w_data;
    begin
        s_axil_wvalid <= 0;
        s_axil_wdata <= 0;
        s_axil_wvalid <= 0;

        @(posedge clk);
        s_axil_wvalid <= 1;
        s_axil_wdata <= w_data;
        wait(s_axil_wready);
        @(posedge clk);
        s_axil_wvalid <= 0;
    end
endtask

task wait_resp;
    begin
        s_axil_bready <= 0;
        @(posedge clk);
        @(posedge clk);
        s_axil_bready <= 1;
        wait(s_axil_bready);
        @(posedge clk);
        $display("Write response received\n");
    end
endtask


task read_addr;
    input [ADDR_WIDTH-1:0] r_addr;
    begin
        s_axil_araddr <= 0;
        s_axil_arvalid <= 0;
        @(posedge clk);
        s_axil_araddr <= r_addr;
        s_axil_arvalid <= 1;

        wait(s_axil_arready);
        @(posedge clk);
        s_axil_arvalid <= 0;
    end
endtask

task read_data;
    //output [DATA_WIDTH-1] rd_data;
    begin
        s_axil_rready <= 0;
        @(posedge clk);
        s_axil_rready <= 1;
        @(s_axil_rvalid);
        @(posedge clk);
        s_axil_rready <= 0;
    end
endtask




axil_to_usr_reg # (
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) axil_to_usr_reg_i (
    .clk(clk),
    .rst(rst),
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
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    
    .usr_reg_wen(usr_reg_wen),
    .usr_reg_waddr(usr_reg_waddr),
    .usr_reg_wdata(usr_reg_wdata),
    .usr_reg_ren(usr_reg_ren),
    .usr_reg_raddr(usr_reg_raddr),
    .usr_reg_rdata(usr_reg_rdata)

);





endmodule
