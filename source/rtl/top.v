module top (
    input           clk50m_in,
    input           rstn,

    input [3:0]     eth_rxd,
    input           eth_rx_dv,
    input           eth_rx_clk,

    output [3:0]    eth_txd,
    output          eth_tx_en,
    output          eth_gtx_clk,

    output          eth_mdc,
    inout           eth_mdio,
    output          eth_reset_n,
    
    // LED
    output          c_pl_led131, // core board LED
    output          c_pl_led141, // core board LED
    //ADC0
    input [5:0]     adc0_din_p,
    input [5:0]     adc0_din_n,
    input           adc0_or_p,
    input           adc0_or_n,
    input           adc0_dco_p,
    input           adc0_dco_n,
    output          adc0_pd,
    output          adc0_cs_n,
    //ADC1 
    input [5:0]     adc1_din_p,
    input [5:0]     adc1_din_n,
    input           adc1_or_p,
    input           adc1_or_n,
    input           adc1_dco_p,
    input           adc1_dco_n,
    output          adc1_pd,
    output          adc1_cs_n,

    //AD9517
    output          ad9517_reset_n,   
    output          ad9517_pd_n,
    output          ad9517_ref_sel,
    output          ad9517_sync_n,
    output          ad9517_cs_n,


    //output          spi_cs_n,
    output          spi_sclk,
    inout           spi_sdio,

    // iic
    inout           iic_sda,
    inout           iic_scl,

    //trig
    input           trig_in,
    output          trig_d,
    output          trig_rst,

    //DDR 

    input           sys_clk_200m_p,
    input           sys_clk_200m_n,

    // output GPIO
    output          hp_gpio0, //SMA3
    output          hp_gpio1, //SMA4
    output          hp_gpio2, //SMA5
    output          hp_clk //SMA6
);
localparam MOSI_DATA_WIDTH = 24;
localparam MISO_DATA_WIDTH = 8;
localparam INSTR_HEADER_LEN = 16;

localparam AD5339_DEVICE_ADDR = 7'b0001100;

wire        mdio_t;
wire        mdio_i;
wire        mdio_o;
wire        locked;
wire        clk_200m;
wire        clk_20m;
wire        clk_800m;
wire    sys_clk_100m;
wire    sys_clk_locked;
wire    sys_clk_200m;
/*
wire        spi_mosi;
wire        spi_miso;
wire        spi_oe, spi_oe_n;
reg [5:0]   cnt;
wire        spi_clk;
reg         spi_wr_cmd;
reg         spi_rd_cmd;
wire        spi_busy;
reg [MOSI_DATA_WIDTH-1:0] spi_wr_data;
wire [MISO_DATA_WIDTH:0]  spi_rd_data;
reg         cfg_start;
wire        cfg_start_vio;
reg         cfg_start_r;
*/
wire        rst;
wire        device_cfg_done;
wire        device_cfg_start;
wire        soft_rst;

// --------------------------------------
// ADC BRAM

wire [31:0] adc0_bram_addr;
wire        adc0_bram_clk;
wire [31:0] adc0_bram_din;
wire [31:0] adc0_bram_dout;
wire        adc0_bram_ena;
wire        adc0_bram_rst;
wire        adc0_bram_wea;



assign eth_mdio = ~mdio_t ? mdio_o : 1'bz;
assign mdio_i = eth_mdio;

assign ad9517_reset_n = 1'b1;
assign ad9517_pd_n = 1'b1;
assign ad9517_ref_sel = 1'b0; // Not used in differential clock. Controlled by REG 0x1c
//assign ad9517_cs_n = spi_cs_n;
assign ad9517_sync_n = 1'b1;

// ADC0
assign adc0_pd = 1'b0;
// ADC0
assign adc1_pd = 1'b0;

// LED

assign c_pl_led131 = 1'b0;
assign c_pl_led141 = 1'b0;

assign rst = ~rstn;

clk_wiz_sys clk_wiz_sys_i (
    .clk_200m(clk_200m),
    .clk_20m(clk_20m),
    .resetn(rstn), 
    .locked(locked),
    .clk50m_in(clk50m_in)
); 

vio_sys vio_sys_inst (
    .clk(clk50m_in),
    .probe_in0(locked)
);

//---------------------------------------------------
// data mover signals
// --------------------------------------------------
wire            hp0_arready;
wire            hp0_awready;
wire [5:0]      hp0_bid;
wire [1:0]      hp0_bresp;
wire            hp0_bvalid;
wire [63:0]     hp0_rdata;
wire [5:0]      hp0_rid;
wire            hp0_rlast;
wire [1:0]      hp0_rresp;
wire            hp0_rvalid;
wire            hp0_wready;
 
wire [31:0]     hp0_araddr;
wire [1:0]      hp0_arburst;
wire [3:0]      hp0_arcache;
wire [3:0]      hp0_arid;
wire [3:0]      hp0_arlen;
wire [1:0]      hp0_arlock;
wire [2:0]      hp0_arprot;
wire [3:0]      hp0_arqos;
wire [2:0]      hp0_arsize;
wire            hp0_arvalid;

wire [31:0]     hp0_awaddr;
wire [1:0]      hp0_awburst;
wire [3:0]      hp0_awcache;
wire [3:0]      hp0_awid;
wire [3:0]      hp0_awlen;
wire [1:0]      hp0_awlock;
wire [2:0]      hp0_awprot;
wire [3:0]      hp0_awqos;
wire [2:0]      hp0_awsize;
wire            hp0_awvalid;
wire            hp0_bready;
wire            hp0_rready;
wire [63:0]     hp0_wdata;
wire [5:0]      hp0_wid;
wire            hp0_wlast;
wire [7:0]      hp0_wstrb;
wire            hp0_wvalid;

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

system bd_system(
    .clk_300_o(),
    .reset_300_o(),
    //AXI4 read addr
    .hp0_araddr(hp0_araddr),
    .hp0_arburst(hp0_arburst),
    .hp0_arcache(hp0_arcache),
    .hp0_arid(hp0_arid),
    .hp0_arlen(hp0_arlen),
    .hp0_arlock(hp0_arlock),
    .hp0_arprot(hp0_arprot),
    .hp0_arqos(hp0_arqos),
    .hp0_arready(hp0_arready),
    .hp0_arsize(hp0_arsize),
    .hp0_arvalid(hp0_arvalid),
    //AXI4 write addr
    .hp0_awaddr(hp0_awaddr),
    .hp0_awburst(hp0_awburst),
    .hp0_awcache(hp0_awcache),
    .hp0_awid(hp0_awid),
    .hp0_awlen(hp0_awlen),
    .hp0_awlock(hp0_awlock),
    .hp0_awprot(hp0_awprot),
    .hp0_awqos(hp0_awqos),
    .hp0_awready(hp0_awready),
    .hp0_awsize(hp0_awsize),
    .hp0_awvalid(hp0_awvalid),

    .hp0_bid(hp0_bid),
    .hp0_bready(hp0_bready),
    .hp0_bresp(hp0_bresp),
    .hp0_bvalid(hp0_bvalid),
    //AXI4 read data interface
    .hp0_rdata(hp0_rdata),
    .hp0_rid(hp0_rid),
    .hp0_rlast(hp0_rlast),
    .hp0_rready(hp0_rready),
    .hp0_rresp(hp0_rresp),
    .hp0_rvalid(hp0_bvalid),
    //AXI4 write data interface
    .hp0_wdata(hp0_wdata),
    .hp0_wid(hp0_wid),
    .hp0_wlast(hp0_wlast),
    .hp0_wready(hp0_ready),
    .hp0_wstrb(hp0_wstrb),
    .hp0_wvalid(hp0_wvalid),
    //ADC BRAM
    .adc_bram_addr(adc0_bram_addr),
    .adc_bram_clk(adc0_bram_clk),
    .adc_bram_din(adc0_bram_din),
    .adc_bram_dout(adc0_bram_dout),
    .adc_bram_en(adc0_bram_ena),
    .adc_bram_rst(adc0_bram_rst),
    .adc_bram_we(adc0_bram_wea)
    
);

/*
always @(posedge clk_20m) begin
    cfg_start_r <= cfg_start_vio;
    cfg_start <= ~cfg_start_vio & cfg_start_r;
end
*/
device_cfg #(
    .MOSI_DATA_WIDTH( MOSI_DATA_WIDTH),
    .MISO_DATA_WIDTH(MISO_DATA_WIDTH),
    .INSTR_HEADER_LEN(INSTR_HEADER_LEN)

)device_cfg_inst (
    .clk_20m(clk_20m),
    .rst(rst),
    .soft_rst(soft_rst),

    .i_cfg_start(device_cfg_start),
    .i_ad9517_locked(sys_clk_locked),
    .o_cfg_done(device_cfg_done),
    .ad9517_cs_n(ad9517_cs_n),
    .adc0_cs_n(adc0_cs_n),
    .adc1_cs_n(adc1_cs_n),
    .spi_sclk(spi_sclk),
    .spi_sdio(spi_sdio)
);

vio_0 vio_0_cfg (
    .clk(clk_20m),                // input wire clk
    .probe_in0(device_cfg_done),
    .probe_out0(device_cfg_start),  // output wire [0 : 0] probe_out0
    .probe_out1(soft_rst) // output wire [0 : 0] probe_out1
    
);

// IIC 
wire           iic_busy;
wire [15:0]    ad5339_wr_data;
wire           ad5339_wr_req;
wire           ad5339_wr_ack;
wire           ad5339_wr_done;

wire           ad5339_rd_req;
//wire [7:0]     ad5339_rd_addr;
wire           ad5339_rd_ack;
wire [15:0]    ad5339_rd_data;
wire           ad5339_rd_done;

// ------------------------------------------- AD5339 ------------------------------------
ad5339_cfg ad5339_cfg_i (
    .sys_clk(clk_20m),
    .sys_rst(rst),
    .device_addr(AD5339_DEVICE_ADDR),
    .iic_wr_data(ad5339_wr_data),
    .iic_wr_req(ad5339_wr_req),
    .iic_wr_ack(ad5339_wr_ack),
    .iic_wr_done(ad5339_wr_done),

    .iic_rd_req(ad5339_rd_req),
   // .iic_rd_addr(),
    .iic_rd_ack(ad5339_rd_ack),
    .iic_rd_done(ad5339_rd_done),
    .iic_rd_data(ad5339_rd_data),
    .iic_busy_o(iic_busy),
    .scl(iic_scl),
    .sda(iic_sda)

);
/*
ila_ad5339 ila_ad5339_i (
	.clk(clk_20m), // input wire clk
	.probe0(ad5339_wr_data), // input wire [15:0]  probe0  
	.probe1(ad5339_rd_data), // input wire [15:0]  probe1 
	.probe2(ad5339_wr_req), // input wire [0:0]  probe2 
	.probe3(ad5339_wr_ack), // input wire [0:0]  probe3 
	.probe4(ad5339_wr_done), // input wire [0:0]  probe4 
	.probe5(ad5339_rd_req), // input wire [0:0]  probe5 
	.probe6(ad5339_rd_ack), // input wire [0:0]  probe6 
	.probe7(ad5339_rd_done), // input wire [0:0]  probe7 
	.probe8(iic_busy) // input wire [0:0]  probe8
);
*/
vio_ad5339 vio_ad5339_i (
  .clk(clk_20m),                // input wire clk
  .probe_out0(ad5339_wr_req),  // output wire [0 : 0] probe_out0
  .probe_out1(ad5339_rd_req),  // output wire [0 : 0] probe_out1
  .probe_out2(ad5339_wr_data)  // output wire [15 : 0] probe_out2
);

// -------------------------------------- trig ----------------------------------------

trig trig_i (
    .sys_clk(clk_20m),
    .sys_rst(rst),
    .trig_in(trig_in),
    .trig_d_o(trig_d),
    .trig_rst_o(trig_rst)

);


/*
IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DIFF_SSTL15")     // Specify the input I/O standard
) IBUFDS_inst (
    .O(sys_clk_100m),  // Buffer output
    .I(sys_clk_100m_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(sys_clk_100m_n) // Diff_n buffer input (connect directly to top-level port)
);

clk_wiz_ddr clk_wiz_ddr_i (
    // Clock out ports
    .clk_200(sys_clk_200m),     // output clk_out1
    .clk_800(clk_800m),
    // Status and control signals
    .reset(~rstn), // input reset
    .locked(sys_clk_locked),       // output locked
    // Clock in ports
    .clk_in1(sys_clk_100m)
);
*/

// VCO = ref_in * CLKBOUT_MULT_F/DIVCLK_DIVIDE
// clk0 = VCO / CLK0_DIVIDE
// clk1 = VCO / CLK1_DIVIDE
//wire    sys_clk_200m;
wire    clk_125m;
wire    clk_500m;
IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DIFF_SSTL15")     // Specify the input I/O standard
) IBUFDS_sys_clk_200m (
    .O(sys_clk_200m),  // Buffer output
    .I(sys_clk_200m_p),  // Diff_p buffer input (connect directly to top-level port)
    .IB(sys_clk_200m_n) // Diff_n buffer input (connect directly to top-level port)
);

clock_gen #(
    .REF_CLK_PERIOD(5.0),
    .CLKBOUT_MULT_F(5.0),
    .DIVCLK_DIVIDE(1),
    .CLK0_DIVIDE(8.0),
    .CLK1_DIVIDE(2)
) clock_gen_inst (
    .ref_clk(sys_clk_200m),
    .rst(rst),

    .locked_o(sys_clk_locked),
    .clk0_o(clk_125m),
    .clk1_o(clk_500m)

);

vio_sys vio_sys_i (
  .clk(sys_clk_200m),              // input wire clk
  .probe_in0(sys_clk_locked)  // input wire [0 : 0] probe_in0
);

// --------------------- ADC ---------------------------
ad9434_data ad9434_data_0(
    .rst(rst),
    .clk_200m(clk_200m),
    .i_trig(pulse_gen_trig),
    .i_us_capture(10'd10),
    .i_adc0_din_p(adc0_din_p),
    .i_adc0_din_n(adc0_din_n),
    .i_adc0_or_p(adc0_or_p),
    .i_adc0_or_n(adc0_or_n),
    .i_adc0_dco_p(adc0_dco_p),
    .i_adc0_dco_n(adc0_dco_n),
    
    .o_bram_clk(adc0_bram_clk),
    .o_bram_rst(adc0_bram_rst),
    .o_bram_addr(adc0_bram_addr),
    .o_bram_data(adc0_bram_din),
    .o_bram_wea(adc0_bram_wea),
    .o_bram_ena(adc0_bram_ena)

);

ad9434_data ad9434_data_1(
    .rst(rst),
    .clk_200m(clk_200m),
    .i_trig(pulse_gen_trig),
    .i_us_capture(10'd10),
    .i_adc0_din_p(adc1_din_p),
    .i_adc0_din_n(adc1_din_n),
    .i_adc0_or_p(adc1_or_p),
    .i_adc0_or_n(adc1_or_n),
    .i_adc0_dco_p(adc1_dco_p),
    .i_adc0_dco_n(adc1_dco_n)
);

// -------------------------- HP GPIO ---------------------------

  ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_HP_CLK (
      .Q(hp_clk),   // 1-bit DDR output
      .C(clk_20m),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

// ------------------------ pulse generator --------------------
wire [15:0]    gap_us;
wire [10:0]    pulse_num;
wire [10:0]    pulse_width;
wire           pulse_gen_start;
wire           pulse_gen_trig;
wire           pulse_gen_done;

pulse_gen pulse_gen_inst (
    .clk(clk_500m),
    .clk_div(clk_125m),
    .rst(rst),
    .pulse_width_i(pulse_width),
    .pulse_num_i(pulse_num),
    .gap_us_i(gap_us),
    .start_i(pulse_gen_start),
    .trig_o(pulse_gen_trig),
    .done_o(pulse_gen_done),
    .q(hp_gpio0)

);

vio_pulse_gen vio_pulse_gen_inst (
  .clk(clk_125m),                // input wire clk
  .probe_in0(pulse_gen_trig),
  .probe_in1(pulse_gen_done),
  .probe_out0(pulse_width),  // output wire [10 : 0] probe_out0
  .probe_out1(pulse_num),  // output wire [10 : 0] probe_out1
  .probe_out2(gap_us),  // output wire [15 : 0] probe_out2
  .probe_out3(pulse_gen_start)  // output wire [0 : 0] probe_out3
);

//--------------------------------------------
// data mover
//--------------------------------------------

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




endmodule
