# Run after create_project.tcl and add_sources.tcl from vivado/scripts.
set_property top int8_mac_tb [get_filesets sim_1]
# Generate verification/int8_vectors.csv first, then uncomment and adjust this
# define to enable RTL-vs-Python CSV regression in XSim.
# set_property verilog_define {VECTOR_FILE="../../verification/int8_vectors.csv"} [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim
