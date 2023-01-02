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
import unittest

import exiv2


class TestPreviewManager(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.path = os.path.join(test_dir, 'image_02.jpg')

    def test_manager(self):
        image = exiv2.ImageFactory.open(self.path)
        image.readMetadata()
        manager = exiv2.PreviewManager(image)
        del image
        props = manager.getPreviewProperties()
        prop = props[0]
        del props
        self.assertEqual(prop.width_, 160)
        preview = manager.getPreviewImage(prop)
        del manager, prop
        self.assertEqual(preview.width(), 160)
        self.assertEqual(
            bytes(preview.pData())[:10], b'\xff\xd8\xff\xe0\x00\x10JFIF')


if __name__ == '__main__':
    unittest.main()
