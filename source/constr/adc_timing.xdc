create_clock -period 2.50 -name adc0_clk -waveform {0.000 1.250} [get_ports adc0_dco_p]

set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/IDELAYCTRL_dco]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[0].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[1].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[2].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[3].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[4].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay[5].IDELAYE2_data]
#set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/idelay_mode.IDELAYE2_clk]


#set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_0/IDELAYE2_clk]
# Edge-Aligned Double Data Rate Source Synchronous Inputs 
# (Using an MMCM/PLL)
#
# For an edge-aligned Source Synchronous interface, the clock
# transition occurs at the same time as the data transitions.
# In this template, the clock is aligned with the end of the
# data. The constraints below rely on the default timing
# analysis (setup = 1/2 cycle, hold = 0 cycle).
#
# input                        ___________________________
# clock  _____________________|                           |__________
#                             |                           |                 
#                     skew_bre|skew_are           skew_bfe|skew_afe
#                     <------>|<------>           <------>|<------>
#          ___________        |        ___________                 __
# data   XX_Rise_Data_XXXXXXXXXXXXXXXXX_Fall_Data_XXXXXXXXXXXXXXXXX
#

#create_clock -period 4 -name virt_clk -waveform {0.00 2.00}
#create_generated_clock -name adc0_clk_90 -source [get_pins ad9434_data_0/mmcm_mode.mmcm_adv_inst/CLKIN1] -edges {1 2 3} \ -edge_shift {1 1 1} [get_pins ad9434_data_0/mmcm_mode.mmcm_adv_inst/CLKOUT0]

#set_false_path -setup -rise_from [get_clocks virt_clk] -fall_to [get_clocks -of_objects [get_pins ad9434_data_0/mmcm_mode.clk_wiz_inst/inst/mmcm_adv_inst/CLKOUT0]]
#set_false_path -setup -fall_from [get_clocks virt_clk] -rise_to [get_clocks -of_objects [get_pins ad9434_data_0/mmcm_mode.clk_wiz_inst/inst/mmcm_adv_inst/CLKOUT0]]

#set_false_path -hold -rise_from [get_clocks virt_clk] -rise_to [get_clocks -of_objects [get_pins ad9434_data_0/mmcm_mode.clk_wiz_inst/inst/mmcm_adv_inst/CLKOUT0]]
#set_false_path -hold -fall_from [get_clocks virt_clk] -fall_to [get_clocks -of_objects [get_pins ad9434_data_0/mmcm_mode.clk_wiz_inst/inst/mmcm_adv_inst/CLKOUT0]]


create_clock -period 2.50 -name virt_clk0 -waveform {0.00 1.25}
set_multicycle_path -setup -end 0 -rise_from [get_clocks virt_clk0] -rise_to [get_clocks adc0_clk]
set_multicycle_path -setup -end 0 -fall_from [get_clocks virt_clk0] -fall_to [get_clocks adc0_clk]
set_multicycle_path -hold -end -1 -rise_from [get_clocks virt_clk0] -rise_to [get_clocks adc0_clk]
set_multicycle_path -hold -end -1 -fall_from [get_clocks virt_clk0] -fall_to [get_clocks adc0_clk]

set_false_path -setup -rise_from [get_clocks virt_clk0] -fall_to [get_clocks adc0_clk]
set_false_path -setup -fall_from [get_clocks virt_clk0] -rise_to [get_clocks adc0_clk]
set_false_path -hold -rise_from [get_clocks virt_clk0] -rise_to [get_clocks adc0_clk]
set_false_path -hold -fall_from [get_clocks virt_clk0] -fall_to [get_clocks adc0_clk]

set input_clock         virt_clk0;      # Name of input clock
set skew_bre            0.07;             # Data invalid before the rising clock edge
set skew_are            0.07;             # Data invalid after the rising clock edge
set skew_bfe            0.07;             # Data invalid before the falling clock edge
set skew_afe            0.07;             # Data invalid after the falling clock edge
set input_ports         adc0_din_n[*];     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max $skew_are  [get_ports $input_ports];
set_input_delay -clock $input_clock -min -$skew_bre [get_ports $input_ports];
set_input_delay -clock $input_clock -max $skew_afe  [get_ports $input_ports] -clock_fall -add_delay;
set_input_delay -clock $input_clock -min -$skew_bfe [get_ports $input_ports] -clock_fall -add_delay;


# Report Timing Template
# report_timing -rise_from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max -name src_sync_edge_ddr_in_rise -file src_sync_edge_ddr_in_rise.txt;	  
# report_timing -fall_from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max -name src_sync_edge_ddr_in_fall -file src_sync_edge_ddr_in_fall.txt; 


############################################### ADC1 constraint ####################################################
create_clock -period 2.50 -name adc1_clk -waveform {0.000 1.250} [get_ports adc1_dco_p]

set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/IDELAYCTRL_dco]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[0].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[1].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[2].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[3].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[4].IDELAYE2_data]
set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay[5].IDELAYE2_data]
#set_property IODELAY_GROUP  adc_idelay_grp [get_cells ad9434_data_1/idelay_mode.IDELAYE2_clk]

# Edge-Aligned Double Data Rate Source Synchronous Inputs 
# (Using an MMCM/PLL)
#
# For an edge-aligned Source Synchronous interface, the clock
# transition occurs at the same time as the data transitions.
# In this template, the clock is aligned with the end of the
# data. The constraints below rely on the default timing
# analysis (setup = 1/2 cycle, hold = 0 cycle).
#
# input                        ___________________________
# clock  _____________________|                           |__________
#                             |                           |                 
#                     skew_bre|skew_are           skew_bfe|skew_afe
#                     <------>|<------>           <------>|<------>
#          ___________        |        ___________                 __
# data   XX_Rise_Data_XXXXXXXXXXXXXXXXX_Fall_Data_XXXXXXXXXXXXXXXXX
#


create_clock -period 2.50 -name virt_clk1 -waveform {0.00 1.25}
set_multicycle_path -setup -end 0 -rise_from [get_clocks virt_clk1] -rise_to [get_clocks adc1_clk]
set_multicycle_path -setup -end 0 -fall_from [get_clocks virt_clk1] -fall_to [get_clocks adc1_clk]
set_multicycle_path -hold -end -1 -rise_from [get_clocks virt_clk1] -rise_to [get_clocks adc1_clk]
set_multicycle_path -hold -end -1 -fall_from [get_clocks virt_clk1] -fall_to [get_clocks adc1_clk]

set_false_path -setup -rise_from [get_clocks virt_clk1] -fall_to [get_clocks adc1_clk]
set_false_path -setup -fall_from [get_clocks virt_clk1] -rise_to [get_clocks adc1_clk]
set_false_path -hold -rise_from [get_clocks virt_clk1] -rise_to [get_clocks adc1_clk]
set_false_path -hold -fall_from [get_clocks virt_clk1] -fall_to [get_clocks adc1_clk]

set input_clock         virt_clk1;      # Name of input clock
set skew_bre            0.07;             # Data invalid before the rising clock edge
set skew_are            0.07;             # Data invalid after the rising clock edge
set skew_bfe            0.07;             # Data invalid before the falling clock edge
set skew_afe            0.07;             # Data invalid after the falling clock edge
set input_ports         adc1_din_n[*];     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max $skew_are  [get_ports $input_ports];
set_input_delay -clock $input_clock -min -$skew_bre [get_ports $input_ports];
set_input_delay -clock $input_clock -max $skew_afe  [get_ports $input_ports] -clock_fall -add_delay;
set_input_delay -clock $input_clock -min -$skew_bfe [get_ports $input_ports] -clock_fall -add_delay;


# Report Timing Template
# report_timing -rise_from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max -name src_sync_edge_ddr_in_rise -file src_sync_edge_ddr_in_rise.txt;	  
# report_timing -fall_from [get_ports $input_ports] -max_paths 20 -nworst 1 -delay_type min_max -name src_sync_edge_ddr_in_fall -file src_sync_edge_ddr_in_fall.txt; 

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_200m]
