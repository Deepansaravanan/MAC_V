"""Reference arithmetic helpers; not a hardware implementation."""
def mac(a: int, b: int, accumulator: int) -> int:
    """Return mathematical multiply-accumulate; width policy is intentionally TBD."""
    return a * b + accumulator

