"""Reusable width-accurate signed MAC reference model."""
from dataclasses import dataclass

def wrap_signed(value: int, width: int) -> int:
    if width < 1:
        raise ValueError("width must be positive")
    value &= (1 << width) - 1
    return value - (1 << width) if value & (1 << (width - 1)) else value

@dataclass(frozen=True)
class MacResult:
    accumulator: int
    valid_out: bool

def mac_step(a: int, b: int, accumulator: int, *, operand_width: int,
             accumulator_width: int, enable: bool = True,
             clear: bool = False, valid_in: bool = True) -> MacResult:
    minimum = -(1 << (operand_width - 1))
    maximum = (1 << (operand_width - 1)) - 1
    if not isinstance(a, int) or not isinstance(b, int):
        raise TypeError("operands must be integers")
    if not minimum <= a <= maximum or not minimum <= b <= maximum:
        raise ValueError(f"operands must be in [{minimum}, {maximum}]")
    if accumulator_width < 2 * operand_width:
        raise ValueError("accumulator cannot be narrower than the full product")
    if clear:
        return MacResult(0, False)
    if enable and valid_in:
        return MacResult(wrap_signed(accumulator + a * b,
                                     accumulator_width), True)
    return MacResult(wrap_signed(accumulator, accumulator_width), False)
