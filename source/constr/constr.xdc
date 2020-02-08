### reference clock
set_property PACKAGE_PIN J14 [get_ports clk50m_in]
set_property IOSTANDARD LVCMOS18 [get_ports clk50m_in]

### reset
set_property PACKAGE_PIN D15 [get_ports rstn]
set_property IOSTANDARD LVCMOS18 [get_ports rstn]

### PL ethernet

set_property PACKAGE_PIN D11 [get_ports eth_gtx_clk]
set_property PACKAGE_PIN B12 [get_ports eth_tx_en]

set_property PACKAGE_PIN E10 [get_ports {eth_txd[0]}]
set_property PACKAGE_PIN G10 [get_ports {eth_txd[1]}]
set_property PACKAGE_PIN B11 [get_ports {eth_txd[2]}]
set_property PACKAGE_PIN C11 [get_ports {eth_txd[3]}]


set_property PACKAGE_PIN B16 [get_ports eth_mdc]
set_property PACKAGE_PIN B17 [get_ports eth_mdio]
set_property PACKAGE_PIN A17 [get_ports eth_reset_n]

set_property PACKAGE_PIN F15 [get_ports eth_rx_clk]
set_property PACKAGE_PIN B15 [get_ports eth_rx_dv]

set_property PACKAGE_PIN A14 [get_ports {eth_rxd[0]}]
set_property PACKAGE_PIN B14 [get_ports {eth_rxd[1]}]
set_property PACKAGE_PIN A13 [get_ports {eth_rxd[2]}]
set_property PACKAGE_PIN A12 [get_ports {eth_rxd[3]}]

set_property IOSTANDARD LVCMOS18 [get_ports {eth_txd[*]}]

set_property IOSTANDARD LVCMOS18 [get_ports eth_gtx_clk]
#set_property IOSTANDARD LVCMOS18 [get_ports {eth_rx_clk}]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports eth_rx_dv]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports eth_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports eth_tx_en]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_rxd[*]}]


### ADC1
set_property PACKAGE_PIN AB26 [get_ports {adc1_din_p[0]}]
set_property PACKAGE_PIN AC26 [get_ports {adc1_din_n[0]}]
set_property PACKAGE_PIN AD25 [get_ports {adc1_din_p[1]}]
set_property PACKAGE_PIN AD26 [get_ports {adc1_din_n[1]}]
set_property PACKAGE_PIN AE25 [get_ports {adc1_din_p[2]}]
set_property PACKAGE_PIN AE26 [get_ports {adc1_din_n[2]}]
set_property PACKAGE_PIN AF24 [get_ports {adc1_din_p[3]}]
set_property PACKAGE_PIN AF25 [get_ports {adc1_din_n[3]}]
set_property PACKAGE_PIN AE23 [get_ports {adc1_din_p[4]}]
set_property PACKAGE_PIN AF23 [get_ports {adc1_din_n[4]}]
set_property PACKAGE_PIN AE22 [get_ports {adc1_din_p[5]}]
set_property PACKAGE_PIN AF22 [get_ports {adc1_din_n[5]}]

set_property PACKAGE_PIN AF19 [get_ports adc1_or_p]
set_property PACKAGE_PIN AF20 [get_ports adc1_or_n]

set_property PACKAGE_PIN AC23 [get_ports adc1_dco_p]
set_property PACKAGE_PIN AC24 [get_ports adc1_dco_n]

set_property PACKAGE_PIN W17 [get_ports adc1_pd_n]
set_property PACKAGE_PIN Y16 [get_ports adc1_cs_n]

set_property IOSTANDARD LVDS_25 [get_ports {adc1_din_p[*]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc1_din_n[*]}]
set_property IOSTANDARD LVDS_25 [get_ports adc1_or_p]
set_property IOSTANDARD LVDS_25 [get_ports adc1_or_n]
set_property IOSTANDARD LVDS_25 [get_ports adc1_dco_p]
set_property IOSTANDARD LVDS_25 [get_ports adc1_dco_n]

set_property IOSTANDARD LVCMOS18 [get_ports adc1_pd_n]
set_property IOSTANDARD LVCMOS18 [get_ports adc1_cs_n]


### ADC 0
set_property PACKAGE_PIN AD21 [get_ports adc0_dco_n]
set_property PACKAGE_PIN AD20 [get_ports adc0_dco_p]

set_property PACKAGE_PIN AF18 [get_ports adc0_or_n]
set_property PACKAGE_PIN AE18 [get_ports adc0_or_p]

set_property PACKAGE_PIN AB20 [get_ports {adc0_din_n[0]}]
set_property PACKAGE_PIN AA20 [get_ports {adc0_din_p[0]}]
set_property PACKAGE_PIN AD19 [get_ports {adc0_din_n[1]}]
set_property PACKAGE_PIN AD18 [get_ports {adc0_din_p[1]}]
set_property PACKAGE_PIN AC19 [get_ports {adc0_din_n[2]}]
set_property PACKAGE_PIN AC18 [get_ports {adc0_din_p[2]}]
set_property PACKAGE_PIN AB19 [get_ports {adc0_din_n[3]}]
set_property PACKAGE_PIN AA19 [get_ports {adc0_din_p[3]}]
set_property PACKAGE_PIN AA18 [get_ports {adc0_din_n[4]}]
set_property PACKAGE_PIN Y18 [get_ports {adc0_din_p[4]}]
set_property PACKAGE_PIN W19 [get_ports {adc0_din_n[5]}]
set_property PACKAGE_PIN W18 [get_ports {adc0_din_p[5]}]

set_property PACKAGE_PIN AD16 [get_ports adc0_pd]
set_property PACKAGE_PIN AB16 [get_ports adc0_cs_n]

set_property IOSTANDARD LVDS_25 [get_ports {adc0_din_p[*]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc0_din_n[*]}]
set_property IOSTANDARD LVDS_25 [get_ports adc0_or_p]
set_property IOSTANDARD LVDS_25 [get_ports adc0_or_n]
set_property IOSTANDARD LVDS_25 [get_ports adc0_dco_p]
set_property IOSTANDARD LVDS_25 [get_ports adc0_dco_n]

set_property IOSTANDARD LVCMOS18 [get_ports adc0_pd]
set_property IOSTANDARD LVCMOS18 [get_ports adc0_cs_n]

### AD9517
set_property PACKAGE_PIN W13 [get_ports ad9517_reset_n]
set_property PACKAGE_PIN Y13 [get_ports ad9517_cs_n]
set_property PACKAGE_PIN AA10 [get_ports ad9517_pd_n]
set_property PACKAGE_PIN AB11 [get_ports ad9517_ref_sel]
set_property PACKAGE_PIN AC11 [get_ports ad9517_sync_n]

set_property IOSTANDARD LVCMOS18 [get_ports ad9517_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports ad9517_cs_n]
set_property IOSTANDARD LVCMOS18 [get_ports ad9517_pd_n]
set_property IOSTANDARD LVCMOS18 [get_ports ad9517_ref_sel]
set_property IOSTANDARD LVCMOS18 [get_ports ad9517_sync_n]

### SPI
set_property PACKAGE_PIN AB15 [get_ports spi_sclk]
set_property PACKAGE_PIN AD15 [get_ports spi_sdio]
set_property IOSTANDARD LVCMOS18 [get_ports spi_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports spi_sdio]

### IIC
set_property PACKAGE_PIN AC12 [get_ports iic_sda]
set_property PACKAGE_PIN AE10 [get_ports iic_scl]
set_property IOSTANDARD LVCMOS18 [get_ports iic_sda]
set_property IOSTANDARD LVCMOS18 [get_ports iic_scl]


### LED bottom board
#set_property PACKAGE_PIN E11  [get_ports b_pl_led1]
#set_property PACKAGE_PIN C12  [get_ports b_pl_led2]
#set_property PACKAGE_PIN E12  [get_ports b_pl_led3]
#set_property PACKAGE_PIN D13  [get_ports b_pl_led4]

### LED core board
set_property PACKAGE_PIN A15 [get_ports c_pl_led131]
set_property PACKAGE_PIN C17 [get_ports c_pl_led141]
set_property IOSTANDARD LVCMOS18 [get_ports c_pl_led131]
set_property IOSTANDARD LVCMOS18 [get_ports c_pl_led141]

#set_location_assignment PIN_G16 -to pl_key2
#set_location_assignment PIN_G15 -to pl_key1

### trig
set_property PACKAGE_PIN AB10 [get_ports trig_in]
set_property PACKAGE_PIN AF15 [get_ports trig_d]
set_property PACKAGE_PIN AC14 [get_ports trig_rst]

set_property IOSTANDARD LVCMOS18 [get_ports trig_in]
set_property IOSTANDARD LVCMOS18 [get_ports trig_d]
set_property IOSTANDARD LVCMOS18 [get_ports trig_rst]

### DDR

set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_100m_p]
set_property PACKAGE_PIN D6 [get_ports sys_clk_100m_p]
create_clock -period 10.000 [get_ports sys_clk_100m_p]



