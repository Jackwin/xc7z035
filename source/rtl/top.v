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
    output reg      adc0_cs_n,
    //ADC1 
    input [5:0]     adc1_din_p,
    input [5:0]     adc1_din_n,
    input           adc1_or_p,
    input           adc1_or_n,
    input           adc1_dco_p,
    input           adc1_dco_n,
    output          adc1_pd,
    output reg     adc1_cs_n,

    //AD9517
    output          ad9517_reset_n,   
    output          ad9517_pd_n,
    output          ad9517_ref_sel,
    output          ad9517_sync_n,
    output reg      ad9517_cs_n,


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

 clk_wiz_sys clk_wiz_sys_i
   (
    // Clock out ports
    .clk_200m(clk_200m),     // output clk_200m
    .clk_20m(clk_20m),
    // Status and control signals
    .resetn(rstn), // input resetn
    .locked(locked),       // output locked
   // Clock in ports
    .clk50m_in(clk50m_in)
    ); 

system bd_system(
/*
    .rgmii_eth_rd(rgmii_eth_rd),
    .rgmii_eth_rx_ctl(rgmii_eth_rx_ctl),
    .rgmii_eth_rxc(rgmii_eth_rxc),
    .rgmii_eth_td(rgmii_eth_td),
    .rgmii_eth_tx_ctl(rgmii_eth_tx_ctl),
    .rgmii_eth_txc(rgmii_eth_txc),
    .eth_mdio_mdc(eth_mdio_mdc),
    .eth_mdio_mdio_i(mdio_i),
    .eth_mdio_mdio_o(mdio_o),
    .eth_mdio_mdio_t(mdio_t)
    */
    );


always @(posedge clk_20m) begin
    cfg_start_r <= cfg_start_vio;
    cfg_start <= ~cfg_start_vio & cfg_start_r;
end

//system_wrapper system_wrapper_i();

wire    ad9517_spi_wr_cmd;
wire    ad9517_spi_rd_cmd;
wire [MOSI_DATA_WIDTH-1:0] ad9517_spi_wr_data;
wire [MISO_DATA_WIDTH:0]  ad9517_spi_rd_data;
wire    ad9517_spi_busy;
wire    ad9517_cfg_start;
wire    ad9517_cfg_go;

ad9517_cfg ad9517_cfg_i(
    .clk(clk_20m),
    .rst(~rstn),
    .o_spi_wr_cmd(ad9517_spi_wr_cmd),
    .o_spi_rd_cmd(ad9517_spi_rd_cmd),
    .o_spi_wr_data(ad9517_spi_wr_data),
    .i_spi_rd_data(ad9517_spi_rd_data),
    .i_spi_busy(ad9517_spi_busy),
    .i_cfg_start(ad9517_cfg_start)
);

assign ad9517_spi_rd_data = spi_rd_data;
assign ad9517_spi_busy = spi_busy;

wire    adc0_spi_wr_cmd;
wire    adc0_spi_rd_cmd;
wire [MOSI_DATA_WIDTH-1:0] adc0_spi_wr_data;
wire [MISO_DATA_WIDTH:0]  adc0_spi_rd_data;
wire    adc0_spi_busy;
wire    adc0_cfg_start;
wire    adc0_cfg_go;

wire    adc1_spi_wr_cmd;
wire    adc1_spi_rd_cmd;
wire [MOSI_DATA_WIDTH-1:0] adc1_spi_wr_data;
wire [MISO_DATA_WIDTH:0]  adc1_spi_rd_data;
wire    adc1_spi_busy;
wire    adc1_cfg_start;
wire    adc1_cfg_go;

adc_cfg adc0_cfg(
    .clk(clk_20m),
    .rst(~rstn),
    .o_spi_wr_cmd(adc0_spi_wr_cmd),
    .o_spi_rd_cmd(adc0_spi_rd_cmd),
    .o_spi_wr_data(adc0_spi_wr_data),
    .i_spi_rd_data(adc0_spi_rd_data),
    .i_spi_busy(adc0_spi_busy),
    .i_cfg_start(adc0_cfg_start),
    .o_cfg_go(adc0_cfg_go)
);

adc_cfg adc1_cfg(
    .clk(clk_20m),
    .rst(~rstn),
    .o_spi_wr_cmd(adc1_spi_wr_cmd),
    .o_spi_rd_cmd(adc1_spi_rd_cmd),
    .o_spi_wr_data(adc1_spi_wr_data),
    .i_spi_rd_data(adc1_spi_rd_data),
    .i_spi_busy(adc1_spi_busy),
    .i_cfg_start(adc1_cfg_start),
    .o_cfg_go(adc1_cfg_go)
);

assign adc0_spi_rd_data = spi_rd_data;
assign adc0_spi_busy = spi_busy;
assign adc1_spi_rd_data = spi_rd_data;
assign adc1_spi_busy = spi_busy;

always @(*) begin
    if (adc0_cfg_go) begin
        spi_wr_cmd = adc0_spi_wr_cmd;
        spi_rd_cmd = adc0_spi_rd_cmd;
        spi_wr_data = adc0_spi_wr_data;
        adc0_cs_n = spi_cs_n;
        ad9517_cs_n = 1'b1;
        adc1_cs_n = 1'b1;
    end
    else if (adc1_cfg_go) begin
        spi_wr_cmd = adc1_spi_wr_cmd;
        spi_rd_cmd = adc1_spi_rd_cmd;
        spi_wr_data = adc1_spi_wr_data;
        adc1_cs_n = spi_cs_n;
        ad9517_cs_n = 1'b1;
        adc0_cs_n = 1'b1;
    end
    else begin
        spi_wr_cmd = ad9517_spi_wr_cmd;
        spi_rd_cmd = ad9517_spi_rd_cmd;
        spi_wr_data = ad9517_spi_wr_data;
        ad9517_cs_n = spi_cs_n;
        adc0_cs_n = 1'b1;
        adc1_cs_n = 1'b1;
    end
end


always @(posedge clk_20m) begin
    if (~rstn) begin
        cnt <= 'h0;
    end
    else begin
        cnt <= cnt + 1'd1;
    end
end

assign spi_clk = cnt[5];

spi_master #(
      .CPOL( 0 ),
      .FREE_RUNNING_SPI_CLK( 1 ),
      .MOSI_DATA_WIDTH( MOSI_DATA_WIDTH),
      .WRITE_MSB_FIRST( 1 ),
      .MISO_DATA_WIDTH( MISO_DATA_WIDTH ),
      .READ_MSB_FIRST( 1 ),
      .INSTR_HEADER_LEN(INSTR_HEADER_LEN)
    ) SM1 (
      .clk(clk_20m),
      .nrst(rstn  ),
      .spi_clk(spi_clk),
      .spi_wr_cmd(spi_wr_cmd ),
      .spi_rd_cmd(spi_rd_cmd ),
      .spi_busy(spi_busy),
      .mosi_data(spi_wr_data),
      .miso_data(spi_rd_data),
      .clk_pin(spi_sclk),
      .ncs_pin(spi_cs_n),
      .mosi_pin(spi_mosi),
      .oe_pin(spi_oe_n),
      .miso_pin(spi_miso)
    );

assign spi_oe = ~spi_oe_n;

IOBUF #(
    .DRIVE(12), // Specify the output drive strength
    .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
    .IOSTANDARD("DEFAULT"), // Specify the I/O standard
    .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_spi_mosi (
    .O(spi_miso),     // Buffer output
    .IO(spi_sdio),   // Buffer inout port (connect directly to top-level port)
    .I(spi_mosi),     // Buffer input
    .T(spi_oe)      // 3-state enable input, high=input, low=output
   );

ila_spi ila_spi_i (
	.clk(spi_clk), // input wire clk
	.probe0(spi_cs_n), // input wire [0:0]  probe0  
	.probe1(spi_mosi), // input wire [0:0]  probe1 
	.probe2(spi_oe), // input wire [0:0]  probe2 
	.probe3(spi_miso), // input wire [0:0]  probe3 
	.probe4(spi_sclk) // input wire [0:0]  probe4
);

vio_0 vio_0_cfg (
  .clk(clk_200m),                // input wire clk
  .probe_out0(ad9517_cfg_start),  // output wire [0 : 0] probe_out0
  .probe_out1(adc0_cfg_start),  // output wire [0 : 0] probe_out1
  .probe_out2(adc1_cfg_start)
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
    .sys_rst(~rstn),
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
    .sys_rst(~rstn),
    .trig_in(trig_in),
    .trig_d_o(trig_d),
    .trig_rst_o(trig_rst)

);

wire    sys_clk_100m;
wire    sys_clk_locked;
wire    sys_clk_200m;
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
wire    sys_clk_200m;
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
    .rst(~rstn),

    .locked_o(sys_clk_locked),
    .clk0_o(clk_125m),
    .clk1_o(clk_500m)

);

vio_sys vio_sys_i (
  .clk(sys_clk_200m),              // input wire clk
  .probe_in0(sys_clk_locked)  // input wire [0 : 0] probe_in0
);

// --------------------- ADC ---------------------------

/*
wire    dummy;
 top5x2_7to1_ddr_rx # (
     .D(6),
     .N(1)

 ) adc0 (
	.reset(~rstn),					// reset (active high)
    .refclkin(clk_200m),				// Reference clock for input delay control
    .clkin_p(adc0_dco_p),  
    .clkin_n(adc0_dco_n),			// lvds channel 1 clock input
    .datain_p(adc0_din_p), 
    .datain_n(adc0_din_n),			// lvds channel 1 data inputs
    .dummy(dummy)
) ; 				// Dummy output for test
*/

ad9434_data ad9434_data_0(
    .rst(~rstn),
    .clk_200m_in(clk_200m),
    .adc0_din_p(adc0_din_p),
    .adc0_din_n(adc0_din_n),
    .adc0_or_p(adc0_or_p),
    .adc0_or_n(adc0_or_n),
    .adc0_dco_p(adc0_dco_p),
    .adc0_dco_n(adc0_dco_n)
);

ad9434_data ad9434_data_1(
    .rst(~rstn),
    .clk_200m_in(clk_200m),
    .adc0_din_p(adc1_din_p),
    .adc0_din_n(adc1_din_n),
    .adc0_or_p(adc1_or_p),
    .adc0_or_n(adc1_or_n),
    .adc0_dco_p(adc1_dco_p),
    .adc0_dco_n(adc1_dco_n)
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
pulse_gen pulse_gen_inst (
    .clk(clk_500m),
    .clk_div(clk_125m),
    .rst(~rstn),
    .q(hp_gpio0)

);

endmodule
