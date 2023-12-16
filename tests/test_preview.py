##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2022-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


class TestPreviewModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        # read image file data into memory
        with open(cls.image_path, 'rb') as f:
            cls.image_data = f.read()
        cls.image = exiv2.ImageFactory.open(cls.image_data)
        cls.image.readMetadata()

    def test_PreviewImage(self):
        manager = exiv2.PreviewManager(self.image)
        props = manager.getPreviewProperties()
        preview = manager.getPreviewImage(props[0])
        self.assertIsInstance(preview, exiv2.PreviewImage)
        preview2 = exiv2.PreviewImage(preview)
        self.assertIsInstance(preview2, exiv2.PreviewImage)
        self.assertEqual(len(preview), preview.size())
        copy = preview.copy()
        self.assertIsInstance(copy, exiv2.DataBuf)
        with preview.pData() as data:
            self.assertIsInstance(data, memoryview)
            self.assertEqual(data[:10], b'\xff\xd8\xff\xe0\x00\x10JFIF')
            self.assertEqual(data, copy)
        self.assertEqual(memoryview(preview), copy)
        self.assertEqual(preview.extension(), '.jpg')
        self.assertEqual(preview.height(), 120)
        self.assertEqual(preview.id(), 4)
        self.assertEqual(preview.mimeType(), 'image/jpeg')
        self.assertEqual(preview.size(), 2532)
        self.assertEqual(preview.width(), 160)
        with tempfile.TemporaryDirectory() as tmp_dir:
            temp_file = os.path.join(tmp_dir, 'image.jpg')
            self.assertEqual(preview.writeFile(temp_file), 2532)

    def test_PreviewManager(self):
        manager = exiv2.PreviewManager(self.image)
        self.assertIsInstance(manager, exiv2.PreviewManager)
        props = manager.getPreviewProperties()
        self.assertIsInstance(props, tuple)
        self.assertEqual(len(props), 1)
        prop = props[0]
        self.assertIsInstance(prop, exiv2.PreviewProperties)
        preview = manager.getPreviewImage(prop)
        self.assertIsInstance(preview, exiv2.PreviewImage)

    def test_PreviewProperties(self):
        properties = exiv2.PreviewManager(self.image).getPreviewProperties()[0]
        self.assertIsInstance(properties, exiv2.PreviewProperties)
        self.assertEqual(properties.extension_, '.jpg')
        self.assertEqual(properties.height_, 120)
        self.assertEqual(properties.id_, 4)
        self.assertEqual(properties.mimeType_, 'image/jpeg')
        self.assertEqual(properties.size_, 2532)
        self.assertEqual(properties.width_, 160)

    def test_ref_counts(self):
        # manager keeps reference to image
        self.assertEqual(sys.getrefcount(self.image), 2)
        manager = exiv2.PreviewManager(self.image)
        self.assertEqual(sys.getrefcount(self.image), 3)


if __name__ == '__main__':
    unittest.main()
