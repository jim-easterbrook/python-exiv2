##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2022-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        # read image file data into memory
        with open(cls.image_path, 'rb') as f:
            cls.image_data = f.read()
        cls.image = exiv2.ImageFactory.open(cls.image_data)
        cls.image.readMetadata()

    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

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
            self.check_result(data, memoryview, copy)
            self.assertEqual(data[:10], b'\xff\xd8\xff\xe0\x00\x10JFIF')
        self.assertEqual(memoryview(preview), copy)
        self.check_result(preview.extension(), str, '.jpg')
        self.check_result(preview.height(), int, 120)
        self.check_result(preview.id(), int, 4)
        self.check_result(preview.mimeType(), str, 'image/jpeg')
        self.check_result(preview.size(), int, 2532)
        self.check_result(preview.width(), int, 160)
        if not exiv2.versionInfo()['EXV_ENABLE_FILESYSTEM']:
            self.skipTest('EXV_ENABLE_FILESYSTEM is off')
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
        self.check_result(properties.extension_, str, '.jpg')
        self.check_result(properties.height_, int, 120)
        self.check_result(properties.id_, int, 4)
        self.check_result(properties.mimeType_, str, 'image/jpeg')
        self.check_result(properties.size_, int, 2532)
        self.check_result(properties.width_, int, 160)
        keys = properties.keys()
        self.assertIsInstance(keys, list)
        self.assertEqual(len(keys), 6)
        values = properties.values()
        self.assertIsInstance(values, list)
        self.assertEqual(len(values), 6)
        items = properties.items()
        self.assertIsInstance(items, list)
        self.assertEqual(len(items), 6)
        for k in properties:
            v = properties[k]
            self.assertIn(k, keys)
            self.assertIn(v, values)
            self.assertIn((k, v), items)
            with self.assertRaises(TypeError):
                properties[k] = 123
            with self.assertRaises(TypeError):
                del properties[k]
        with self.assertRaises(KeyError):
            a = properties['fred']
        with self.assertRaises(KeyError):
            properties['fred'] = 123

    def test_ref_counts(self):
        # manager keeps reference to image
        self.assertEqual(sys.getrefcount(self.image), 2)
        manager = exiv2.PreviewManager(self.image)
        self.assertEqual(sys.getrefcount(self.image), 3)


if __name__ == '__main__':
    unittest.main()
