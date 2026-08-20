# Runtime-Reconfigurable Architecture

The implemented baseline reuses one signed 16×16 multiplier and one 48-bit
accumulator. INT8 mode sign-extends each low byte before the shared multiplier;
INT16 mode uses the complete operands.

```mermaid
flowchart LR
  A["16-bit A/B"] --> S["Mode-select and INT8 sign extension"]
  M["precision_mode"] --> S
  S --> X["Shared signed 16 x 16 multiplier"]
  X --> E["48-bit sign extension"]
  E --> C["Shared 48-bit accumulator"]
  C --> O["acc_out"]
```

This is runtime datapath selection, not FPGA partial reconfiguration. Reset and
clear take priority over accepted operations. Mode changes preserve accumulator
state and are transaction-safe because mode is used only at an accepting edge.
