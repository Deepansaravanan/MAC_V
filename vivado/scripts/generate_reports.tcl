set report_dir [file join $script_dir .. reports $TOP_MODULE]
file mkdir $report_dir
report_utilization -file [file join $report_dir utilization.rpt]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
  -file [file join $report_dir timing_summary.rpt]
report_power -file [file join $report_dir power.rpt]
report_drc -file [file join $report_dir drc.rpt]
