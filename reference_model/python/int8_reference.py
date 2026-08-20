"""Width-accurate golden model for the fixed signed-INT8 M2 MAC."""

def _wrap_signed(value: int, width: int) -> int:
    if width < 1:
        raise ValueError("width must be positive")
    wrapped = value & ((1 << width) - 1)
    sign_bit = 1 << (width - 1)
    return wrapped - (1 << width) if wrapped & sign_bit else wrapped

def mac_int8(a: int, b: int, accumulator: int, acc_width: int = 32,
             *, enable: bool = True, clear: bool = False,
             valid_in: bool = True) -> tuple[int, bool]:
    """Return ``(next_accumulator, valid_out)`` using the frozen M1 priority."""
    if not isinstance(a, int) or not isinstance(b, int):
        raise TypeError("INT8 operands must be integers")
    if not -128 <= a <= 127 or not -128 <= b <= 127:
        raise ValueError("INT8 operands must be in [-128, 127]")
    if acc_width < 16:
        raise ValueError("acc_width must be at least 16")
    if clear:
        return 0, False
    if enable and valid_in:
        return _wrap_signed(accumulator + (a * b), acc_width), True
    return _wrap_signed(accumulator, acc_width), False
