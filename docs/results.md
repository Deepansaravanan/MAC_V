# Results

Functional RTL results have been collected with Icarus Verilog; synthesis,
implementation, timing, power, and FPGA performance measurements have **not**
been collected because Vivado is unavailable in the current environment.

The batch flow accepts a target part and synthesis top:

```powershell
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs <FPGA_PART> mac_int8
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs <FPGA_PART> mac_int16
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs <FPGA_PART> reconfigurable_mac_top
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs <FPGA_PART> reconfigurable_mac_optimized
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs <FPGA_PART> mac_array_4lane
```

Actual reports will be written under `vivado/reports/<top>/`. The empty CSV
schemas under `results/` must only be populated by parsing those reports. The
current 10 ns clock is a baseline constraint, not a measured Fmax.
