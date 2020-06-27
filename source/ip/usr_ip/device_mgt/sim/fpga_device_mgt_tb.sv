`timescale 1ns/1ps

module fpga_device_mgt_tb ();

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
localparam INTR_MSG_WIDTH = 8;
localparam TEMPER_WIDTH = 12;

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

logic [DATA_WIDTH-1:0]      status_reg_data;
logic                       status_reg_valid;
logic [DATA_WIDTH-1:0]      ctrl_reg_data;
logic                       ctrl_reg_valid;
logic                       intr_ready;
logic [INTR_MSG_WIDTH-1:0]  intr_msg;
logic [TEMPER_WIDTH-1:0]    temper;
logic                       temper_valid;
logic [DATA_WIDTH-1:0]      version;
logic                       soft_rst;

logic                       soft_rst_r;

always_ff @(posedge clk) begin
    soft_rst_r <= soft_rst;
end

initial begin
    temper  <= 0;
    temper_valid <= 0;
    intr_msg <= 0;
    version <= 32'hf8d5a5c8;
    #200;
    @(posedge clk);
    temper <= 12'h5ff;
    temper_valid <= 1;

    read_addr(32'h4);
    read_data();
    wait(s_axil_rvalid & (s_axil_rdata== version));
    $display("Version check done\n");

    read_addr(32'h8);
    read_data();
    wait(s_axil_rvalid & (s_axil_rdata== temper));
    $display("temp check done\n");

    read_addr(32'h100);
    read_data();
    wait(s_axil_rvalid & (s_axil_rdata== 32'hf7f7f7f7));
    $display("ctrl check done\n");

    wr_addr(32'ha);
    wr_data(32'h1);
    wait(soft_rst_r & ~soft_rst);
    $display("soft reset");

    //generate intr

    @(posedge clk);
    intr_msg <= 1;
    @(posedge clk);
    intr_msg <= 0;

    read_addr(32'h0);
    read_data();
    wait(s_axil_rvalid & s_axil_rdata == 1);
    $display("Interrupt");
    #40;
    $stop;

end

fpga_device_mgt_top # ( 
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .TEMPER_WIDTH(TEMPER_WIDTH),
    .INTR_MSG_WIDTH(INTR_MSG_WIDTH)

) fpga_device_mgt_top_inst (

    .o_status_reg_data(status_reg_data),
    .o_status_reg_valid(status_reg_valid),
    .o_intr_ready(intr_ready),
    .i_intr_msg(intr_msg),

    .i_temper(temper),
    .i_temper_valid(temper_valid),
    .i_version(version),
    .soft_rst(soft_rst),

    .usr_reg_wen(usr_reg_wen),
    .usr_reg_waddr(usr_reg_waddr),
    .usr_reg_wdata(usr_reg_wdata),
    .usr_reg_ren(usr_reg_ren),
    .usr_reg_raddr(usr_reg_raddr),
    .usr_reg_rdata(usr_reg_rdata),
    
    .s_axil_aclk(clk),
    .s_axil_aresetn(~rst),
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

usr_reg_rd_switch # (
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)usr_reg_rd_switch_inst (
    .clk(clk),
    .rst(rst),
    .i_usr_reg_rd(usr_reg_ren),
    .i_usr_reg_addr(usr_reg_raddr),
    .o_usr_reg_data(usr_reg_rdata),

    .i_status_reg_data(status_reg_data),
    .i_status_reg_valid(status_reg_valid),

    .i_ctrl_reg_data(ctrl_reg_data),
    .i_ctrl_reg_valid(ctrl_reg_valid)
);


//---------------------- ctrl reg ------------------

always_ff @(posedge clk) begin
    if (rst) begin
        ctrl_reg_valid <= 0;   
    end else if (usr_reg_ren & (usr_reg_raddr == 32'h100) & ~ctrl_reg_valid) begin
        ctrl_reg_data <= 32'hf7f7f7f7;
        ctrl_reg_valid <= 1;
    end else begin
        ctrl_reg_valid <= 0;
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


endmodule