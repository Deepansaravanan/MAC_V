set script_dir [file dirname [file normalize [info script]]]
if {![info exists TARGET_PART] || $TARGET_PART eq ""} {
  if {$argc < 1} { error "Usage: vivado -mode batch -source run_all.tcl -tclargs <part> ?top?" }
  set TARGET_PART [lindex $argv 0]
}
if {![info exists TOP_MODULE] || $TOP_MODULE eq ""} {
  set TOP_MODULE [expr {$argc >= 2 ? [lindex $argv 1] : "reconfigurable_mac_top"}]
}
create_project mac_${TOP_MODULE} [file join $script_dir .. project $TOP_MODULE] -part $TARGET_PART -force
