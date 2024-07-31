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
import unittest

import exiv2


class TestEasyaccessModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_dir = os.path.dirname(__file__)
        with open(os.path.join(test_dir, 'image_02.jpg'), 'rb') as f:
            image = exiv2.ImageFactory.open(f.read())
        image.readMetadata()
        cls.exif_data = image.exifData()

    def check_result(self, datum, expected_type=None):
        # not all files have a value
        if datum is not None:
            self.assertIsInstance(datum, exiv2.Exifdatum)
            self.assertIsInstance(datum.getValue(), expected_type)

    def test_easyaccess(self):
        self.check_result(exiv2.afPoint(self.exif_data))
        self.check_result(exiv2.contrast(self.exif_data))
        self.check_result(exiv2.exposureMode(self.exif_data))
        self.check_result(exiv2.exposureTime(self.exif_data))
        self.check_result(exiv2.fNumber(self.exif_data), exiv2.URationalValue)
        self.check_result(exiv2.flashBias(self.exif_data))
        self.check_result(exiv2.focalLength(self.exif_data), exiv2.URationalValue)
        self.check_result(exiv2.imageQuality(self.exif_data))
        self.check_result(exiv2.isoSpeed(self.exif_data))
        self.check_result(exiv2.lensName(self.exif_data), exiv2.AsciiValue)
        self.check_result(exiv2.macroMode(self.exif_data))
        self.check_result(exiv2.make(self.exif_data))
        self.check_result(exiv2.meteringMode(self.exif_data))
        self.check_result(exiv2.model(self.exif_data))
        self.check_result(exiv2.orientation(self.exif_data), exiv2.UShortValue)
        self.check_result(exiv2.saturation(self.exif_data))
        self.check_result(exiv2.sceneCaptureType(self.exif_data))
        self.check_result(exiv2.sceneMode(self.exif_data))
        self.check_result(exiv2.serialNumber(self.exif_data))
        self.check_result(exiv2.sharpness(self.exif_data))
        self.check_result(exiv2.subjectDistance(self.exif_data))
        self.check_result(exiv2.whiteBalance(self.exif_data))
        if not exiv2.testVersion(0, 27, 4):
            self.skipTest('easyaccess funcs introduced in v0.27.4')
        self.check_result(exiv2.apertureValue(self.exif_data), exiv2.URationalValue)
        self.check_result(exiv2.brightnessValue(self.exif_data))
        self.check_result(exiv2.dateTimeOriginal(self.exif_data), exiv2.AsciiValue)
        self.check_result(exiv2.exposureBiasValue(self.exif_data))
        self.check_result(exiv2.exposureIndex(self.exif_data))
        self.check_result(exiv2.flash(self.exif_data))
        self.check_result(exiv2.flashEnergy(self.exif_data))
        self.check_result(exiv2.lightSource(self.exif_data))
        self.check_result(exiv2.maxApertureValue(self.exif_data))
        self.check_result(exiv2.sensingMethod(self.exif_data))
        self.check_result(exiv2.shutterSpeedValue(self.exif_data))
        self.check_result(exiv2.subjectArea(self.exif_data))


if __name__ == '__main__':
    unittest.main()
