# M9 — Vivado synthesis and results

## Status

**PASS.** Vivado 2025.2 synthesized and implemented all five architectures on
2026-08-23 for `xc7a35tcpg236-1` at a common 10.000 ns constraint. The tables
below contain parsed post-route Vivado results, not placeholders.

## Reproducible configuration

The FPGA part is a required runner argument. The clock defaults to 10.000 ns
(100 MHz) and is generated identically for every top; it may be overridden.
No board or physical pins are required. All five accelerator cores use Vivado
out-of-context synthesis so wide core buses are not forced onto package pins;
this is necessary because `mac_array_4lane` has 183 logical I/Os while the
selected `cpg236` package has 106 bonded I/Os. Default synthesis and
implementation strategies are otherwise used, through `route_design`.

Verified top-module names and architecture behavior:

| Architecture | RTL top | Latency | Accepted work/cycle |
|---|---|---:|---:|
| Fixed INT8 | `mac_int8` | 1 cycle | 1 MAC |
| Fixed INT16 | `mac_int16` | 1 cycle | 1 MAC |
| Reconfigurable | `reconfigurable_mac_top` | 1 cycle | 1 MAC |
| Pipelined reconfigurable | `reconfigurable_mac_optimized` | 2 cycles | 1 MAC |
| Four-lane dot product | `mac_array_4lane` | 1 cycle | 4 MACs |

Latency and parallelism above come from RTL transaction behavior. Throughput is
only emitted when a timing-derived frequency exists. The array accepts four
independent operand pairs per valid cycle and accumulates their dot-product.

## Run

```powershell
.\vivado\scripts\check_vivado.ps1
.\vivado\scripts\run_m9.ps1 -FpgaPart "xc7a35tcpg236-1" -Top mac_int8
.\vivado\scripts\run_m9.ps1 -FpgaPart "xc7a35tcpg236-1"
```

The part above is only an example; confirm that the installed Vivado edition has
device support. Direct TCL usage is:

```powershell
vivado -mode batch -source vivado/scripts/run_all.tcl -tclargs xc7a35tcpg236-1 mac_int8 10.000
```

Each top writes to `results/vivado/<top>/`: post-route utilization, timing
summary, critical paths, estimated power, DRC, routed checkpoint, status, and
the runner's Vivado log. Testbenches and simulation-only files are excluded.

## Metric interpretation

The parser reads report values without inventing substitutes. Blank cells mean
the report or metric was unavailable. For a constraint `T_target` and setup WNS,
the timing-derived period estimate is:

`T_est = T_target - WNS`, and `Fmax_est = 1000 / T_est` MHz.

Thus negative WNS lengthens the estimated period, while positive WNS shortens
it. This is an estimate from the implemented design at one constraint, not an
exact frequency-search result. TNS and data-path delay are retained separately.
Power values are Vivado estimates, not board measurements. Derived overhead and
improvement percentages are emitted only when both operands exist and the
denominator is nonzero.

## Results and limitations

| Architecture | LUT | FF | DSP | BRAM | WNS (ns) | Fmax estimate (MHz) | Total power (W) |
|---|---:|---:|---:|---:|---:|---:|---:|
| `mac_int8` | 95 | 33 | 0 | 0 | 7.175 | 353.982 | 0.070 |
| `mac_int16` | 3 | 1 | 1 | 0 | N/A | N/A | 0.070 |
| `reconfigurable_mac_top` | 19 | 1 | 1 | 0 | N/A | N/A | 0.070 |
| `reconfigurable_mac_optimized` | 11 | 2 | 1 | 0 | 8.396 | 623.441 | 0.070 |
| `mac_array_4lane` | 163 | 49 | 4 | 0 | 4.624 | 186.012 | 0.077 |

The timing-based throughputs are 353.982 million MAC/s for INT8, 623.441
million MAC/s for the optimized core, and 744.048 million MAC/s for the
four-lane array. INT16 and baseline reconfigurable throughput remain blank
because Vivado reported no numeric setup WNS in OOC mode: their accumulator
logic was absorbed into a DSP and no register-to-register setup path was
reported. Their data-path delays are retained in the CSV, but are not silently
substituted for clock timing. Consequently, optimized-vs-baseline Fmax
improvement is also unavailable.

The parsed LUT difference of the reconfigurable core versus INT8 is -80%; this
is not evidence that reconfiguration is intrinsically cheaper. Vivado mapped
INT8 into LUT fabric but absorbed the 16-bit/reconfigurable arithmetic into one
DSP, so resource classes must be interpreted together.

Power is Vivado vectorless estimated power. Dynamic/static/total values are in
`results/power_comparison.csv`; accuracy depends on default activity assumptions
because no SAIF switching activity was supplied. OOC runs warn that top-level
port partial routing and clock-source modeling are incomplete; reported
clocked-path timing is suitable for this core comparison but not board-level
timing signoff. OOC DRC also omits checks requiring top-level connectivity.

Synthesis reported no RTL warnings for the inspected runs. No RTL was modified
for M9, so functional verification was not rerun. Eight plots were generated;
the Fmax-improvement plot was correctly skipped because baseline Fmax is N/A.
