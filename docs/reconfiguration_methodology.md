# Reconfiguration Methodology

`precision_mode` is sampled with each `enable && valid_in` transaction: zero
selects signed INT8 from the low operand bytes and one selects signed INT16.
Mode may change on consecutive accepted cycles without bubbles. The 48-bit
accumulator is preserved during switching and is cleared only by `clear_acc` or
reset. Randomized verification changes mode, enable, valid, clear, and operands.
