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

import unittest

import exiv2


class TestVersionModule(unittest.TestCase):
    def test_module(self):
        # earliest usable libexiv2 version
        result = exiv2.testVersion(0, 27, 0)
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        version = exiv2.version()
        self.assertIsInstance(version, str)
        self.assertGreaterEqual(version, '0.27.0')
        version_tuple = tuple(int(x) for x in version.split('.')[:3])
        version = exiv2.versionNumber()
        self.assertIsInstance(version, int)
        self.assertEqual(version, (version_tuple[0] << 16)
                         + (version_tuple[1] << 8) + version_tuple[2])
        version = exiv2.versionNumberHexString()
        self.assertIsInstance(version, str)
        self.assertEqual(
            version, '{:02x}{:02x}{:02x}'.format(*version_tuple))
        version = exiv2.versionString()
        self.assertIsInstance(version, str)
        self.assertGreaterEqual(
            version, '.'.join(str(x) for x in version_tuple))


if __name__ == '__main__':
    unittest.main()
