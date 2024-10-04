###########################################################
#####	 	Part 1 Read RTL		              #####
###########################################################
create_lib -technology ../../libraries/saed32nm_1p9m.tf -ref_lib { ../../libraries/sram2rw16x4_tt1p_v125c.ndm ../../libraries/saed32rvt_tt_v125c.ndm } bitcoin_stage_1.dlib
open_lib bitcoin_stage_1.dlib
report_ref_libs
analyze -format verilog [ glob ../../sourcecode/rtl/*.v ]
elaborate bit_coin
set_top_module bit_coin
current_block
save_block -as bitcoin/elaborate
get_blocks -all
save_lib

###########################################################
#####	 	Part 2 Compile flow		      #####
###########################################################

# tech_setup.tcp
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

read_parasitic_tech -layermap ../../libraries/saed32nm_tf_itf_tluplus.map -tlup ../../libraries/saed32nm_1p9m_Cmin.tluplus -name Cmin
read_parasitic_tech -layermap ../../libraries/saed32nm_tf_itf_tluplus.map -tlup ../../libraries/saed32nm_1p9m_nominal.tluplus -name Cnom
read_parasitic_tech -layermap ../../libraries/saed32nm_tf_itf_tluplus.map -tlup ../../libraries/saed32nm_1p9m_Cmax.tluplus -name Cmax

suppress_message ATTR-12
set_attribute [get_layers {M1 M3 M5 M7 M9}]   routing_direction vertical
set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction horizontal
unsuppress_message ATTR-12

# mcmm_setup: 
# Remove all MCMM related info
remove_corners   -all
remove_modes     -all
remove_scenarios -all

# Create Corners
create_corner Fast
create_corner Typical
create_corner Slow

# Set parasitics parameters
set_parasitics_parameters -early_spec Cmin -late_spec  Cmin -corners {Fast}
set_parasitics_parameters -early_spec Cnom -late_spec  Cnom -corners {Typical}
set_parasitics_parameters -early_spec Cmax -late_spec  Cmax -corners {Slow}

# Create Mode
create_mode  FUNC
current_mode FUNC

# Create Scenarios
create_scenario -mode FUNC -corner Fast    -name FUNC_Fast
create_scenario -mode FUNC -corner Typical -name FUNC_Typical
create_scenario -mode FUNC -corner Slow    -name FUNC_Slow

# Read Constraints for each scenario
suppress_message UIC-034

foreach scenario [ list FUNC_Fast FUNC_Typical FUNC_Slow ] {
	current_scenario ${scenario}
	read_sdc ../../libraries/bit_coin.sdc
}

# Set operating conditions for each corner and scenario
set PVT_FF "tt0p85v125c"
current_corner Fast
current_scenario FUNC_Fast
set_operating_conditions ${PVT_FF}

set PVT_TT "tt0p85v125c"
current_corner Typical
current_scenario FUNC_Typical
set_operating_conditions ${PVT_TT}

set PVT_SS "tt0p85v125c"
current_corner Slow
current_scenario FUNC_Slow
set_operating_conditions ${PVT_SS}

# Scenario configuration example
set_scenario_status FUNC_Fast    -setup false -hold true  -leakage_power false -dynamic_power true  -max_transition false  -max_capacitance true  -active false
set_scenario_status FUNC_Typical -all -active true
set_scenario_status FUNC_Slow    -setup true  -hold false -leakage_power true  -dynamic_power true  -max_transition true   -max_capacitance false  -active false

# Setup application options
set_app_options -name place.coarse.continue_on_missing_scandef -value true

# Collecting all reports into a direectory 
# TODO: You should create the directory "reports/stage1" manually in the relevant location
proc collect_reports {stage_name} {
	echo "Collecting reports for ${stage_name} stage..."
	redirect -file ../../reports/stage1/${stage_name}_report_power.rpt {report_power -scenarios [all_scenarios]}
	redirect -file ../../reports/stage1/${stage_name}_report_timing_setup.rpt {report_timing -scenarios [all_scenarios] -delay_type max}
	redirect -file ../../reports/stage1/${stage_name}_report_timing_hold.rpt  {report_timing -scenarios [all_scenarios] -delay_type min}
	redirect -file ../../reports/stage1/${stage_name}_report_area.rpt {report_area}
	redirect -file ../../reports/stage1/${stage_name}_report_qor.rpt  {report_qor}
	redirect -file ../../reports/stage1/${stage_name}_report_design.rpt  {report_design}
	echo "Reports are generated for ${stage_name} stage."
}

# Learn about compile fusion using man and list_only flags
man compile_fusion
compile_fusion -list_only

# Check the design before compile_fusion
compile_fusion -check_only

# initial_map stage
compile_fusion -to initial_map
collect_reports initial_map

# logic_opto stage
compile_fusion -from logic_opto -to logic_opto
collect_reports logic_opto

# initial_place stage
compile_fusion -from initial_place -to initial_place
collect_reports initial_place

# Check timing for SETUP violations
report_timing -scenarios [all_scenarios] -delay_type max 

##### FILL BY STUDENTS #####
set tp1 [get_timing_paths -from bit_secure_2/lreset_sync/reset_sync_reg -to bit_secure_2/slice_9/sipo_bit/rd_addr_reg[1] ]
change_selection $tp1
##### FILL BY STUDENTS #####

# Check timing for HOLD violations
report_timing -scenarios [all_scenarios] -delay_type min

##### FILL BY STUDENTS #####
change_selection [get_timing_paths -from  bit_secure_5/sipo_slice_first/count_reg[0] -to bit_secure_5/sipo_slice_first/count_reg[0]]
##### FILL BY STUDENTS #####

# Create False paths to ignore
##### FILL BY STUDENTS #####
set_false_path -from  bit_secure_2/lreset_sync/reset_sync_reg/Q -to *
##### FILL BY STUDENTS #####

# initial_drc stage
compile_fusion -from initial_drc -to initial_drc
collect_reports initial_drc 

# initial_opto stage
compile_fusion -from initial_opto -to initial_opto
collect_reports initial_opto

# final_place stage
compile_fusion -from final_place -to final_place
collect_reports final_place

# final_opto stage
compile_fusion -from final_opto -to final_opto
collect_reports final_opto

# Same path you wrote after section "Check timing for SETUP violations"
change_selection $tp1

check_legality

save_block -as bitcoin/compile
get_blocks -all
save_lib
