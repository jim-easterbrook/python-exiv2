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


class TestIterators(unittest.TestCase):
    def setUp(self):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        image = exiv2.ImageFactory.open(os.path.join(test_dir, 'image_01.jpg'))
        image.readMetadata()
        self.exifData = image.exifData()
        self.iptcData = image.iptcData()
        self.xmpData = image.xmpData()

    def iterator_test_python_style(self, data, result):
        keys = []
        for datum in data:
            keys.append(datum.key())
        self.assertEqual(keys, result)

    def iterator_test_c_style(self, data, result):
        keys = []
        b = data.begin()
        e = data.end()
        while b != e:
            keys.append(b.key())
            next(b)
        self.assertEqual(keys, result)

    def iterator_test_mixed(self, data, result):
        keys = []
        for datum in data.begin():
            keys.append(datum.key())
        self.assertEqual(keys, result)

    def test_iterators(self):
        exif_keys = [
            'Exif.Image.ProcessingSoftware', 'Exif.Image.ImageDescription',
            'Exif.Image.DateTime', 'Exif.Image.ExifTag',
            'Exif.Photo.DateTimeOriginal', 'Exif.Photo.DateTimeDigitized',
            'Exif.Photo.SubSecTime', 'Exif.Photo.SubSecTimeOriginal',
            'Exif.Photo.SubSecTimeDigitized']
        self.iterator_test_python_style(self.exifData, exif_keys)
        self.iterator_test_c_style(self.exifData, exif_keys)
        self.iterator_test_mixed(self.exifData, exif_keys)
        iptc_keys = [
            'Iptc.Envelope.CharacterSet', 'Iptc.Application2.DigitizationDate',
            'Iptc.Application2.DigitizationTime',
            'Iptc.Application2.DateCreated', 'Iptc.Application2.TimeCreated',
            'Iptc.Application2.Caption', 'Iptc.Application2.Keywords',
            'Iptc.Application2.Keywords', 'Iptc.Application2.Program',
            'Iptc.Application2.ProgramVersion']
        self.iterator_test_python_style(self.iptcData, iptc_keys)
        self.iterator_test_c_style(self.iptcData, iptc_keys)
        self.iterator_test_mixed(self.iptcData, iptc_keys)
        xmp_keys = [
            'Xmp.xmp.CreateDate', 'Xmp.xmp.ModifyDate',
            'Xmp.photoshop.DateCreated', 'Xmp.dc.description',
            'Xmp.dc.subject']
        self.iterator_test_python_style(self.xmpData, xmp_keys)
        self.iterator_test_c_style(self.xmpData, xmp_keys)
        self.iterator_test_mixed(self.xmpData, xmp_keys)

    def find_erase_test(self, data, key, value):
        pos = data.findKey(key)
        self.assertNotEqual(pos, data.end())
        self.assertEqual(pos.key(), key.key())
        self.assertEqual(pos.toString(), value)
        data.erase(pos)
        pos = data.findKey(key)
        self.assertEqual(pos, data.end())

    def test_find_erase(self):
        self.find_erase_test(
            self.exifData, exiv2.ExifKey('Exif.Image.ImageDescription'),
            'Description')
        self.find_erase_test(
            self.iptcData, exiv2.IptcKey('Iptc.Application2.Caption'),
            'Description')
        self.find_erase_test(
            self.xmpData, exiv2.XmpKey('Xmp.dc.description'),
            'lang="en-GB" Description')

    def test_empty(self):
        data = exiv2.ExifData()
        self.assertEqual(data.begin(), data.end())
        for datum in data:
            self.fail('not empty')
        for datum in data.begin():
            self.fail('not empty')
        for datum in data.end():
            self.fail('not empty')


if __name__ == '__main__':
    unittest.main()
