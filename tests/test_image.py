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


class TestImageModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        # read image file data into memory
        with open(cls.image_path, 'rb') as f:
            cls.image_data = f.read()

    def test_Image(self):
        if exiv2.testVersion(0, 27, 4):
            self.assertIsInstance(exiv2.enableBMFF(True), bool)
        # open image in memory so we don't corrupt the file
        image = exiv2.ImageFactory.open(self.image_data)
        self.assertEqual(len(image.io()), 15125)
        # test clearMetadata
        image.readMetadata()
        self.assertEqual(image.comment(), 'Created with GIMP')
        self.assertEqual(len(image.exifData()), 29)
        self.assertEqual(len(image.iptcData()), 19)
        self.assertEqual(len(image.xmpData()), 26)
        self.assertEqual(len(image.iccProfile()), 672)
        image.clearMetadata()
        self.assertEqual(image.comment(), '')
        self.assertEqual(len(image.exifData()), 0)
        self.assertEqual(len(image.iptcData()), 0)
        self.assertEqual(len(image.xmpData()), 0)
        self.assertEqual(len(image.iccProfile()), 0)
        image.writeMetadata()
        self.assertEqual(len(image.io()), 6371)
        # test setting individual parts
        image2 = exiv2.ImageFactory.open(self.image_data)
        image2.readMetadata()
        image.setComment(image2.comment())
        self.assertEqual(image.comment(), 'Created with GIMP')
        image.setExifData(image2.exifData())
        self.assertEqual(len(image.exifData()), 29)
        image.setIptcData(image2.iptcData())
        self.assertEqual(len(image.iptcData()), 19)
        image.setXmpPacket(image2.xmpPacket())
        self.assertEqual(len(image.xmpPacket()), 4234)
        image.setXmpData(image2.xmpData())
        self.assertEqual(len(image.xmpData()), 26)
        image.setIccProfile(image2.iccProfile())
        self.assertEqual(len(image.iccProfile()), 672)
        image.writeMetadata()
        self.assertEqual(len(image.io()), 15125)
        del image2
        # test clearing individual parts
        image = exiv2.ImageFactory.open(self.image_data)
        image.readMetadata()
        self.assertEqual(image.comment(), 'Created with GIMP')
        image.clearComment()
        self.assertEqual(image.comment(), '')
        self.assertEqual(len(image.exifData()), 29)
        image.clearExifData()
        self.assertEqual(len(image.exifData()), 0)
        self.assertEqual(len(image.iptcData()), 19)
        image.clearIptcData()
        self.assertEqual(len(image.iptcData()), 0)
        self.assertEqual(len(image.xmpPacket()), 4234)
        image.clearXmpPacket()
        self.assertEqual(image.xmpPacket(), '')
        self.assertEqual(len(image.xmpData()), 26)
        image.clearXmpData()
        self.assertEqual(len(image.xmpData()), 0)
        self.assertEqual(len(image.iccProfile()), 672)
        image.clearIccProfile()
        self.assertEqual(len(image.iccProfile()), 0)
        # test other methods
        image.readMetadata()
        self.assertEqual(image.byteOrder(), exiv2.ByteOrder.littleEndian)
        self.assertEqual(image.checkMode(exiv2.MetadataId.Exif),
                         exiv2.AccessMode.ReadWrite)
        self.assertEqual(image.good(), True)
        self.assertEqual(image.iccProfileDefined(), True)
        self.assertEqual(image.imageType(), exiv2.ImageType.jpeg)
        self.assertIsInstance(image.io(), exiv2.BasicIo)
        self.assertEqual(image.mimeType(), 'image/jpeg')
        self.assertEqual(image.pixelHeight(), 200)
        self.assertEqual(image.pixelWidth(), 200)
        image.setByteOrder(exiv2.ByteOrder.littleEndian)
        image.setComment('fred')
        self.assertEqual(image.comment(), 'fred')

    def test_ImageFactory(self):
        factory = exiv2.ImageFactory
        self.assertEqual(
            factory.checkMode(exiv2.ImageType.jpeg, exiv2.MetadataId.Exif),
            exiv2.AccessMode.ReadWrite)
        io = exiv2.MemIo(self.image_data)
        self.assertEqual(
            factory.checkType(exiv2.ImageType.jpeg, io, False), True)
        self.assertIsInstance(
            factory.create(exiv2.ImageType.jpeg), exiv2.Image)
        with tempfile.TemporaryDirectory() as tmp_dir:
            temp_file = os.path.join(tmp_dir, 'image.jpg')
            self.assertIsInstance(
                factory.create(exiv2.ImageType.jpeg, temp_file), exiv2.Image)
        self.assertIsInstance(factory.createIo(self.image_path), exiv2.BasicIo)
        self.assertEqual(factory.getType(self.image_path), exiv2.ImageType.jpeg)
        self.assertEqual(factory.getType(self.image_data), exiv2.ImageType.jpeg)
        self.assertEqual(factory.getType(io), exiv2.ImageType.jpeg)
        self.assertIsInstance(factory.open(self.image_path), exiv2.Image)
        self.assertIsInstance(factory.open(self.image_data), exiv2.Image)

    def test_ref_counts(self):
        # opening from data keeps reference to buffer
        self.assertEqual(sys.getrefcount(self.image_data), 2)
        image = exiv2.ImageFactory.open(self.image_data)
        self.assertEqual(sys.getrefcount(self.image_data), 3)
        # writeMetadata releases buffer
        image.writeMetadata()
        self.assertEqual(sys.getrefcount(self.image_data), 2)
        # getting metadata and buffers keeps reference to image
        image = exiv2.ImageFactory.open(self.image_data)
        image.readMetadata()
        self.assertEqual(sys.getrefcount(image), 2)
        data = [image.exifData()]
        self.assertEqual(sys.getrefcount(image), 3)
        data.append(image.iptcData())
        self.assertEqual(sys.getrefcount(image), 4)
        data.append(image.xmpData())
        self.assertEqual(sys.getrefcount(image), 5)
        data.append(image.iccProfile())
        self.assertEqual(sys.getrefcount(image), 6)
        data.append(image.io())
        self.assertEqual(sys.getrefcount(image), 7)
        del data
        self.assertEqual(sys.getrefcount(image), 2)


if __name__ == '__main__':
    unittest.main()
