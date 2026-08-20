# Frozen MAC Specification

Version: M1.0 — 2026-08-20

This document is the interface and arithmetic contract for all baseline and
runtime-reconfigurable MAC implementations. RTL changes that alter this contract
require a specification revision.

## Common synchronous protocol

All state and output-valid signals update on the rising edge of `clk`.
`rst_n` is an active-low **synchronous** reset. Priority is:

1. `!rst_n`: clear accumulator and `valid_out`.
2. `clear_acc`: clear accumulator and `valid_out`; no operand is accepted.
3. `enable && valid_in`: accept operands, perform one MAC, and assert
   `valid_out` for that updated result.
4. Otherwise: retain the accumulator and deassert `valid_out`.

There is no ready/backpressure signal. Operands may change while no transaction
is accepted and have no architectural effect. `acc_out` always exposes the
current accumulator. Reset value is zero. Baselines are single-stage registered
designs: an accepted input updates `acc_out` and `valid_out` at the same edge,
giving one-edge (one-cycle transaction) latency and accepting one operation per
cycle. No saturation, rounding, exception, or hidden pipeline state is used.

## INT8 baseline

| Signal | Direction | Type | Meaning |
| --- | --- | --- | --- |
| `clk` | input | 1 bit | rising-edge clock |
| `rst_n` | input | 1 bit | active-low synchronous reset |
| `enable` | input | 1 bit | clock-enable qualification |
| `clear_acc` | input | 1 bit | synchronous accumulator clear |
| `valid_in` | input | 1 bit | operand transaction is valid |
| `a`, `b` | input | signed `[7:0]` | two's-complement operands |
| `acc_out` | output | signed `[ACC_WIDTH-1:0]` | current accumulator |
| `valid_out` | output | 1 bit | updated accumulator is valid |

The exact operation is `ACC(n+1) = wrap_ACC_WIDTH(ACC(n) + A * B)`.
Multiplication is signed 8 × 8 with a full signed 16-bit product, explicitly
sign-extended before addition. `ACC_WIDTH` defaults to 32 and must be at least
16. Overflow uses deterministic two's-complement modular wraparound.

## INT16 baseline

The common protocol is unchanged. `a` and `b` are signed `[15:0]`, their full
product is signed 32-bit, and `ACC_WIDTH` defaults to 48 and must be at least 32.
Overflow wraps at the configured accumulator width. This section freezes the
future M4 contract; it does not claim that M4 is implemented.

## Runtime precision mode

The future unified interface uses `precision_mode`: `0` = INT8 and `1` = INT16,
sampled only when `enable && valid_in` accepts a transaction. Mode changes while
idle have no state effect. The shared accumulator is 48 bits and is preserved
across mode changes unless `clear_acc` or reset is asserted. An accepted INT8
operand uses the low 8 bits of each 16-bit operand and sign-extends its product;
INT16 uses all bits. Mode must remain stable for the setup/hold interval of the
accepting edge. Output validity and priority follow the common protocol.

## Planned pipelining

Optimized variants may add registered stages, but must parameterize or clearly
name their latency and preserve transaction order. Their `valid_out` must be
delayed by exactly the datapath latency. The M2 and M4 baselines remain
single-stage reference architectures.
