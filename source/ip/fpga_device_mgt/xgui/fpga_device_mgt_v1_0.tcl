# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INTR_MSG_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TEMPER_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.INTR_MSG_WIDTH { PARAM_VALUE.INTR_MSG_WIDTH } {
	# Procedure called to update INTR_MSG_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INTR_MSG_WIDTH { PARAM_VALUE.INTR_MSG_WIDTH } {
	# Procedure called to validate INTR_MSG_WIDTH
	return true
}

proc update_PARAM_VALUE.TEMPER_WIDTH { PARAM_VALUE.TEMPER_WIDTH } {
	# Procedure called to update TEMPER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TEMPER_WIDTH { PARAM_VALUE.TEMPER_WIDTH } {
	# Procedure called to validate TEMPER_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.TEMPER_WIDTH { MODELPARAM_VALUE.TEMPER_WIDTH PARAM_VALUE.TEMPER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TEMPER_WIDTH}] ${MODELPARAM_VALUE.TEMPER_WIDTH}
}

proc update_MODELPARAM_VALUE.INTR_MSG_WIDTH { MODELPARAM_VALUE.INTR_MSG_WIDTH PARAM_VALUE.INTR_MSG_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INTR_MSG_WIDTH}] ${MODELPARAM_VALUE.INTR_MSG_WIDTH}
}

