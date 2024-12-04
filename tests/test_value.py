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

import datetime
from fractions import Fraction
import io
import os
import random
import struct
import sys
import unittest

import exiv2


class TestValueModule(unittest.TestCase):
    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

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
        if sequence:
            self.check_result(value.count(), int, len(sequence))
            if not isinstance(sequence, dict):
                with self.assertRaises(IndexError):
                    result = value[value.count()]
        else:
            self.check_result(value.count(), int, len(data))
        self.check_result(value.ok(), bool, True)
        with self.assertWarns(DeprecationWarning):
            result = exiv2.Value.create(int(type_id))
        result = exiv2.Value.create(type_id)
        self.assertEqual(result.read(string), 0)
        self.assertEqual(str(result), string)
        result = exiv2.Value.create(type_id)
        self.assertEqual(result.read(data, exiv2.ByteOrder.littleEndian), 0)
        self.assertEqual(str(result), string)
        self.check_result(value.size(), int, len(data))
        # Exiv2::CommentValue::typeId returns undefined
        if type_id == exiv2.TypeId.comment:
            self.check_result(
                value.typeId(), exiv2.TypeId, exiv2.TypeId.undefined)
        else:
            self.check_result(value.typeId(), exiv2.TypeId, type_id)
        buf = io.StringIO()
        buf = value.write(buf)
        self.assertEqual(buf.getvalue(), string)

    def do_conversion_tests(self, value, text, number):
        result = value.toFloat(0)
        if value.ok():
            self.assertEqual(value.ok(), True)
            self.assertIsInstance(result, float)
            self.assertAlmostEqual(result, float(number), places=5)
            self.assertEqual(value.toFloat(0), value.toFloat())
        if exiv2.testVersion(0, 28, 0):
            result = value.toUint32(0)
            if value.ok():
                self.assertEqual(value.ok(), True)
                self.check_result(result, int, int(number))
                self.assertEqual(result, value.toUint32())
            result = value.toInt64(0)
            if value.ok():
                self.assertEqual(value.ok(), True)
                self.check_result(result, int, int(number))
                self.assertEqual(result, value.toInt64())
        else:
            result = value.toLong(0)
            if value.ok():
                self.assertEqual(value.ok(), True)
                self.check_result(result, int, int(number))
                self.assertEqual(result, value.toLong())
        result = value.toRational(0)
        if value.ok():
            self.assertEqual(value.ok(), True)
            self.assertIsInstance(result, tuple)
            self.assertAlmostEqual(
                float(Fraction(*result)), float(number), places=5)
            self.assertEqual(value.toRational(0), value.toRational())
        result = value.toString(0)
        if value.ok():
            self.assertEqual(value.ok(), True)
            self.check_result(result, str, text)

    def do_dataarea_tests(self, value, has_dataarea=False):
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        if has_dataarea:
            self.assertEqual(value.setDataArea(b'fred'), 0)
            self.check_result(value.sizeDataArea(), int, 4)
        else:
            self.assertEqual(value.setDataArea(b'fred'), -1)

    def do_common_string_tests(self, value, data):
        with self.assertWarns(DeprecationWarning):
            char = value[0]
        with value.data() as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, data)

    def do_common_xmp_tests(self, value):
        with self.assertWarns(DeprecationWarning):
            type_ = exiv2.XmpArrayType.xaSeq
        for type_ in (exiv2.XmpValue.XmpArrayType.xaSeq,
                      exiv2.XmpValue.XmpArrayType.xaBag,
                      exiv2.XmpValue.XmpArrayType.xaAlt,
                      exiv2.XmpValue.XmpArrayType.xaNone):
            with self.assertWarns(DeprecationWarning):
                value.setXmpArrayType(int(type_))
            value.setXmpArrayType(type_)
            self.check_result(
                value.xmpArrayType(), exiv2.XmpValue.XmpArrayType, type_)
        with self.assertWarns(DeprecationWarning):
            type_ = exiv2.XmpStruct.xsStruct
        for type_ in (exiv2.XmpValue.XmpStruct.xsStruct,
                      exiv2.XmpValue.XmpStruct.xsNone):
            value.setXmpStruct(type_)
            self.check_result(
                value.xmpStruct(), exiv2.XmpValue.XmpStruct, type_)
        value.setXmpStruct()
        self.check_result(value.xmpStruct(), exiv2.XmpValue.XmpStruct,
                          exiv2.XmpValue.XmpStruct.xsStruct)

    def test_AsciiValue(self):
        text = 'The quick brown fox jumps over the lazy dog. àéīöûç'
        data = bytes(text, 'utf-8') + b'\x00'
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
        if exiv2.testVersion(0, 27, 3):
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
        with self.assertWarns(DeprecationWarning):
            result = exiv2.CharsetId.ascii
        self.check_result(value.charsetId(), exiv2.CommentValue.CharsetId,
                          exiv2.CommentValue.CharsetId.unicode)
        self.check_result(value.comment(), str, raw_text)
        self.check_result(value.detectCharset(raw_text), str, 'UCS-2LE')
        self.check_result(
            value.byteOrder_, exiv2.ByteOrder, exiv2.ByteOrder.littleEndian)
        self.do_common_tests(value, exiv2.TypeId.comment, text, data)
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
        self.check_result(value['en-GB'], str, text_dict['en-GB'])
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
        self.check_result(value.keys(), list, list(text_dict.keys()))
        self.check_result(value.values(), list, list(text_dict.values()))
        self.check_result(value.items(), list, list(text_dict.items()))
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
        value = exiv2.XmpArrayValue()
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.xmpBag)
        self.assertEqual(len(value), 0)
        value = exiv2.XmpArrayValue(exiv2.TypeId.xmpSeq)
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.xmpSeq)
        value = exiv2.XmpArrayValue(text)
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.xmpBag)
        value = exiv2.XmpArrayValue(text, exiv2.TypeId.xmpSeq)
        self.assertIsInstance(value, exiv2.XmpArrayValue)
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.xmpSeq)
        # other methods
        self.assertEqual(len(value), 2)
        self.check_result(value[0], str, text[0])
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
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.undefined)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.check_result(
            value.typeId(), exiv2.TypeId, exiv2.TypeId.unsignedByte)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(data)
        self.assertIsInstance(value, exiv2.DataValue)
        self.check_result(value.typeId(), exiv2.TypeId, exiv2.TypeId.undefined)
        check_data(value, data)
        value = exiv2.DataValue(
            data, exiv2.ByteOrder.invalidByteOrder, exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.check_result(
            value.typeId(), exiv2.TypeId, exiv2.TypeId.unsignedByte)
        check_data(value, data)
        # other methods
        self.do_common_tests(value, exiv2.TypeId.unsignedByte, string, data)
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
        self.assertEqual(dict(value), {
            'year': today.year, 'month': today.month, 'day': today.day})

    def do_test_DateValue(self, py_date):
        data = bytes(py_date.strftime('%Y%m%d'), 'ascii')
        exiv_date = exiv2.Date()
        exiv_date.year = py_date.year
        exiv_date.month = py_date.month
        exiv_date.day = py_date.day
        date_dict = {
            'year': py_date.year, 'month': py_date.month, 'day': py_date.day}
        # constructors
        value = exiv2.DateValue()
        self.assertIsInstance(value, exiv2.DateValue)
        value = exiv2.DateValue(exiv_date)
        self.assertIsInstance(value, exiv2.DateValue)
        self.assertEqual(str(value), py_date.isoformat())
        value = exiv2.DateValue(py_date.year, py_date.month, py_date.day)
        self.assertIsInstance(value, exiv2.DateValue)
        self.assertEqual(str(value), py_date.isoformat())
        # other methods
        with self.assertWarns(DeprecationWarning):
            result = value[0]
        self.check_result(dict(value.getDate()), dict, date_dict)
        value.setDate(exiv_date)
        self.assertEqual(str(value), py_date.isoformat())
        value.setDate(py_date.year, py_date.month, py_date.day)
        self.assertEqual(str(value), py_date.isoformat())
        seconds = int(datetime.datetime.combine(
            py_date, datetime.time(), datetime.timezone.utc).timestamp())
        self.do_common_tests(value, exiv2.TypeId.date, py_date.isoformat(), data)
        self.do_conversion_tests(value, py_date.isoformat(), seconds)
        self.do_dataarea_tests(value)

    def test_DateValue(self):
        date = datetime.date(2024, 7, 4)
        with self.subTest(date=date):
            self.do_test_DateValue(date)
        if exiv2.testVersion(0, 28, 4):
            date = datetime.date(2039, 1, 1)
            with self.subTest(date=date):
                self.do_test_DateValue(date)

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
        self.assertEqual(dict(value), {
            'hour': now.hour, 'minute': now.minute, 'second': now.second,
            'tzHour': 1, 'tzMinute': 30})

    def do_test_TimeValue(self, py_time):
        exiv_time = exiv2.Time()
        exiv_time.hour = py_time.hour
        exiv_time.minute = py_time.minute
        exiv_time.second = py_time.second
        exiv_time.tzHour = 1
        exiv_time.tzMinute = 30
        time_dict = {'hour': py_time.hour, 'minute': py_time.minute,
                     'second': py_time.second, 'tzHour': 1, 'tzMinute': 30}
        data = bytes(py_time.strftime('%H%M%S%z'), 'ascii')
        # constructors
        value = exiv2.TimeValue()
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(exiv_time)
        self.assertIsInstance(value, exiv2.TimeValue)
        self.assertEqual(str(value), py_time.isoformat())
        value = exiv2.TimeValue(py_time.hour, py_time.minute, py_time.second)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(
            py_time.hour, py_time.minute, py_time.second, 1)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(
            py_time.hour, py_time.minute, py_time.second, 1, 30)
        self.assertIsInstance(value, exiv2.TimeValue)
        self.assertEqual(str(value), py_time.isoformat())
        # other methods
        with self.assertWarns(DeprecationWarning):
            result = value[0]
        self.check_result(dict(value.getTime()), dict, time_dict)
        value.setTime(exiv_time)
        self.assertEqual(str(value), py_time.isoformat())
        value.setTime(py_time.hour, py_time.minute)
        value.setTime(py_time.hour, py_time.minute, py_time.second)
        value.setTime(py_time.hour, py_time.minute, py_time.second, 1)
        value.setTime(py_time.hour, py_time.minute, py_time.second, 1, 30)
        self.assertEqual(str(value), py_time.isoformat())
        seconds = (py_time.hour * 3600) + (py_time.minute * 60) + py_time.second
        seconds -= py_time.tzinfo.utcoffset(
            datetime.datetime.now()).total_seconds()
        if seconds < 0:
            seconds += 24 * 3600
        value = exiv2.TimeValue()
        value.read(py_time.isoformat())
        self.do_common_tests(value, exiv2.TypeId.time, py_time.isoformat(), data)
        self.do_conversion_tests(value, py_time.isoformat(), seconds)
        self.do_dataarea_tests(value)

    def test_TimeValue(self):
        py_tz = datetime.timezone(datetime.timedelta(hours=1, minutes=30))
        py_time = datetime.time(12, 34, 56, tzinfo=py_tz)
        with self.subTest(time=py_time):
            self.do_test_TimeValue(py_time)
        py_time = py_time.replace(hour=0)
        with self.subTest(py_time=py_time):
            self.do_test_TimeValue(py_time)

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
        self.check_result(value[0], int, sequence[0])
        self.check_result(value[2], int, sequence[2])
        self.check_result(value[-1], int, sequence[-1])
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
        # data range
        value = exiv2.UShortValue((1<<16) - 1)
        with self.assertRaises(TypeError):
            value = exiv2.UShortValue(1<<16)
        value = exiv2.UShortValue(0)
        with self.assertRaises(TypeError):
            value = exiv2.UShortValue(-1)

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
        self.check_result(value[0], tuple, sequence[0])
        self.check_result(value[1], tuple, sequence[1])
        self.check_result(value[-1], tuple, sequence[-1])
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
        # data range
        value = exiv2.URationalValue([((1<<32) - 1, 1)])
        with self.assertRaises(TypeError):
            value = exiv2.URationalValue([(1<<32, 1)])
        value = exiv2.URationalValue([(0, 1)])
        with self.assertRaises(TypeError):
            value = exiv2.URationalValue([(-1, 1)])


if __name__ == '__main__':
    unittest.main()
