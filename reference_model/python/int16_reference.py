"""Width-accurate model for the independent signed-INT16 baseline."""
from mac_reference import mac_step

def mac_int16(a: int, b: int, accumulator: int, acc_width: int = 48,
              *, enable: bool = True, clear: bool = False,
              valid_in: bool = True) -> tuple[int, bool]:
    result = mac_step(a, b, accumulator, operand_width=16,
                      accumulator_width=acc_width, enable=enable,
                      clear=clear, valid_in=valid_in)
    return result.accumulator, result.valid_out
