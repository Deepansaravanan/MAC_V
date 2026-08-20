# Optimization Methodology

M7 implements a functionally equivalent two-stage variant. Accepted operands are
mode-selected and captured only when `enable && valid_in`, isolating the shared
multiplier from idle input activity. The following stage accumulates the pending
product and propagates its valid bit. Reset or clear flushes pending work.

This structure is intended to improve timing and reduce unnecessary switching,
but no area, Fmax, or power benefit is claimed until Vivado reports are produced.
Functional equivalence is checked with randomized mode and control sequences.

Optimization candidates include operand isolation, clock-enable control, precision selection, pipelining, and optional array parallelism. Each candidate will be compared against fixed baselines using measured implementation reports rather than assumed improvements.
