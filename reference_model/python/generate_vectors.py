"""Generate deterministic M3 INT8 golden vectors as CSV."""
import argparse
import csv
import random
from pathlib import Path
from mac_reference import mac_step

DIRECTED = [
    (0, 0, 1, 0, 1), (10, 5, 1, 0, 1), (10, -5, 1, 0, 1),
    (-10, 5, 1, 0, 1), (-10, -5, 1, 0, 1), (127, 127, 1, 0, 1),
    (-128, -128, 1, 0, 1), (-128, 127, 1, 0, 1),
    (127, -128, 1, 0, 1), (22, 19, 0, 0, 1),
    (22, 19, 1, 0, 0), (1, 1, 1, 1, 1),
]

def generate(path: Path, random_count: int, seed: int) -> int:
    rng = random.Random(seed)
    operations = list(DIRECTED)
    for _ in range(random_count):
        operations.append((rng.randint(-128, 127), rng.randint(-128, 127),
                           rng.getrandbits(1), rng.randrange(32) == 0,
                           rng.getrandbits(1)))
    accumulator = 0
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(("cycle", "a", "b", "enable", "clear_acc",
                         "valid_in", "expected_acc", "expected_valid"))
        for cycle, (a, b, enable, clear, valid) in enumerate(operations):
            result = mac_step(a, b, accumulator, operand_width=8,
                              accumulator_width=32, enable=bool(enable),
                              clear=bool(clear), valid_in=bool(valid))
            accumulator = result.accumulator
            writer.writerow((cycle, a, b, enable, int(clear), valid,
                             accumulator, int(result.valid_out)))
    return len(operations)

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path,
                        default=Path("verification/int8_vectors.csv"))
    parser.add_argument("--random-count", type=int, default=10_000)
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x4D33)
    args = parser.parse_args()
    if args.random_count < 1000:
        parser.error("--random-count must be at least 1000")
    count = generate(args.output, args.random_count, args.seed)
    print(f"Generated {count} INT8 vectors at {args.output}")

if __name__ == "__main__":
    main()
