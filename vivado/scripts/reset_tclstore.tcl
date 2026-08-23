if {[catch {tclapp::reset_tclstore} message]} {
  puts stderr "Tcl Store reset failed: $message"
  exit 1
}
puts "Tcl Store reset completed."
exit 0
