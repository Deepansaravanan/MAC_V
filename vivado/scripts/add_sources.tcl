# Vivado automation placeholder. Set TARGET_PART before running this flow.
if {![info exists TARGET_PART] || $TARGET_PART eq ""} { set TARGET_PART "" }
# Run from vivado/scripts after create_project.tcl.
# TODO: Add RTL, testbench, and XDC sources explicitly as RTL is implemented.
add_files -norecurse [glob -nocomplain ../../rtl/**/*.sv]
add_files -fileset sim_1 -norecurse [glob -nocomplain ../../tb/**/*.sv]
add_files -fileset constrs_1 -norecurse [glob -nocomplain ../constraints/*.xdc]
set_property top reconfigurable_mac_top [current_fileset]

