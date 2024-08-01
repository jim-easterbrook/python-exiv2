##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2023-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        cls.bmff_path = os.path.join(test_dir, 'image_02.heic')
        # read image file data into memory
        with open(cls.image_path, 'rb') as f:
            cls.image_data = f.read()

    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_BMFF(self):
        with self.assertWarns(DeprecationWarning):
            enabled = exiv2.enableBMFF(True)
        self.assertEqual(enabled, exiv2.versionInfo()['EXV_ENABLE_BMFF'])
        with open(self.bmff_path, 'rb') as f:
            image_data = f.read()
        if not exiv2.versionInfo()['EXV_ENABLE_BMFF']:
            if (exiv2.testVersion(0, 28, 0)
                    or not exiv2.versionInfo()['EXV_ENABLE_VIDEO']):
                with self.assertRaises(exiv2.Exiv2Error) as cm:
                    image = exiv2.ImageFactory.open(image_data)
                self.assertEqual(cm.exception.code,
                                 exiv2.ErrorCode.kerMemoryContainsUnknownImageType)
            self.skipTest('EXV_ENABLE_BMFF is off')
        image = exiv2.ImageFactory.open(image_data)
        image.readMetadata()
        self.assertEqual(len(image.exifData()), 29)
        self.assertEqual(len(image.iptcData()), 0)
        self.assertEqual(len(image.xmpData()), 26)
        self.assertEqual(len(image.iccProfile()), 672)

    def test_Image(self):
        # open image in memory so we don't corrupt the file
        image = exiv2.ImageFactory.open(self.image_data)
        self.assertEqual(len(image.io()), 15125)
        # test clearMetadata
        image.readMetadata()
        self.check_result(image.comment(), str, 'Created with GIMP')
        self.assertEqual(len(image.exifData()), 29)
        self.assertEqual(len(image.iptcData()), 19)
        self.assertEqual(len(image.xmpData()), 26)
        self.assertEqual(len(image.iccProfile()), 672)
        image.clearMetadata()
        self.check_result(image.comment(), str, '')
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
        self.check_result(image.comment(), str, 'Created with GIMP')
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
        self.check_result(image.comment(), str, 'Created with GIMP')
        image.clearComment()
        self.check_result(image.comment(), str, '')
        self.assertEqual(len(image.exifData()), 29)
        image.clearExifData()
        self.assertEqual(len(image.exifData()), 0)
        self.assertEqual(len(image.iptcData()), 19)
        image.clearIptcData()
        self.assertEqual(len(image.iptcData()), 0)
        self.assertEqual(len(image.xmpPacket()), 4234)
        image.clearXmpPacket()
        self.check_result(image.xmpPacket(), str, '')
        self.assertEqual(len(image.xmpData()), 26)
        image.clearXmpData()
        self.assertEqual(len(image.xmpData()), 0)
        self.assertEqual(len(image.iccProfile()), 672)
        image.clearIccProfile()
        self.assertEqual(len(image.iccProfile()), 0)
        # test other methods
        image.readMetadata()
        self.check_result(image.byteOrder(),
                          exiv2.ByteOrder, exiv2.ByteOrder.littleEndian)
        self.check_result(image.checkMode(exiv2.MetadataId.Exif),
                          exiv2.AccessMode, exiv2.AccessMode.ReadWrite)
        self.check_result(image.good(), bool, True)
        self.check_result(image.iccProfileDefined(), bool, True)
        self.check_result(image.imageType(),
                          exiv2.ImageType, exiv2.ImageType.jpeg)
        self.assertIsInstance(image.io(), exiv2.BasicIo)
        self.check_result(image.mimeType(), str, 'image/jpeg')
        self.check_result(image.pixelHeight(), int, 200)
        self.check_result(image.pixelWidth(), int, 200)
        image.setByteOrder(exiv2.ByteOrder.littleEndian)
        image.setComment('fred')
        self.check_result(image.comment(), str, 'fred')

    def test_ImageFactory(self):
        factory = exiv2.ImageFactory
        with self.assertWarns(DeprecationWarning):
            factory.checkMode(int(exiv2.ImageType.jpeg), exiv2.MetadataId.Exif)
        self.check_result(
            factory.checkMode(exiv2.ImageType.jpeg, exiv2.MetadataId.Exif),
            exiv2.AccessMode, exiv2.AccessMode.ReadWrite)
        io = factory.createIo(self.image_data)
        with self.assertWarns(DeprecationWarning):
            factory.checkType(int(exiv2.ImageType.jpeg), io, False)
        self.check_result(
            factory.checkType(exiv2.ImageType.jpeg, io, False), bool, True)
        with self.assertWarns(DeprecationWarning):
            factory.create(int(exiv2.ImageType.jpeg))
        self.assertIsInstance(
            factory.create(exiv2.ImageType.jpeg), exiv2.Image)
        self.assertIsInstance(factory.createIo(self.image_data), exiv2.BasicIo)
        self.check_result(factory.getType(self.image_data),
                          exiv2.ImageType, exiv2.ImageType.jpeg)
        self.check_result(factory.getType(io),
                          exiv2.ImageType, exiv2.ImageType.jpeg)
        self.assertIsInstance(factory.open(self.image_data), exiv2.Image)
        if not exiv2.versionInfo()['EXV_ENABLE_FILESYSTEM']:
            self.skipTest('EXV_ENABLE_FILESYSTEM is off')
        with tempfile.TemporaryDirectory() as tmp_dir:
            temp_file = os.path.join(tmp_dir, 'image.jpg')
            self.assertIsInstance(
                factory.create(exiv2.ImageType.jpeg, temp_file), exiv2.Image)
        self.assertIsInstance(factory.createIo(self.image_path), exiv2.BasicIo)
        self.check_result(factory.getType(self.image_path),
                          exiv2.ImageType, exiv2.ImageType.jpeg)
        self.assertIsInstance(factory.open(self.image_path), exiv2.Image)

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
