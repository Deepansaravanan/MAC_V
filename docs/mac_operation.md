# MAC Operation

## M2 — Fixed INT8 Baseline

`acc_out(next) = acc_out(current) + signed(a) * signed(b)`

| Property | Definition |
| --- | --- |
| Operands | signed two's-complement INT8 |
| Product | full-precision signed 16-bit |
| Accumulator | signed `ACC_WIDTH`, default 32 and minimum 16 |
| Reset | active-low synchronous; clears to zero |
| Enable/valid | update for `enable && valid_in`; pulse `valid_out` |
| Clear | synchronous `clear_acc`, below reset and above update priority |
| Latency | one rising clock edge |
| Overflow | natural two's-complement wraparound |

The product is explicitly sign-extended before addition. The portable RTL uses no
vendor primitive. Its self-checking testbench covers directed behavior and 1000
full-range randomized transactions. Define `DUMP_VCD` on simulators that support
`$dumpvars` to capture interface, product, extension, and accumulator waveforms.

Synthesis, timing, utilization, power, INT16, and runtime switching are planned.
