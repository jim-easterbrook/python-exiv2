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

import enum
import logging
import os
import unittest

import exiv2


class TestErrorModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # clear locale
        name = 'en_US.UTF-8'
        os.environ['LC_ALL'] = name
        os.environ['LANG'] = name
        os.environ['LANGUAGE'] = name

    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_LogMsg(self):
        self.assertIsInstance(exiv2.LogMsg.Level, enum.EnumMeta)
        self.check_result(
            exiv2.LogMsg.level(), exiv2.LogMsg.Level, exiv2.LogMsg.Level.warn)
        exiv2.LogMsg.setLevel(exiv2.LogMsg.Level.debug)
        self.check_result(
            exiv2.LogMsg.level(), exiv2.LogMsg.Level, exiv2.LogMsg.Level.debug)
        # get exiv2 to log a message
        with self.assertLogs(level=logging.WARNING):
            comment = exiv2.CommentValue('charset=invalid Fred')
        # test setting and clearing handler
        self.assertEqual(exiv2.LogMsg.handler(), exiv2.LogMsg.pythonHandler)
        exiv2.LogMsg.setHandler(None)
        self.assertEqual(exiv2.LogMsg.handler(), None)
        exiv2.LogMsg.setHandler(exiv2.LogMsg.defaultHandler)
        self.assertEqual(exiv2.LogMsg.handler(), exiv2.LogMsg.defaultHandler)
        exiv2.LogMsg.setHandler(exiv2.LogMsg.pythonHandler)
        self.assertEqual(exiv2.LogMsg.handler(), exiv2.LogMsg.pythonHandler)
        # get exiv2 to raise an exception
        with self.assertRaises(exiv2.Exiv2Error) as cm:
            image = exiv2.ImageFactory.open(bytes())
        self.assertEqual(cm.exception.code,
                         exiv2.ErrorCode.kerInputDataReadFailed)


if __name__ == '__main__':
    unittest.main()
