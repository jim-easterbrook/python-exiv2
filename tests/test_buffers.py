##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2022  Jim Easterbrook  jim@jim-easterbrook.me.uk
##
##  This program is free software: you can redistribute it and/or
##  modify it under the terms of the GNU General Public License as
##  published by the Free Software Foundation, either version 3 of the
##  License, or (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see
##  <http://www.gnu.org/licenses/>.

import os
import random
import unittest

import exiv2


class TestBuffers(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.path = os.path.join(test_dir, 'image_01.jpg')

    def test_Image_io(self):
        image = exiv2.ImageFactory.open(self.path)
        image_data = bytes(image.io())
        with open(self.path, 'rb') as in_file:
            self.assertEqual(image_data, in_file.read())

    def test_DataValue(self):
        py_data_1 = bytes(random.choices(range(256), k=128))
        exv_data = exiv2.DataValue(py_data_1)
        py_data_2 = bytearray(len(exv_data))
        exv_data.copy(py_data_2)
        self.assertEqual(py_data_1, py_data_2)


if __name__ == '__main__':
    unittest.main()
