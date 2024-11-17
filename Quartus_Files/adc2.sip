set_global_assignment -entity "adc2" -library "lib_adc2" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "adc2" -library "lib_adc2" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "adc2" -library "lib_adc2" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_adc2" -name SPD_FILE [file join $::quartus(sip_path) "../adc2.spd"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "../../adc2.qsys"]

set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "adc2.vhd"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/adc2_modular_adc_0.vhd"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control.v"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_avrg_fifo.v"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_fsm.v"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/chsel_code_converter_sw_to_hw.v"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_primitive_wrapper.v"]
set_global_assignment -library "lib_adc2" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_top_wrapper.v"]
