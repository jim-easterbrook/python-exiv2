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
        def check_data(value, data):
            copy = bytearray(len(data))
            self.assertEqual(value.copy(copy), len(data))
            self.assertEqual(copy, data)

        data = bytes(random.choices(range(256), k=128))
        # constructors
        value = exiv2.DataValue()
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.Value.create(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(data)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        value = exiv2.DataValue(data, exiv2.TypeId.undefined)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        # other methods
        self.assertEqual(str(value), ' '.join(str(x) for x in data))
        clone = value.clone()
        self.assertIsInstance(clone, exiv2.DataValue)
        check_data(clone, data)
        count = value.count()
        self.assertIsInstance(count, int)
        self.assertEqual(count, len(data))
        value = exiv2.DataValue()
        self.assertEqual(value.read(data), 0)
        check_data(value, data)
        value = exiv2.DataValue()
        self.assertEqual(value.read(' '.join(str(x) for x in data)), 0)
        check_data(value, data)
        size = value.size()
        self.assertIsInstance(size, int)
        self.assertEqual(size, len(data))
        result = value.toFloat(0)
        self.assertIsInstance(result, float)
        self.assertEqual(result, float(data[0]))
        if exiv2.testVersion(0, 28, 0):
            result = value.toInt64(0)
        else:
            result = value.toLong(0)
        self.assertIsInstance(result, int)
        self.assertEqual(result, int(data[0]))
        result = value.toRational(0)
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, (data[0], 1))
        result = value.toString(0)
        self.assertIsInstance(result, str)
        self.assertEqual(result, str(data[0]))
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        result = value.ok()
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        self.assertEqual(value.setDataArea(b'fred'), -1)
        result = value.sizeDataArea()
        self.assertIsInstance(result, int)
        self.assertEqual(result, 0)
        type_id = value.typeId()
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.undefined)

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
