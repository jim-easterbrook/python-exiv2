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
            exiv_value = datum.value()
            self.assertIsInstance(exiv_value, exiv_type)
            if exiv_type == exiv2.AsciiValue:
                self.assertEqual(str(exiv_value), value)
            else:
                self.assertEqual(len(exiv_value), len(value))
                self.assertEqual(list(exiv_value), value)
        thumb = exiv2.ExifThumb(self.exifData).copy()
        data = memoryview(thumb.data())
        self.assertEqual(len(data), 2532)
        self.assertEqual(
            data[:15], b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00')

    def test_iptc(self):
        datum = self.iptcData['Iptc.Application2.Caption']
        exiv_value = datum.value()
        self.assertIsInstance(exiv_value, exiv2.StringValue)
        self.assertEqual(str(exiv_value), 'Good view of the lighthouse.')

        datum = self.iptcData['Iptc.Application2.DateCreated']
        exiv_value = datum.value()
        self.assertIsInstance(exiv_value, exiv2.DateValue)
        self.assertEqual(dict(exiv_value.getDate()),
                         {'year': 2022, 'month': 8, 'day': 17})

        datum = self.iptcData['Iptc.Application2.TimeCreated']
        exiv_value = datum.value()
        self.assertIsInstance(exiv_value, exiv2.TimeValue)
        self.assertEqual(dict(exiv_value.getTime()),
                         {'hour': 12, 'minute': 45, 'second': 28,
                          'tzHour': 1, 'tzMinute': 0})

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
            exiv_value = datum.value()
            self.assertIsInstance(exiv_value, exiv_type)
            if exiv_type == exiv2.XmpArrayValue:
                self.assertEqual(list(exiv_value), value)
            elif exiv_type == exiv2.LangAltValue:
                self.assertEqual(dict(exiv_value), value)
            else:
                self.assertEqual(str(exiv_value), value)

    def test_set_value(self):
        datum = self.exifData['Exif.GPSInfo.GPSLatitude']
        value = datum.getValue()
        # set value
        self.assertEqual(list(value), [(57, 1), (51, 1), (146751, 5000)])
        value[1] = (45, 1)
        self.assertEqual(list(value), [(57, 1), (45, 1), (146751, 5000)])
        del value[1]
        self.assertEqual(list(value), [(57, 1), (146751, 5000)])
        value.append((12, 34))
        self.assertEqual(list(value), [(57, 1), (146751, 5000), (12, 34)])
        # set datum
        self.assertEqual(list(datum.value()), [(57, 1), (51, 1), (146751, 5000)])
        self.exifData['Exif.GPSInfo.GPSLatitude'] = exiv2.URationalValue(
            [(23, 1), (47, 1), (3592, 100)])
        self.assertEqual(list(datum.value()), [(23, 1), (47, 1), (3592, 100)])
        self.exifData['Exif.GPSInfo.GPSLatitude'] = '23/1 46/1'
        self.assertEqual(list(datum.value()), [(23, 1), (46, 1)])
        del self.exifData['Exif.GPSInfo.GPSLatitude']
        datum = self.exifData['Exif.GPSInfo.GPSLatitude']
        with self.assertRaises(exiv2.Exiv2Error):
            self.assertEqual(datum.value(), [])


if __name__ == '__main__':
    unittest.main()
