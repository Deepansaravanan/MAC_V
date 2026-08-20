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

## Current status

Project skeleton and starter interfaces only. The final MAC datapath, verification suite, configurations, and measured results are intentionally not yet implemented.

## Future work

Define width and overflow policy, implement fixed baselines and the runtime-controlled datapath, write directed and randomized verification, run Vivado flows for a selected FPGA part, and compare measured outputs.
