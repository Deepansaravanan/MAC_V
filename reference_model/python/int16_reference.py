"""Planned signed INT16 reference model."""
def int16_mac(a: int, b: int, accumulator: int) -> int:
    if not all(-32768 <= value <= 32767 for value in (a, b)):
        raise ValueError("INT16 operands must be signed 16-bit values")
    return a * b + accumulator

