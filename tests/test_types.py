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

import locale
import logging
import os
import random
import sys
import unittest

import exiv2


class TestTypesModule(unittest.TestCase):
    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_DataBuf(self):
        data = bytes(random.choices(range(256), k=128))
        # constructors
        buf = exiv2.DataBuf()
        self.assertIsInstance(buf, exiv2.DataBuf)
        self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf(4)
        self.assertEqual(len(buf), 4)
        buf = exiv2.DataBuf(data)
        self.assertEqual(len(buf), len(data))
        self.check_result(buf.data(), memoryview, data)
        # other methods
        self.check_result(buf.size(), int, len(data))
        with buf.data() as view:
            self.assertIsInstance(view, memoryview)
            self.check_result(view[23], int, data[23])
            view[49] = 99
            self.check_result(view[49], int, 99)
        buf = exiv2.DataBuf(data)
        self.assertEqual(buf, data)
        self.assertEqual(data, buf)
        self.assertNotEqual(buf, b'fred')
        self.assertNotEqual(b'fred', buf)
        if exiv2.testVersion(0, 28, 0):
            self.assertEqual(buf.cmpBytes(0, data), 0)
            self.assertEqual(buf.cmpBytes(5, data[5:]), 0)
            self.assertNotEqual(buf.cmpBytes(0, b'fred'), 0)
            buf.resize(6)
            self.assertEqual(len(buf), 6)
            self.assertEqual(buf.empty(), False)
            buf.resize(0)
            self.assertEqual(buf.empty(), True)
        else:
            with self.assertWarns(DeprecationWarning):
                result = buf[23]
            with self.assertWarns(DeprecationWarning):
                self.check_result(buf.pData_, memoryview, data)
            with self.assertWarns(DeprecationWarning):
                self.check_result(buf.size_, int, len(data))
            buf.free()
            self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf(data)
        buf.reset()
        self.assertEqual(len(buf), 0)
        buf = exiv2.DataBuf()
        buf.alloc(6)
        self.assertEqual(len(buf), 6)

    def test_Rational(self):
        for type_ in (exiv2.Rational, exiv2.URational):
            # constructors
            value = type_()
            self.assertIsInstance(value, type_)
            value = type_(13, 7)
            self.assertIsInstance(value, type_)
            # other methods
            self.assertEqual(len(value), 2)
            self.assertEqual(repr(value), '(13, 7)')
            self.check_result(value[0], int, 13)
            self.check_result(value[1], int, 7)
            self.check_result(value.first, int, value[0])
            self.check_result(value.second, int, value[1])
            value[0] = 23
            self.check_result(value[0], int, 23)

    def test_TypeInfo(self):
        info = exiv2.TypeInfo
        self.check_result(info.typeId('Rational'),
                          exiv2.TypeId, exiv2.TypeId.unsignedRational)
        self.check_result(info.typeName(exiv2.TypeId.unsignedRational),
                          str, 'Rational')
        self.check_result(info.typeSize(exiv2.TypeId.unsignedRational), int, 8)

    @unittest.skipUnless(exiv2.versionInfo()['EXV_ENABLE_NLS'],
                         'no localisation available')
    def test_localisation(self):
        str_en = 'Failed to read input data'
        str_de = 'Die Eingabedaten konnten nicht gelesen werden.'
        # clear current locale
        locale.setlocale(locale.LC_ALL, 'C')
        self.check_result(exiv2.exvGettext(str_en), str, str_en)
        # set German locale
        if sys.platform == 'win32':
            name = 'German'
        else:
            name = 'de_DE.UTF-8'
        try:
            locale.setlocale(locale.LC_ALL, name)
        except locale.Error:
            self.skipTest("failed to set locale")
            return
        name = 'de_DE.UTF-8'
        os.environ['LC_ALL'] = name
        os.environ['LANG'] = name
        os.environ['LANGUAGE'] = name
        locale.setlocale(locale.LC_ALL, '')
        name, encoding = locale.getlocale()
        if name != 'de_DE' and sys.platform != 'win32':
            self.skipTest("locale environment ignored")
        # test localisation
        self.check_result(exiv2.exvGettext(str_en), str, str_de)
        if exiv2.testVersion(0, 28, 3) or not exiv2.testVersion(0, 28, 0):
            with self.assertLogs(level=logging.WARNING) as cm:
                comment = exiv2.CommentValue('charset=invalid Fred')
            self.assertEqual(cm.output, [
                'WARNING:exiv2:Ungültiger Zeichensatz: "invalid"'])
            with self.assertRaises(exiv2.Exiv2Error) as cm:
                key = exiv2.ExifKey('not.a.tag')
            self.assertEqual(cm.exception.message.replace('"', "'"),
                             "Ungültiger Schlüssel 'not.a.tag'")
        # clear locale
        name = 'en_US.UTF-8'
        os.environ['LC_ALL'] = name
        os.environ['LANG'] = name
        os.environ['LANGUAGE'] = name


if __name__ == '__main__':
    unittest.main()
