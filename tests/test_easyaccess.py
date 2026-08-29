##  python-exiv2 - Python interface to libexiv2
##  http://github.com/jim-easterbrook/python-exiv2
##  Copyright (C) 2023-26  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')

    def check_result(self, datum, expected_type=None):
        # not all files have a value
        if datum is not None:
            self.assertIsInstance(datum, exiv2.Exifdatum)
            self.assertIsInstance(datum.getValue(), expected_type)

    def test_easyaccess(self):
        image = exiv2.ImageFactory.open(self.image_path)
        image.readMetadata()
        exif_data = image.exifData()
        self.check_result(exiv2.afPoint(exif_data))
        self.check_result(exiv2.contrast(exif_data))
        self.check_result(exiv2.exposureMode(exif_data))
        self.check_result(exiv2.exposureTime(exif_data))
        self.check_result(exiv2.fNumber(exif_data), exiv2.URationalValue)
        self.check_result(exiv2.flashBias(exif_data))
        self.check_result(exiv2.focalLength(exif_data), exiv2.URationalValue)
        self.check_result(exiv2.imageQuality(exif_data))
        self.check_result(exiv2.isoSpeed(exif_data))
        self.check_result(exiv2.lensName(exif_data), exiv2.AsciiValue)
        self.check_result(exiv2.macroMode(exif_data))
        self.check_result(exiv2.make(exif_data))
        self.check_result(exiv2.meteringMode(exif_data))
        self.check_result(exiv2.model(exif_data))
        self.check_result(exiv2.orientation(exif_data), exiv2.UShortValue)
        self.check_result(exiv2.saturation(exif_data))
        self.check_result(exiv2.sceneCaptureType(exif_data))
        self.check_result(exiv2.sceneMode(exif_data))
        self.check_result(exiv2.serialNumber(exif_data))
        self.check_result(exiv2.sharpness(exif_data))
        self.check_result(exiv2.subjectDistance(exif_data))
        self.check_result(exiv2.whiteBalance(exif_data))
        if not exiv2.testVersion(0, 27, 4):
            self.skipTest('easyaccess funcs introduced in v0.27.4')
        self.check_result(exiv2.apertureValue(exif_data), exiv2.URationalValue)
        self.check_result(exiv2.brightnessValue(exif_data))
        self.check_result(exiv2.dateTimeOriginal(exif_data), exiv2.AsciiValue)
        self.check_result(exiv2.exposureBiasValue(exif_data))
        self.check_result(exiv2.exposureIndex(exif_data))
        self.check_result(exiv2.flash(exif_data))
        self.check_result(exiv2.flashEnergy(exif_data))
        self.check_result(exiv2.lightSource(exif_data))
        self.check_result(exiv2.maxApertureValue(exif_data))
        self.check_result(exiv2.sensingMethod(exif_data))
        self.check_result(exiv2.shutterSpeedValue(exif_data))
        self.check_result(exiv2.subjectArea(exif_data))


if __name__ == '__main__':
    unittest.main()
