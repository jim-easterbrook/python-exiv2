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
import unittest

import exiv2


class TestEasyaccessModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        image = exiv2.ImageFactory.open(os.path.join(test_dir, 'image_02.jpg'))
        image.readMetadata()
        cls.exif_data = image.exifData()

    def test_easyaccess(self):
        for func_name, value_type in (
                ('afPoint', None),
                ('apertureValue', exiv2.URationalValue),
                ('brightnessValue', None),
                ('contrast', None),
                ('dateTimeOriginal', exiv2.AsciiValue),
                ('exposureBiasValue', None),
                ('exposureIndex', None),
                ('exposureMode', None),
                ('exposureTime', None),
                ('fNumber', exiv2.URationalValue),
                ('flash', None),
                ('flashBias', None),
                ('flashEnergy', None),
                ('focalLength', exiv2.URationalValue),
                ('imageQuality', None),
                ('isoSpeed', None),
                ('lensName', exiv2.AsciiValue),
                ('lightSource', None),
                ('macroMode', None),
                ('make', None),
                ('maxApertureValue', None),
                ('meteringMode', None),
                ('model', None),
                ('orientation', exiv2.UShortValue),
                ('saturation', None),
                ('sceneCaptureType', None),
                ('sceneMode', None),
                ('sensingMethod', None),
                ('serialNumber', None),
                ('sharpness', None),
                ('shutterSpeedValue', None),
                ('subjectArea', None),
                ('subjectDistance', None),
                ('whiteBalance', None),
                ):
            # not all versions of libexiv2 have all easyaccess functions
            if hasattr(exiv2, func_name):
                datum = getattr(exiv2, func_name)(self.exif_data)
                # not all files have a value
                if datum is not None:
                    self.assertIsInstance(datum, exiv2.Exifdatum)
                    self.assertIsInstance(datum.getValue(), value_type)


if __name__ == '__main__':
    unittest.main()
