"""Four-lane dot-product MAC reference model."""
from mac_reference import wrap_signed

def array_step(a: list[int], b: list[int], accumulator: int, *, mode_int16: bool,
               enable: bool=True, clear: bool=False, valid_in: bool=True) -> tuple[int,bool]:
    if len(a)!=4 or len(b)!=4:
        raise ValueError("exactly four lanes are required")
    if clear:
        return 0,False
    if not(enable and valid_in):
        return wrap_signed(accumulator,48),False
    width=16 if mode_int16 else 8
    lo,hi=-(1<<(width-1)),(1<<(width-1))-1
    if any(not lo<=value<=hi for value in a+b):
        raise ValueError("operand outside selected precision")
    return wrap_signed(accumulator+sum(x*y for x,y in zip(a,b)),48),True
