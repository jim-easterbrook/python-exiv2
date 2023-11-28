##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2023  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
import sys
import unittest

import exiv2


class TestValueModule(unittest.TestCase):
    def test_DataValue(self):
        py_data_1 = bytes(random.choices(range(256), k=128))
        exv_data = exiv2.DataValue(py_data_1)
        py_data_2 = bytearray(len(exv_data))
        exv_data.copy(py_data_2)
        self.assertEqual(py_data_1, py_data_2)

    def do_string_tests(self, exiv2_type, exiv2_id):
        value = exiv2_type('fred')
        self.assertEqual(value.typeId(), exiv2_id)
        self.assertEqual(value.count(), 4)
        self.assertEqual(value.data(), b'fred')
        self.assertEqual(value.size(), 4)
        self.assertEqual(str(value), 'fred')
        self.assertEqual(len(value), 4)
        value = exiv2_type()
        value.read('The quick brown fox')
        self.assertEqual(str(value), 'The quick brown fox')

    def test_string_types(self):
        self.do_string_tests(exiv2.XmpTextValue, exiv2.TypeId.xmpText)
        self.do_string_tests(exiv2.StringValue, exiv2.TypeId.string)
        self.do_string_tests(exiv2.AsciiValue, exiv2.TypeId.asciiString)


if __name__ == '__main__':
    unittest.main()
