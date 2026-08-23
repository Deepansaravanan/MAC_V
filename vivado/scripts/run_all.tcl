# M9 batch flow: run_all.tcl <FPGA_PART> <TOP_MODULE> ?CLOCK_PERIOD_NS?
proc fail {message {code 1}} { puts stderr "M9 ERROR: $message"; exit $code }
if {$argc < 2 || $argc > 3} { fail "Usage: run_all.tcl <FPGA_PART> <TOP_MODULE> ?CLOCK_PERIOD_NS?" 2 }
set TARGET_PART [lindex $argv 0]
set TOP_MODULE [lindex $argv 1]
set CLOCK_PERIOD_NS [expr {$argc == 3 ? [lindex $argv 2] : 10.000}]
if {![string is double -strict $CLOCK_PERIOD_NS] || $CLOCK_PERIOD_NS <= 0} { fail "CLOCK_PERIOD_NS must be positive" 2 }
set allowed_tops {mac_int8 mac_int16 reconfigurable_mac_top reconfigurable_mac_optimized mac_array_4lane}
if {[lsearch -exact $allowed_tops $TOP_MODULE] < 0} { fail "Unsupported top '$TOP_MODULE'; choose: $allowed_tops" 2 }

set script_dir [file dirname [info script]]
set repo_root [file dirname [file dirname $script_dir]]
puts "M9 paths: script_dir=$script_dir repo_root=$repo_root"
set build_dir [file join $repo_root build vivado $TOP_MODULE]
set report_dir [file join $repo_root results vivado $TOP_MODULE]
file mkdir $build_dir
file mkdir $report_dir
set status_file [file join $report_dir status.txt]
set fh [open $status_file w]
puts $fh "architecture=$TOP_MODULE\nfpga_part=$TARGET_PART\nclock_period_ns=$CLOCK_PERIOD_NS\nvivado_version=[version -short]\nsynthesis=NOT_RUN\nimplementation=NOT_RUN"
close $fh
proc append_status {path key value} { set f [open $path a]; puts $f "$key=$value"; close $f }

if {[catch {
  create_project m9_${TOP_MODULE} $build_dir -part $TARGET_PART -force
  set rtl_files [glob -nocomplain [file join $repo_root rtl * *.sv]]
  if {[llength $rtl_files] == 0} { error "No RTL sources found" }
  add_files -norecurse $rtl_files
  set_property file_type SystemVerilog [get_files $rtl_files]
  set_property top $TOP_MODULE [current_fileset]
  update_compile_order -fileset sources_1
  set generated_xdc [file join $build_dir m9_clock.xdc]
  set xdc [open $generated_xdc w]
  puts $xdc "create_clock -name system_clk -period $CLOCK_PERIOD_NS \[get_ports clk\]"
  close $xdc
  add_files -fileset constrs_1 -norecurse $generated_xdc

  # These are reusable accelerator cores, not board-level pin wrappers. OOC
  # mode prevents wide operand buses (183 ports for the four-lane array) from
  # being forced into the selected package's 106 bonded I/Os.
  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

  launch_runs synth_1 -jobs 4
  wait_on_run synth_1
  set synth_status [get_property STATUS [get_runs synth_1]]
  append_status $status_file synthesis_status $synth_status
  if {![string match "synth_design Complete*" $synth_status]} { append_status $status_file synthesis FAIL; error "Synthesis failed: $synth_status" }
  append_status $status_file synthesis PASS
  open_run synth_1
  set synth_util [file join $report_dir post_synth_utilization.rpt]
  file delete -force $synth_util
  report_utilization -file $synth_util

  launch_runs impl_1 -to_step route_design -jobs 4
  wait_on_run impl_1
  set impl_status [get_property STATUS [get_runs impl_1]]
  append_status $status_file implementation_status $impl_status
  if {![string match "route_design Complete*" $impl_status]} { append_status $status_file implementation FAIL; error "Implementation failed: $impl_status" }
  append_status $status_file implementation PASS
  open_run impl_1
  set utilization_report [file join $report_dir utilization.rpt]
  set timing_report [file join $report_dir timing_summary.rpt]
  set critical_report [file join $report_dir critical_paths.rpt]
  set power_report [file join $report_dir power.rpt]
  set drc_report [file join $report_dir drc.rpt]
  foreach old_report [list $utilization_report $timing_report $critical_report $power_report $drc_report] { file delete -force $old_report }
  report_utilization -file $utilization_report
  report_timing_summary -delay_type max -max_paths 10 -report_unconstrained -check_timing_verbose -file $timing_report
  report_timing -delay_type max -max_paths 10 -path_type full -file $critical_report
  report_power -file $power_report
  report_drc -file $drc_report
  write_checkpoint -force [file join $report_dir routed.dcp]
} flow_error]} {
  append_status $status_file flow FAIL
  append_status $status_file error [string map {"\n" " " "\r" " " "=" ":"} $flow_error]
  puts stderr $::errorInfo
  exit 1
}
append_status $status_file flow PASS
puts "M9 PASS: reports written to $report_dir"
exit 0
