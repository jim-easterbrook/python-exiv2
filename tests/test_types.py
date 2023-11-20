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
import sys
import unittest

import exiv2


class TestTypes(unittest.TestCase):
    def test_data_buf(self):
        buf = exiv2.DataBuf()
        self.assertEqual(buf.size(), 0)
        self.assertEqual(len(buf), 0)
        self.assertEqual(buf.data(), b'')
        buf = exiv2.DataBuf(4)
        self.assertEqual(len(buf), 4)
        self.assertEqual(buf.data(), b'\x00\x00\x00\x00')
        buf = exiv2.DataBuf(b'fred')
        self.assertEqual(len(buf), 4)
        self.assertEqual(buf.data(), b'fred')
        buf.data()[1] = ord('e')
        self.assertEqual(buf.data(), b'feed')
        if exiv2.testVersion(0, 28, 0):
            self.assertEqual(buf.cmpBytes(0, b'feed'), 0)
            self.assertEqual(buf.cmpBytes(2, b'ed'), 0)
            self.assertNotEqual(buf.cmpBytes(0, b'fred'), 0)
            buf.resize(6)
            self.assertEqual(len(buf), 6)
            self.assertEqual(buf.empty(), False)
            self.assertEqual(buf.data()[:4], b'feed')
            buf.resize(0)
            self.assertEqual(buf.empty(), True)
        else:
            with self.assertWarns(DeprecationWarning):
                a = buf[0]
            with self.assertWarns(DeprecationWarning):
                m = memoryview(buf)
        buf.alloc(6)
        self.assertEqual(len(buf), 6)
        if exiv2.testVersion(0, 28, 0):
            buf.reset()
            self.assertEqual(buf.empty(), True)
        else:
            buf.free()
        self.assertEqual(len(buf), 0)


if __name__ == '__main__':
    unittest.main()
