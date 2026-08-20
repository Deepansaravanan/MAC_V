"""Fail-fast comparison of simulator CSV output to Python golden vectors."""
import argparse
import csv
from pathlib import Path

def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected", type=Path,
                        default=Path("verification/int8_vectors.csv"))
    parser.add_argument("--actual", type=Path,
                        default=Path("verification/int8_results.csv"))
    args = parser.parse_args()
    expected, actual = read_rows(args.expected), read_rows(args.actual)
    if len(expected) != len(actual):
        raise SystemExit(f"FAIL: expected {len(expected)} rows, got {len(actual)}")
    for index, (gold, rtl) in enumerate(zip(expected, actual)):
        for field, rtl_field in (("expected_acc", "actual_acc"),
                                 ("expected_valid", "actual_valid")):
            if int(gold[field]) != int(rtl[rtl_field]):
                raise SystemExit(
                    f"FAIL test={index} a={gold['a']} b={gold['b']} "
                    f"enable={gold['enable']} clear={gold['clear_acc']} "
                    f"valid_in={gold['valid_in']} expected={gold[field]} "
                    f"actual={rtl[rtl_field]}")
    print(f"RTL vs Python golden: {len(expected)}/{len(expected)} PASS")

if __name__ == "__main__":
    main()
