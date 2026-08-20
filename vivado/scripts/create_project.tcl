# Vivado automation placeholder. Set TARGET_PART before running this flow.
if {![info exists TARGET_PART] || $TARGET_PART eq ""} { set TARGET_PART "" }
# TODO: Set TARGET_PART (for example via -tclargs) before creating a project.
if {$TARGET_PART eq ""} { error "TARGET_PART must be set to a valid FPGA part." }
create_project reconfigurable_mac ../project -part $TARGET_PART -force

