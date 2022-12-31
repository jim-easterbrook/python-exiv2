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
import sys
import unittest

import exiv2


class TestReferenceCounts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.image = exiv2.ImageFactory.open(
            os.path.join(test_dir, 'image_02.jpg'))
        cls.image.readMetadata()

    def test_data(self):
        self.assertEqual(sys.getrefcount(self.image), 2)
        exifData = self.image.exifData()
        self.assertEqual(sys.getrefcount(exifData), 2)
        datum = exifData['Exif.Image.ImageDescription']
        self.assertEqual(sys.getrefcount(datum), 2)
        value = datum.value()
        self.assertEqual(sys.getrefcount(datum), 3)
        del value
        self.assertEqual(sys.getrefcount(datum), 2)
        self.assertEqual(sys.getrefcount(exifData), 3)
        del datum
        self.assertEqual(sys.getrefcount(exifData), 2)
        self.assertEqual(sys.getrefcount(self.image), 3)
        del exifData
        self.assertEqual(sys.getrefcount(self.image), 2)

    def test_io(self):
        self.assertEqual(sys.getrefcount(self.image), 2)
        io = self.image.io()
        self.assertEqual(sys.getrefcount(io), 2)
        io.open()
        mmap = io.mmap()
        self.assertEqual(sys.getrefcount(io), 3)
        del mmap
        self.assertEqual(sys.getrefcount(io), 2)
        self.assertEqual(sys.getrefcount(self.image), 3)
        del io
        self.assertEqual(sys.getrefcount(self.image), 2)

    def test_iterator(self):
        exifData = self.image.exifData()
        self.assertEqual(sys.getrefcount(exifData), 2)
        # iterators point into exifData, so keep a reference to it
        iterator = exifData.begin()
        self.assertEqual(sys.getrefcount(exifData), 3)
        # creating a new iterator increments the parent reference count
        self.assertEqual(sys.getrefcount(iterator), 2)
        new_iterator = iter(iterator)
        self.assertEqual(sys.getrefcount(iterator), 3)
        del new_iterator
        self.assertEqual(sys.getrefcount(iterator), 2)
        del iterator
        self.assertEqual(sys.getrefcount(exifData), 2)


if __name__ == '__main__':
    unittest.main()
