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

import logging
import unittest

import exiv2


class TestErrorModule(unittest.TestCase):
    def test_LogMsg(self):
        self.assertEqual(exiv2.LogMsg.level(), exiv2.LogMsg.warn)
        exiv2.LogMsg.setLevel(exiv2.LogMsg.debug)
        self.assertEqual(exiv2.LogMsg.level(), exiv2.LogMsg.debug)
        # get exiv2 to log a message
        with self.assertLogs(level=logging.WARNING):
            comment = exiv2.CommentValue('charset=invalid Fred')
        # get exiv2 to raise an exception
        with self.assertRaises(exiv2.Exiv2Error):
            image = exiv2.ImageFactory.open('non-existing.jpg')


if __name__ == '__main__':
    unittest.main()
