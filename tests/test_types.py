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


class TestTypesModule(unittest.TestCase):
    def test_DataBuf(self):
        data = bytes(random.choices(range(256), k=128))
        # constructors
        buf = exiv2.DataBuf()
        self.assertIsInstance(buf, exiv2.DataBuf)
        self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf(4)
        self.assertEqual(len(buf), 4)
        buf = exiv2.DataBuf(data)
        self.assertEqual(len(buf), len(data))
        self.assertEqual(buf.data(), data)
        # other methods
        result = buf.size()
        self.assertIsInstance(result, int)
        self.assertEqual(result, len(data))
        with buf.data() as view:
            self.assertIsInstance(view, memoryview)
            result = view[23]
            self.assertIsInstance(result, int)
            self.assertEqual(result, data[23])
            view[49] = 99
            self.assertEqual(view[49], 99)
        buf = exiv2.DataBuf(data)
        if exiv2.testVersion(0, 28, 0):
            self.assertEqual(buf.cmpBytes(0, data), 0)
            self.assertEqual(buf.cmpBytes(5, data[5:]), 0)
            self.assertNotEqual(buf.cmpBytes(0, b'fred'), 0)
            buf.resize(6)
            self.assertEqual(len(buf), 6)
            self.assertEqual(buf.empty(), False)
            buf.resize(0)
            self.assertEqual(buf.empty(), True)
        else:
            with self.assertWarns(DeprecationWarning):
                result = buf[23]
            buf.free()
            self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf(data)
        buf.reset()
        self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf()
        buf.alloc(6)
        self.assertEqual(len(buf), 6)


if __name__ == '__main__':
    unittest.main()
