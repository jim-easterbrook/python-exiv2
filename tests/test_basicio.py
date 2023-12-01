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
import tempfile
import unittest

import exiv2


class TestBasicIoModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        cls.data = b'The quick brown fox jumps over the lazy dog'

    def test_FileIo(self):
        # most functions are tested in test_MemIo
        io = exiv2.FileIo(self.image_path)
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.error(), False)
        self.assertEqual(io.path(), self.image_path)
        self.assertEqual(io.size(), 15125)
        # open and close
        self.assertEqual(io.isopen(), False)
        self.assertEqual(io.open(), 0)
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.close(), 0)
        self.assertEqual(io.isopen(), False)

    def test_MemIo(self):
        io = exiv2.MemIo(self.data)
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.error(), False)
        self.assertEqual(io.path(), 'MemIo')
        self.assertEqual(io.size(), len(self.data))
        self.assertEqual(len(io), len(self.data))
        # open and close, MemIo is always open
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.close(), 0)
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.open(), 0)
        self.assertEqual(io.isopen(), True)
        # mmap data access
        with io.mmap() as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, self.data)
        self.assertEqual(io.munmap(), 0)
        # Python buffer interface
        with memoryview(io) as view:
            self.assertEqual(view, self.data)
            self.assertEqual(view.readonly, False)
        # seek & tell
        with self.assertWarns(DeprecationWarning):
            self.assertEqual(io.seek(0, exiv2.Position.beg), 0)
        self.assertEqual(io.tell(), 0)
        self.assertEqual(io.seek(0, exiv2.BasicIo.Position.end), 0)
        self.assertEqual(io.tell(), len(self.data))
        # reading data
        self.assertEqual(io.seek(0, exiv2.BasicIo.Position.beg), 0)
        self.assertEqual(io.getb(), self.data[0])
        self.assertEqual(io.tell(), 1)
        self.assertEqual(memoryview(io.read(10000)), self.data[1:])
        self.assertEqual(io.tell(), len(self.data))
        self.assertEqual(io.eof(), True)
        # writing data
        self.assertEqual(io.putb(ord('+')), ord('+'))
        self.assertEqual(io.eof(), True)
        self.assertEqual(len(io), len(self.data) + 1)
        self.assertEqual(io.write(exiv2.MemIo(b'fred')), 4)
        self.assertEqual(len(io), len(self.data) + 5)
        self.assertEqual(io.write(b'+jim'), 4)
        self.assertEqual(len(io), len(self.data) + 9)
        self.assertEqual(memoryview(io), self.data + b'+fred+jim')

    def test_ref_counts(self):
        # MemIo keeps a reference to the data buffer
        self.assertEqual(sys.getrefcount(self.data), 3)
        io = exiv2.MemIo(self.data)
        self.assertEqual(sys.getrefcount(self.data), 4)
        del io
        self.assertEqual(sys.getrefcount(self.data), 3)


if __name__ == '__main__':
    unittest.main()
