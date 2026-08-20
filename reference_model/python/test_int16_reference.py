import unittest
from int16_reference import mac_int16

class Int16ReferenceTests(unittest.TestCase):
    def test_extremes(self) -> None:
        self.assertEqual(mac_int16(32767, 32767, 0), (1073676289, True))
        self.assertEqual(mac_int16(-32768, -32768, 0), (1073741824, True))
        self.assertEqual(mac_int16(-32768, 32767, 0), (-1073709056, True))

    def test_controls(self) -> None:
        self.assertEqual(mac_int16(2, 3, 9, enable=False), (9, False))
        self.assertEqual(mac_int16(2, 3, 9, valid_in=False), (9, False))
        self.assertEqual(mac_int16(2, 3, 9, clear=True), (0, False))

    def test_wrap(self) -> None:
        maximum = (1 << 47) - 1
        self.assertEqual(mac_int16(1, 1, maximum), (-(1 << 47), True))

if __name__ == "__main__":
    unittest.main(verbosity=2)
