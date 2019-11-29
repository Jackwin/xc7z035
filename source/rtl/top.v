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
    output          adc0_pd_n,
    output          adc0_cs_n,
    //ADC1 
    input [5:0]     adc1_din_p,
    input [5:0]     adc1_din_n,
    input           adc1_or_p,
    input           adc1_or_n,
    input           adc1_dco_p,
    input           adc1_dco_n,
    output          adc1_pd_n,
    output          adc1_cs_n,

    //AD9517
    output          ad9517_reset_n,   
    output          ad9517_pd_n,
    output          ad9517_ref_sel,
    output          ad9517_sync_n,
    output          ad9517_cs_n,


    //output          spi_cs_n,
    output          spi_sclk,
    inout           spi_sdio
);

wire    mdio_t;
wire    mdio_i;
wire    mdio_o;
wire    locked;
wire    clk_200m;
wire    clk_20m;

assign eth_mdio = ~mdio_t ? mdio_o : 1'bz;
assign mdio_i = eth_mdio;

assign ad9517_reset_n = 1'b1;
assign ad9517_pd_n = 1'b1;
assign ad9517_ref_sel = 1'b0; // Not used in differential clock. Controlled by REG 0x1c
assign ad9517_cs_n = spi_cs_n;
assign ad9517_sync_n = 1'b1;

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
    .clk50m_in(clk50m_in)); 
/*
system bd_system(
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
    );
*/

ila_0 ila_clk (
	.clk(clk50m_in), // input wire clk
	.probe0(locked) // input wire [0:0] probe0
);

system_wrapper system_wrapper_i();

ad9517_cfg ad9517_cfg_i(
    .clk(clk_200m),
    .rst(~rstn),
    .o_spi_wr_cmd(spi_wr_cmd),
    .o_spi_rd_cmd(spi_rd_cmd),
    .o_spi_wr_data(spi_wr_data),
    .i_spi_rd_data(spi_rd_data),
    .i_spi_busy(spi_busy),
    .i_cfg_start(cfg_start)
);


wire        spi_mosi;
wire        spi_miso;
wire        spi_oe;
reg [2:0]   cnt;
wire        spi_clk;
wire        spi_wr_cmd;
wire        spi_rd_cmd;
wire        spi_busy;
wire [23:0]  spi_wr_data;
wire [7:0]  spi_rd_data;
always @(posedge clk_20m) begin
    if (~rstn) begin
        cnt <= 'h0;
    end
    else begin
        cnt <= cnt + 1'd1;
    end
end

assign spi_clk = cnt[2];

spi_master #(
      .CPOL( 0 ),
      .FREE_RUNNING_SPI_CLK( 0 ),
      .MOSI_DATA_WIDTH( 24 ),
      .WRITE_MSB_FIRST( 1 ),
      .MISO_DATA_WIDTH( 8 ),
      .READ_MSB_FIRST( 1 )
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
      .oe_pin(spi_oe),
      .miso_pin(spi_miso)
    );

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
endmodule
