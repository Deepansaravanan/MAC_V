"""Planned signed INT8 reference model."""
def int8_mac(a: int, b: int, accumulator: int) -> int:
    if not all(-128 <= value <= 127 for value in (a, b)):
        raise ValueError("INT8 operands must be signed 8-bit values")
    return a * b + accumulator

