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
import os
import random
import sys
import unittest

import exiv2


class TestValueModule(unittest.TestCase):
    def test_DataValue(self):
        def check_data(value, data):
            copy = bytearray(len(data))
            self.assertEqual(value.copy(copy), len(data))
            self.assertEqual(copy, data)

        data = bytes(random.choices(range(256), k=128))
        # constructors
        value = exiv2.DataValue()
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.Value.create(exiv2.TypeId.unsignedByte)
        self.assertIsInstance(value, exiv2.DataValue)
        self.assertEqual(len(value), 0)
        value = exiv2.DataValue(data)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        value = exiv2.DataValue(data, exiv2.TypeId.undefined)
        self.assertIsInstance(value, exiv2.DataValue)
        check_data(value, data)
        # other methods
        self.assertEqual(str(value), ' '.join(str(x) for x in data))
        clone = value.clone()
        self.assertIsInstance(clone, exiv2.DataValue)
        check_data(clone, data)
        count = value.count()
        self.assertIsInstance(count, int)
        self.assertEqual(count, len(data))
        value = exiv2.DataValue()
        self.assertEqual(value.read(data), 0)
        check_data(value, data)
        value = exiv2.DataValue()
        self.assertEqual(value.read(' '.join(str(x) for x in data)), 0)
        check_data(value, data)
        size = value.size()
        self.assertIsInstance(size, int)
        self.assertEqual(size, len(data))
        result = value.toFloat(0)
        self.assertIsInstance(result, float)
        self.assertEqual(result, float(data[0]))
        if exiv2.testVersion(0, 28, 0):
            result = value.toInt64(0)
        else:
            result = value.toLong(0)
        self.assertIsInstance(result, int)
        self.assertEqual(result, int(data[0]))
        result = value.toRational(0)
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, (data[0], 1))
        result = value.toString(0)
        self.assertIsInstance(result, str)
        self.assertEqual(result, str(data[0]))
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        result = value.ok()
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        self.assertEqual(value.setDataArea(b'fred'), -1)
        result = value.sizeDataArea()
        self.assertIsInstance(result, int)
        self.assertEqual(result, 0)
        type_id = value.typeId()
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.undefined)

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
        # constructors
        value = exiv2.DateValue()
        self.assertIsInstance(value, exiv2.DateValue)
        value = exiv2.Value.create(exiv2.TypeId.date)
        self.assertIsInstance(value, exiv2.DateValue)
        value = exiv2.DateValue(today.year, today.month, today.day)
        self.assertIsInstance(value, exiv2.DateValue)
        # other methods
        with self.assertWarns(DeprecationWarning):
            date = value[0]
        self.assertEqual(len(value), 8)
        self.assertEqual(str(value), today.isoformat())
        clone = value.clone()
        self.assertIsInstance(clone, exiv2.DateValue)
        self.assertEqual(str(clone), today.isoformat())
        copy = bytearray(8)
        self.assertEqual(value.copy(copy), len(copy))
        self.assertEqual(copy, bytes(today.strftime('%Y%m%d'), 'ascii'))
        count = value.count()
        self.assertIsInstance(count, int)
        self.assertEqual(count, 8)
        date = value.getDate()
        self.assertIsInstance(date, exiv2.Date)
        value = exiv2.DateValue()
        self.assertEqual(
            value.read(bytes(today.strftime('%Y%m%d'), 'ascii')), 0)
        self.assertEqual(str(value), today.isoformat())
        value = exiv2.DateValue()
        self.assertEqual(value.read(today.isoformat()), 0)
        self.assertEqual(str(value), today.isoformat())
        value.setDate(date)
        self.assertEqual(str(value), today.isoformat())
        value.setDate(today.year, today.month, today.day)
        self.assertEqual(str(value), today.isoformat())
        size = value.size()
        self.assertIsInstance(size, int)
        self.assertEqual(size, 8)
        seconds = today.strftime('%s')
        result = value.toFloat(0)
        self.assertIsInstance(result, float)
        self.assertEqual(result, float(seconds))
        if exiv2.testVersion(0, 28, 0):
            result = value.toUint32(0)
            self.assertIsInstance(result, int)
            self.assertEqual(result, int(seconds))
            result = value.toInt64(0)
        else:
            result = value.toLong(0)
        self.assertIsInstance(result, int)
        self.assertEqual(result, int(seconds))
        result = value.toRational(0)
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, (int(seconds), 1))
        result = value.toString(0)
        self.assertIsInstance(result, str)
        self.assertEqual(result, today.isoformat())
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        result = value.ok()
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        self.assertEqual(value.setDataArea(b'fred'), -1)
        result = value.sizeDataArea()
        self.assertIsInstance(result, int)
        self.assertEqual(result, 0)
        type_id = value.typeId()
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.date)

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
        # constructors
        value = exiv2.TimeValue()
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.Value.create(exiv2.TypeId.time)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second, 1)
        self.assertIsInstance(value, exiv2.TimeValue)
        value = exiv2.TimeValue(now.hour, now.minute, now.second, 1, 30)
        self.assertIsInstance(value, exiv2.TimeValue)
        # other methods
        with self.assertWarns(DeprecationWarning):
            time = value[0]
        self.assertEqual(len(value), 11)
        self.assertEqual(str(value), now.isoformat())
        clone = value.clone()
        self.assertIsInstance(clone, exiv2.TimeValue)
        self.assertEqual(str(clone), now.isoformat())
        copy = bytearray(11)
        self.assertEqual(value.copy(copy), len(copy))
        self.assertEqual(copy, bytes(now.strftime('%H%M%S%z'), 'ascii'))
        count = value.count()
        self.assertIsInstance(count, int)
        self.assertEqual(count, 11)
        time = value.getTime()
        self.assertIsInstance(time, exiv2.Time)
        value = exiv2.TimeValue()
        self.assertEqual(
            value.read(bytes(now.strftime('%H%M%S%z'), 'ascii')), 0)
        self.assertEqual(str(value), now.isoformat())
        value = exiv2.TimeValue()
        self.assertEqual(value.read(now.isoformat()), 0)
        self.assertEqual(str(value), now.isoformat())
        value.setTime(time)
        self.assertEqual(str(value), now.isoformat())
        value.setTime(now.hour, now.minute)
        value.setTime(now.hour, now.minute, now.second)
        value.setTime(now.hour, now.minute, now.second, 1)
        value.setTime(now.hour, now.minute, now.second, 1, 30)
        self.assertEqual(str(value), now.isoformat())
        size = value.size()
        self.assertIsInstance(size, int)
        self.assertEqual(size, 11)
        seconds = (now.hour * 3600) + (now.minute * 60) + now.second
        seconds -= 3600 + (30 * 60)
        result = value.toFloat(0)
        self.assertIsInstance(result, float)
        self.assertEqual(result, float(seconds))
        if exiv2.testVersion(0, 28, 0):
            result = value.toUint32(0)
            self.assertIsInstance(result, int)
            self.assertEqual(result, int(seconds))
            result = value.toInt64(0)
        else:
            result = value.toLong(0)
        self.assertIsInstance(result, int)
        self.assertEqual(result, int(seconds))
        result = value.toRational(0)
        self.assertIsInstance(result, tuple)
        self.assertEqual(result, (int(seconds), 1))
        result = value.toString(0)
        self.assertIsInstance(result, str)
        self.assertEqual(result, now.isoformat())
        data_area = value.dataArea()
        self.assertIsInstance(data_area, exiv2.DataBuf)
        self.assertEqual(len(data_area), 0)
        result = value.ok()
        self.assertIsInstance(result, bool)
        self.assertEqual(result, True)
        self.assertEqual(value.setDataArea(b'fred'), -1)
        result = value.sizeDataArea()
        self.assertIsInstance(result, int)
        self.assertEqual(result, 0)
        type_id = value.typeId()
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.time)

    def do_string_tests(self, exiv2_type, exiv2_id):
        value = exiv2_type('fred')
        self.assertEqual(value.typeId(), exiv2_id)
        self.assertEqual(value.count(), 4)
        self.assertEqual(value.data(), b'fred')
        self.assertEqual(value.size(), 4)
        self.assertEqual(str(value), 'fred')
        self.assertEqual(len(value), 4)
        value = exiv2_type()
        value.read('The quick brown fox')
        self.assertEqual(str(value), 'The quick brown fox')

    def test_string_types(self):
        self.do_string_tests(exiv2.XmpTextValue, exiv2.TypeId.xmpText)
        self.do_string_tests(exiv2.StringValue, exiv2.TypeId.string)
        self.do_string_tests(exiv2.AsciiValue, exiv2.TypeId.asciiString)


if __name__ == '__main__':
    unittest.main()
