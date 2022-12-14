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


class TestDataRead(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        image = exiv2.ImageFactory.open(os.path.join(test_dir, 'image_02.jpg'))
        image.readMetadata()
        cls.exifData = image.exifData()
        cls.iptcData = image.iptcData()
        cls.xmpData = image.xmpData()

    def test_exif(self):
        for tag, exiv_type, value in (
                ('Exif.Image.ImageDescription', exiv2.AsciiValue,
                 'Good view of the lighthouse.'),
                ('Exif.Image.Orientation', exiv2.UShortValue, [1]),
                ('Exif.Photo.LensSpecification', exiv2.URationalValue,
                 [(18, 1), (200, 1), (7, 2), (63, 10)]),
                ('Exif.Thumbnail.ImageWidth', exiv2.ULongValue, [160]),
                ):
            datum = self.exifData[tag]
            exiv_value = exiv_type(datum.value())
            if isinstance(value, list):
                self.assertEqual(list(exiv_value.value_), value)
            else:
                self.assertEqual(exiv_value.value_, value)
        thumb = exiv2.ExifThumb(self.exifData)
        data = bytes(thumb.copy())
        self.assertEqual(len(data), 2532)
        self.assertEqual(
            data[:15], b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00')

    def test_iptc(self):
        for tag, exiv_type, value in (
                ('Iptc.Application2.Caption', exiv2.StringValue,
                 ['Good view of the lighthouse.']),
                ('Iptc.Application2.DateCreated', exiv2.DateValue,
                 [(2022, 8, 17)]),
                ('Iptc.Application2.TimeCreated', exiv2.TimeValue,
                 [(12, 45, 28, 1, 0)]),
                ):
            datum = self.iptcData[tag]
            exiv_value = exiv_type(datum.value())
            self.assertEqual(list(exiv_value), value)

    def test_xmp(self):
        for tag, exiv_type, value in (
                ('Xmp.photoshop.Credit', exiv2.XmpTextValue,
                 'Jim Easterbrook'),
                ('Xmp.dc.creator', exiv2.XmpArrayValue, ['Jim Easterbrook']),
                ('Xmp.dc.subject', exiv2.XmpArrayValue,
                 ['lighthouse', 'Scotland']),
                ('Xmp.dc.description', exiv2.LangAltValue,
                 {'x-default': 'Good view of the lighthouse.',
                  'en-GB': 'Good view of the lighthouse.',
                  'de': 'Gute Sicht auf den Leuchtturm.'}),
                ):
            datum = self.xmpData[tag]
            exiv_value = exiv_type(datum.value())
            if exiv_type == exiv2.XmpArrayValue:
                self.assertEqual(list(exiv_value), value)
            elif exiv_type == exiv2.LangAltValue:
                self.assertEqual(dict(exiv_value.value_), value)
            else:
                self.assertEqual(exiv_value.value_, value)


if __name__ == '__main__':
    unittest.main()
