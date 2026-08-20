"""Executable unit tests for the M2 INT8 golden model."""
import unittest
from int8_reference import mac_int8

class Int8ReferenceTests(unittest.TestCase):
    def test_signed_products_and_accumulation(self) -> None:
        acc = 0
        for a, b in [(10, 5), (-10, 5), (10, -5), (-10, -5)]:
            acc, valid = mac_int8(a, b, acc)
            self.assertTrue(valid)
        self.assertEqual(acc, 0)
        self.assertEqual(mac_int8(-128, -128, 0), (16384, True))
        self.assertEqual(mac_int8(-128, 127, 0), (-16256, True))

    def test_accumulator_wraparound(self) -> None:
        self.assertEqual(mac_int8(1, 1, (1 << 31) - 1), (-(1 << 31), True))
        self.assertEqual(mac_int8(-1, 1, -(1 << 31)), ((1 << 31) - 1, True))

    def test_control_priority(self) -> None:
        self.assertEqual(mac_int8(7, 9, 12, enable=False), (12, False))
        self.assertEqual(mac_int8(7, 9, 12, valid_in=False), (12, False))
        self.assertEqual(mac_int8(7, 9, 12, clear=True), (0, False))

    def test_validation(self) -> None:
        for invalid in (-129, 128):
            with self.assertRaises(ValueError):
                mac_int8(invalid, 0, 0)
        with self.assertRaises(TypeError):
            mac_int8(1.5, 1, 0)
        with self.assertRaises(ValueError):
            mac_int8(1, 1, 0, acc_width=15)

if __name__ == "__main__":
    unittest.main(verbosity=2)
