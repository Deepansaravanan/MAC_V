import unittest
from mac_array_reference import array_step

class ArrayReferenceTests(unittest.TestCase):
    def test_dot_product(self)->None:
        self.assertEqual(array_step([1,2,3,4],[2,3,4,5],0,mode_int16=False),(40,True))
    def test_controls(self)->None:
        self.assertEqual(array_step([1]*4,[2]*4,9,mode_int16=True,enable=False),(9,False))
        self.assertEqual(array_step([1]*4,[2]*4,9,mode_int16=True,clear=True),(0,False))

if __name__=="__main__":unittest.main(verbosity=2)
