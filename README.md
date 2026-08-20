# Design and Optimization of a Dynamically Reconfigurable MAC Unit for Edge-AI Hardware Acceleration

## Objective

This repository is the planned RTL research platform for a synthesizable Multiply-Accumulate (MAC) unit that can select INT8 and INT16 operation at run time. The scope is runtime control of datapath operation; it does not claim FPGA partial reconfiguration.

## Motivation

Edge-AI accelerators benefit from matching arithmetic precision and operating policy to a workload. This project will evaluate a control-driven MAC architecture against fixed-precision baseline designs.

## Planned architecture

Configuration registers feed a mode controller and reconfiguration controller, which in turn select the intended MAC datapath policy. Future extensions include power-aware controls and a parallel MAC array.

## Toolchain

SystemVerilog, Xilinx Vivado and TCL are used for RTL development and FPGA flows. Python 3 supports reference arithmetic, vectors, report parsing, and plots.

## Repository structure

- `rtl/`: synthesizable RTL modules and common types.
- `tb/`: unit, reconfiguration, power, array, integration, and regression testbenches.
- `reference_model/`: Python arithmetic models and generated test vectors.
- `vivado/`: configurable project, flow scripts, constraints, and generated reports.
- `experiments/` and `results/`: experiment configuration and measured data only.
- `docs/`: research and IEEE-paper working documentation.

## Simulation and synthesis strategy

Vivado TCL scripts are structured to add RTL and testbench files, simulate, synthesize, implement, and emit reports once a target part and implementation are supplied. No generated results are included in this initial skeleton.

## Evaluation metrics

Planned evaluation covers LUT, FF, DSP and BRAM use; maximum frequency, critical path and latency; dynamic, static and total power; energy per MAC; throughput; and derived efficiency metrics.

## M2 — Fixed INT8 Baseline

**Implemented:** the frozen interface is documented in `docs/mac_specification.md`.
`mac_int8` computes `acc_out[n+1] = acc_out[n] + (a * b)` for an accepted
`enable && valid_in` transaction.
Operands are signed two's-complement INT8, the full product is signed 16-bit,
and the accumulator is parameterized (32-bit default). `rst_n` is an active-low
synchronous reset. `clear_acc` synchronously clears the accumulator. With enable
low or invalid input, the result holds and `valid_out` is low. An accepted result
asserts `valid_out` and has one-clock latency; overflow wraps at accumulator width.

Verification includes directed sign, zero, extreme, accumulation, reset, and hold
tests, plus 1000 full-range randomized pairs. A width-aware Python model tests
arithmetic, input validation, and wraparound.

**Planned:** synthesis, implementation, timing, utilization, and power results.
INT16 and runtime switching remain outside M2.

## Reproduce M1–M3 verification (Windows PowerShell)

```powershell
python reference_model/python/generate_vectors.py --random-count 10000
iverilog -g2012 -Wall '-DVECTOR_FILE="verification/int8_vectors.csv"' `
  -s int8_mac_tb -o verification/int8_mac_tb.vvp `
  rtl/precision/int8_mac.sv tb/unit/int8_mac_tb.sv
vvp verification/int8_mac_tb.vvp
python reference_model/python/verify_results.py
python -m unittest discover -s reference_model/python -p 'test_*.py' -v
```

Expected output includes `Directed tests: 20/20 PASS`, `Randomized tests:
1000/1000 PASS`, `Python golden vectors: 10012/10012 PASS`, and an independent
`RTL vs Python golden: 10012/10012 PASS`. Define `DUMP_VCD` at compile time for
VCD output. With Vivado configured, source `create_project.tcl`,
`add_sources.tcl`, and `run_simulation.tcl` from `vivado/scripts`.

## Current status

- M1 Specification ✅
- M2 Fixed INT8 Baseline ✅
- M3 Golden Model + Automated INT8 Verification ✅
- M4 Fixed INT16 Baseline ✅
- M5 Runtime Precision Reconfiguration ✅
- M6 Reconfiguration Verification ✅
- M7 Pipelined/Operand-Isolated Variant ✅ (functional only; PPA unmeasured)
- M8 Four-Lane Edge-AI Dot Product ✅
- M9 Vivado Measurement Flow prepared; execution pending Vivado and target part
- M10 paper structure present; measured-results sections pending M9

## Future work

Define width and overflow policy, implement fixed baselines and the runtime-controlled datapath, write directed and randomized verification, run Vivado flows for a selected FPGA part, and compare measured outputs.
