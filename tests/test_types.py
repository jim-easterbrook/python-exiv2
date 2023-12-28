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

import locale
import os
import random
import sys
import unittest

import exiv2


class TestTypesModule(unittest.TestCase):
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
        self.assertEqual(buf.data(), data)
        # other methods
        result = buf.size()
        self.assertIsInstance(result, int)
        self.assertEqual(result, len(data))
        with buf.data() as view:
            self.assertIsInstance(view, memoryview)
            result = view[23]
            self.assertIsInstance(result, int)
            self.assertEqual(result, data[23])
            view[49] = 99
            self.assertEqual(view[49], 99)
        buf = exiv2.DataBuf(data)
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
            result = value[0]
            self.assertIsInstance(result, int)
            self.assertEqual(result, 13)
            result = value[1]
            self.assertIsInstance(result, int)
            self.assertEqual(result, 7)
            result = value.first
            self.assertIsInstance(result, int)
            self.assertEqual(result, value[0])
            result = value.second
            self.assertIsInstance(result, int)
            self.assertEqual(result, value[1])
            value[0] = 23
            self.assertEqual(value[0], 23)

    def test_TypeInfo(self):
        info = exiv2.TypeInfo
        result = info.typeId('Rational')
        self.assertIsInstance(result, int)
        self.assertEqual(result, exiv2.TypeId.unsignedRational)
        result = info.typeName(exiv2.TypeId.unsignedRational)
        self.assertIsInstance(result, str)
        self.assertEqual(result, 'Rational')
        result = info.typeSize(exiv2.TypeId.unsignedRational)
        self.assertIsInstance(result, int)
        self.assertEqual(result, 8)

    @unittest.skipUnless(exiv2.versionInfo()['EXV_ENABLE_NLS'],
                         'no localisation available')
    def test_localisation(self):
        str_en = 'Failed to read input data'
        str_de = 'Die Eingabedaten konnten nicht gelesen werden.'
        # clear current locale
        locale.setlocale(locale.LC_MESSAGES, 'C')
        self.assertEqual(exiv2.exvGettext(str_en), str_en)
        # set German locale
        for name in ('de_DE.UTF-8', 'de_DE.utf8', 'de_DE', 'German'):
            try:
                locale.setlocale(locale.LC_MESSAGES, name)
                break
            except locale.Error:
                continue
        else:
            self.skipTest("failed to set locale")
            return
        print('setting locale', name)
        os.environ['LANGUAGE'] = name
        locale.setlocale(locale.LC_MESSAGES, '')
        # test localisation
        self.assertEqual(exiv2.exvGettext(str_en), str_de)


if __name__ == '__main__':
    unittest.main()
