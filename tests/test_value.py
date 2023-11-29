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

import datetime
from fractions import Fraction
import os
import random
import struct
import sys
import unittest

import exiv2


class TestValueModule(unittest.TestCase):
    def do_common_tests(self, value, type_id, string, data, sequence=None):
        if type_id != exiv2.TypeId.undefined:
            self.assertIsInstance(exiv2.Value.create(type_id), type(value))
        self.assertEqual(len(value), value.count())
        self.assertEqual(str(value), string)
        result = value.clone()
        self.assertIsInstance(result, type(value))
        self.assertEqual(str(result), str(value))
        result = bytearray(len(data))
        self.assertEqual(
            value.copy(result, exiv2.ByteOrder.littleEndian), len(result))
        self.assertEqual(result, data)
        result = value.count()
        self.assertIsInstance(result, int)
        if sequence:
            self.assertEqual(result, len(sequence))
        else:
            self.assertEqual(result, len(data))
        result = value.ok()
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        if isinstance(value, exiv2.CommentValue):
            result = value.clone()
        else:
            result = exiv2.Value.create(type_id)
        self.assertEqual(result.read(string), 0)
        self.assertEqual(str(result), string)
        if isinstance(value, exiv2.CommentValue):
            result = value.clone()
        else:
            result = exiv2.Value.create(type_id)
        self.assertEqual(result.read(data, exiv2.ByteOrder.littleEndian), 0)
        self.assertEqual(str(result), string)
        result = value.size()
        self.assertIsInstance(result, int)
        self.assertEqual(result, len(data))
        result = value.typeId()
        self.assertIsInstance(result, int)
        self.assertEqual(result, type_id)

    def do_conversion_tests(self, value, text, number):
        result = value.toFloat(0)
        self.assertEqual(value.ok(), True)
        self.assertIsInstance(result, float)
        self.assertAlmostEqual(result, float(number), places=5)
        if exiv2.testVersion(0, 28, 0):
            result = value.toUint32(0)
            self.assertEqual(value.ok(), True)
            self.assertIsInstance(result, int)
            self.assertEqual(result, int(number))
            result = value.toInt64(0)
        else:
            result = value.toLong(0)
        self.assertEqual(value.ok(), True)
        self.assertIsInstance(result, int)
        self.assertEqual(result, int(number))
        result = value.toRational(0)
        self.assertEqual(value.ok(), True)
        self.assertIsInstance(result, tuple)
        self.assertAlmostEqual(
            float(Fraction(*result)), float(number), places=5)
        result = value.toString(0)
        self.assertEqual(value.ok(), True)
        self.assertIsInstance(result, str)
        self.assertEqual(result, text)

    def do_dataarea_tests(self, value, has_dataarea=False):
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        if has_dataarea:
            self.assertEqual(value.setDataArea(b'fred'), 0)
            result = value.sizeDataArea()
            self.assertIsInstance(result, int)
            self.assertEqual(result, 4)
        else:
            self.assertEqual(value.setDataArea(b'fred'), -1)

    def do_common_string_tests(self, value, data):
        with self.assertWarns(DeprecationWarning):
            char = value[0]
        with value.data() as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, data)

    def do_common_xmp_tests(self, value):
        for type_ in (exiv2.XmpArrayType.xaSeq, exiv2.XmpArrayType.xaBag,
                      exiv2.XmpArrayType.xaAlt, exiv2.XmpArrayType.xaNone):
            value.setXmpArrayType(type_)
            result = value.xmpArrayType()
            self.assertIsInstance(result, int)
            self.assertEqual(result, type_)
        for type_ in (exiv2.XmpStruct.xsStruct, exiv2.XmpStruct.xsNone):
            value.setXmpStruct(type_)
            result = value.xmpStruct()
            self.assertIsInstance(result, int)
            self.assertEqual(result, type_)

    def test_AsciiValue(self):
        text = 'The quick brown fox jumps over the lazy dog. àéīöûç'
        data = bytes(text, 'utf-8')
        # constructors
        value = exiv2.AsciiValue()
        self.assertIsInstance(value, exiv2.AsciiValue)
        self.assertEqual(len(value), 0)
        value = exiv2.AsciiValue(text)
        self.assertIsInstance(value, exiv2.AsciiValue)
        # other methods
        self.do_common_tests(value, exiv2.TypeId.asciiString, text, data)
        self.do_common_string_tests(value, data)
        self.do_conversion_tests(value, text, data[0])
        self.do_dataarea_tests(value)

    def test_CommentValue(self):
        raw_text = 'The quick brown fox jumps over the lazy dog. àéīöûç'
        data = b'UNICODE\x00' + bytes(raw_text, 'utf-16-le')
        if exiv2.testVersion(0, 27, 4):
            text = 'charset=Unicode ' + raw_text
        else:
            text = 'charset="Unicode" ' + raw_text
        # constructors
        value = exiv2.CommentValue()
        self.assertIsInstance(value, exiv2.CommentValue)
        self.assertEqual(len(value), 0)
        value = exiv2.CommentValue(text)
        self.assertIsInstance(value, exiv2.CommentValue)
        # other methods
        result = value.charsetId()
        self.assertIsInstance(result, int)
        self.assertEqual(result, exiv2.CharsetId.unicode)
        result = value.comment()
        self.assertIsInstance(result, str)
        self.assertEqual(result, raw_text)
        result = value.byteOrder_
        self.assertIsInstance(result, int)
        self.assertEqual(result, exiv2.ByteOrder.littleEndian)
        self.do_common_tests(value, exiv2.TypeId.undefined, text, data)
        self.do_common_string_tests(value, data)
        self.do_conversion_tests(value, text, data[0])
        self.do_dataarea_tests(value)

    def test_StringValue(self):
        text = 'The quick brown fox jumps over the lazy dog. àéīöûç'
        data = bytes(text, 'utf-8')
        # constructors
        value = exiv2.StringValue()
        self.assertIsInstance(value, exiv2.StringValue)
        self.assertEqual(len(value), 0)
        value = exiv2.StringValue(text)
        self.assertIsInstance(value, exiv2.StringValue)
        # other methods
        self.do_common_tests(value, exiv2.TypeId.string, text, data)
        self.do_common_string_tests(value, data)
        self.do_conversion_tests(value, text, data[0])
        self.do_dataarea_tests(value)

    def test_LangAltValue(self):
        text_dict = {
            'x-default': 'The quick brown fox jumps over the lazy dog.',
            'en-GB': 'The quick brown fox jumps over the lazy dog.',
            'de-DE': 'Der schnelle Braunfuchs springt über den faulen Hund.',
            }
        text = ', '.join('lang="{}" {}'.format(*x) for x in text_dict.items())
        data = bytes(text, 'utf-8')
        # constructors
        value = exiv2.LangAltValue()
        self.assertIsInstance(value, exiv2.LangAltValue)
        self.assertEqual(len(value), 0)
        value = exiv2.LangAltValue(text_dict['x-default'])
        self.assertIsInstance(value, exiv2.LangAltValue)
        self.assertEqual(len(value), 1)
        value = exiv2.LangAltValue(text_dict)
        self.assertIsInstance(value, exiv2.LangAltValue)
        self.assertEqual(len(value), 3)
        # other methods
        self.assertEqual(dict(value), text_dict)
        self.assertEqual('de-DE' in value, True)
        result = value['en-GB']
        self.assertIsInstance(result, str)
        self.assertEqual(result, text_dict['en-GB'])
        self.assertEqual('nl-NL' in value, False)
        nl_string = 'De snelle bruine vos springt over de luie hond heen.'
        value['nl-NL'] = nl_string
        self.assertEqual('nl-NL' in value, True)
        del value['nl-NL']
        self.assertEqual('nl-NL' in value, False)
        self.assertEqual(value.read(nl_string), 0)
        self.assertEqual(value['x-default'], nl_string)
        self.assertEqual(
            value.read('lang="{}" {}'.format('nl-NL', nl_string)), 0)
        self.assertEqual('nl-NL' in value, True)
        self.assertEqual(value['nl-NL'], nl_string)
        value = exiv2.LangAltValue(text_dict)
        result = value.keys()
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, tuple(text_dict.keys()))
        result = value.values()
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, tuple(text_dict.values()))
        result = value.items()
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, tuple(text_dict.items()))
        self.do_common_tests(
            value, exiv2.TypeId.langAlt, text, data, sequence=text_dict)
        # no conversion tests as value can't be numeric
        self.do_dataarea_tests(value)
        self.do_common_xmp_tests(value)

    def test_XmpArrayValue(self):
        text = ('The quick brown fox jumps over the lazy dog. àéīöûç',
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit')
        string = ', '.join(text)
        data = bytes(string, 'utf-8')
        # constructors
        value = exiv2.XmpArrayValue(exiv2.TypeId.xmpSeq)
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        self.assertEqual(len(value), 0)
        value = exiv2.XmpArrayValue(text)
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        # other methods
        self.assertEqual(len(value), 2)
        result = value[0]
        self.assertIsInstance(result, str)
        self.assertEqual(result, text[0])
        value.append('fred')
        self.assertIsInstance(value[2], str)
        value = exiv2.XmpArrayValue(text)
        # read() appends to value
        self.assertEqual(value.read(b'dave'), 0)
        self.assertEqual(len(value), 3)
        self.assertEqual(value[2], 'dave')
        value = exiv2.XmpArrayValue(text)
        self.assertEqual(value.read('pete'), 0)
        self.assertEqual(value[2], 'pete')
        self.assertEqual(len(value), 3)
        value = exiv2.XmpArrayValue(text)
        self.do_common_tests(
            value, exiv2.TypeId.xmpBag, string, data, sequence=text)
        value = exiv2.XmpArrayValue(('123.45', 'fred'))
        self.do_conversion_tests(value, value[0], float(value[0]))
        self.do_dataarea_tests(value)
        self.do_common_xmp_tests(value)

    def test_XmpTextValue(self):
        text = 'The quick brown fox jumps over the lazy dog. àéīöûç'
        data = bytes(text, 'utf-8')
        # constructors
        value = exiv2.XmpTextValue()
        self.assertIsInstance(value, exiv2.XmpTextValue)
        self.assertEqual(len(value), 0)
        value = exiv2.XmpTextValue(text)
        self.assertIsInstance(value, exiv2.XmpTextValue)
        # other methods
        self.do_common_tests(value, exiv2.TypeId.xmpText, text, data)
        self.do_common_string_tests(value, data)
        text = '123.45'
        value = exiv2.XmpArrayValue(text)
        self.do_conversion_tests(value, text[0], int(text[0]))
        self.do_dataarea_tests(value)
        self.do_common_xmp_tests(value)

    def test_DataValue(self):
        def check_data(value, data):
            copy = bytearray(len(data))
            self.assertEqual(value.copy(copy), len(data))
            self.assertEqual(copy, data)

        data = bytes(random.choices(range(256), k=128))
        string = ' '.join(str(x) for x in data)
        # constructors
        value = exiv2.DataValue()
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(data)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        value = exiv2.DataValue(data, exiv2.TypeId.undefined)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        # other methods
        self.do_common_tests(value, exiv2.TypeId.undefined, string, data)
        self.do_conversion_tests(value, str(data[0]), data[0])
        self.do_dataarea_tests(value)

    def test_Date(self):
        today = datetime.date.today()
        value = exiv2.Date()
        value.year = today.year
        value.month = today.month
        value.day = today.day
        self.assertIsInstance(value, exiv2.Date)
        self.assertIsInstance(value.year, int)
        self.assertEqual(value.year, today.year)
        self.assertIsInstance(value.month, int)
        self.assertEqual(value.month, today.month)
        self.assertIsInstance(value.day, int)
        self.assertEqual(value.day, today.day)
        self.assertEqual(list(value), [
            ('year', today.year), ('month', today.month), ('day', today.day)])
        self.assertEqual(dict(value), {
            'year': today.year, 'month': today.month, 'day': today.day})

    def test_DateValue(self):
        today = datetime.date.today()
        data = bytes(today.strftime('%Y%m%d'), 'ascii')
        # constructors
        value = exiv2.DateValue()
        self.assertIsInstance(value, exiv2.DateValue)
        value = exiv2.DateValue(today.year, today.month, today.day)
        self.assertIsInstance(value, exiv2.DateValue)
        # other methods
        with self.assertWarns(DeprecationWarning):
            result = value[0]
        date = value.getDate()
        self.assertIsInstance(date, exiv2.Date)
        value.setDate(date)
        self.assertEqual(str(value), today.isoformat())
        value.setDate(today.year, today.month, today.day)
        self.assertEqual(str(value), today.isoformat())
        seconds = int(today.strftime('%s'))
        self.do_common_tests(value, exiv2.TypeId.date, today.isoformat(), data)
        self.do_conversion_tests(value, today.isoformat(), seconds)
        self.do_dataarea_tests(value)

    def test_Time(self):
        now = datetime.datetime.now().time()
        value = exiv2.Time()
        value.hour = now.hour
        value.minute = now.minute
        value.second = now.second
        value.tzHour = 1
        value.tzMinute = 30
        self.assertIsInstance(value, exiv2.Time)
        self.assertIsInstance(value.hour, int)
        self.assertEqual(value.hour, now.hour)
        self.assertIsInstance(value.minute, int)
        self.assertEqual(value.minute, now.minute)
        self.assertIsInstance(value.second, int)
        self.assertEqual(value.second, now.second)
        self.assertIsInstance(value.tzHour, int)
        self.assertEqual(value.tzHour, 1)
        self.assertIsInstance(value.tzMinute, int)
        self.assertEqual(value.tzMinute, 30)
        self.assertEqual(list(value), [
            ('hour', now.hour), ('minute', now.minute), ('second', now.second),
            ('tzHour', 1), ('tzMinute', 30)])
        self.assertEqual(dict(value), {
            'hour': now.hour, 'minute': now.minute, 'second': now.second,
            'tzHour': 1, 'tzMinute': 30})

    def test_TimeValue(self):
        now = datetime.datetime.now().time()
        now = now.replace(
            tzinfo=datetime.timezone(datetime.timedelta(hours=1, minutes=30)),
            microsecond=0)
        data = bytes(now.strftime('%H%M%S%z'), 'ascii')
        # constructors
        value = exiv2.TimeValue()
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second, 1)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second, 1, 30)
        self.assertIsInstance(value, exiv2.TimeValue)
        # other methods
        with self.assertWarns(DeprecationWarning):
            result = value[0]
        time = value.getTime()
        self.assertIsInstance(time, exiv2.Time)
        value.setTime(time)
        self.assertEqual(str(value), now.isoformat())
        value.setTime(now.hour, now.minute)
        value.setTime(now.hour, now.minute, now.second)
        value.setTime(now.hour, now.minute, now.second, 1)
        value.setTime(now.hour, now.minute, now.second, 1, 30)
        self.assertEqual(str(value), now.isoformat())
        seconds = (now.hour * 3600) + (now.minute * 60) + now.second
        seconds -= 3600 + (30 * 60)
        value = exiv2.TimeValue()
        value.read(now.isoformat())
        self.do_common_tests(value, exiv2.TypeId.time, now.isoformat(), data)
        self.do_conversion_tests(value, now.isoformat(), seconds)
        self.do_dataarea_tests(value)

    def test_UShortValue(self):
        sequence = (4, 6, 9, 5)
        text = ' '.join(str(x) for x in sequence)
        data = struct.pack('<4H', *sequence)
        # constructors
        value = exiv2.UShortValue()
        self.assertIsInstance(value, exiv2.UShortValue)
        self.assertEqual(len(value), 0)
        value = exiv2.UShortValue(sequence)
        self.assertIsInstance(value, exiv2.UShortValue)
        self.assertEqual(tuple(value), sequence)
        # data access
        result = value[2]
        self.assertIsInstance(result, int)
        self.assertEqual(result, sequence[2])
        self.assertEqual(value[-1], sequence[-1])
        value[2] = 56
        self.assertEqual(value[2], 56)
        del value[2]
        self.assertEqual(len(value), len(sequence) - 1)
        value.append(3)
        self.assertEqual(value[3], 3)
        # other methods
        value = exiv2.UShortValue(sequence)
        self.do_common_tests(
            value, exiv2.TypeId.unsignedShort, text, data, sequence=sequence)
        self.do_conversion_tests(value, str(sequence[0]), sequence[0])
        self.do_dataarea_tests(value, has_dataarea=True)

    def test_URationalValue(self):
        sequence = ((4, 3), (7, 13), (23, 3))
        text = ' '.join('{}/{}'.format(x, y) for x, y in sequence)
        data = struct.pack('<6I', *[x for y in sequence for x in y])
        # constructors
        value = exiv2.URationalValue()
        self.assertIsInstance(value, exiv2.URationalValue)
        self.assertEqual(len(value), 0)
        value = exiv2.URationalValue(sequence)
        self.assertIsInstance(value, exiv2.URationalValue)
        self.assertEqual(tuple(value), sequence)
        # data access
        result = value[2]
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, sequence[2])
        self.assertEqual(value[-1], sequence[-1])
        value[2] = (56, 13)
        self.assertEqual(value[2], (56, 13))
        del value[2]
        self.assertEqual(len(value), len(sequence) - 1)
        value.append((3, 1))
        self.assertEqual(value[2], (3, 1))
        # other methods
        value = exiv2.URationalValue(sequence)
        self.do_common_tests(
            value, exiv2.TypeId.unsignedRational, text, data, sequence=sequence)
        self.do_conversion_tests(
            value, '{}/{}'.format(*sequence[0]), Fraction(*sequence[0]))
        self.do_dataarea_tests(value, has_dataarea=True)


if __name__ == '__main__':
    unittest.main()
