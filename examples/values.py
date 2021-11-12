#!/usr/bin/env python

# python-exiv2 - Python interface to libexiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2021  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Accessing some Exiv2::Value types directly, without going via string
# representations. For most purposes, using string representations of
# values is good enough, but for maximum speed and precision you can use
# more appropriate Python types.

import datetime
from fractions import Fraction
import sys

import exiv2
import tzlocal

def main():
    print('==== DateValue & TimeValue ====')
    # These are only used in Iptc - Exif & Xmp use string representations
    tz = tzlocal.get_localzone()
    py_datetime = datetime.datetime.now(tz)
    print("Python datetime:", py_datetime)
    # Python -> Exiv2
    date = exiv2.DateValue()
    date.setDate(py_datetime.year, py_datetime.month, py_datetime.day)
    print("Exiv2 date:", date)
    time = exiv2.TimeValue()
    offset = int(tz.utcoffset(py_datetime).total_seconds()) // 60
    time.setTime(py_datetime.hour, py_datetime.minute, py_datetime.second,
                 offset // 60, offset % 60)
    print("Exiv2 time:", time)
    # Exiv2 -> Python
    # date[0] and time[0] return tuples of ints
    tz = datetime.timezone(
        datetime.timedelta(hours=time[0][3], minutes=time[0][4]))
    py_datetime = datetime.datetime(*date[0], *time[0][:3], tzinfo=tz)
    print("Python datetime:", py_datetime)

    print('==== ShortValue ====')
    # This stores 1 or more 16-bit ints.
    py_shorts = [34, 56, 78]
    print("Python short:", py_shorts)
    # Python -> Exiv2
    shorts = exiv2.ShortValue()
    # append values to initialise
    for x in py_shorts:
        shorts += x
    print("Exiv2 short:", shorts)
    # modify a value by index
    shorts[1] = 12
    print("Exiv2 short:", shorts)
    # append a value
    shorts += 90
    print("Exiv2 short:", shorts)
    # Exiv2 -> Python
    py_shorts = list(shorts)
    print("Python short:", py_shorts)

    print('==== RationalValue ====')
    # This stores 1 or more pairs of ints. Typical usage is
    # Exif.GPSInfo.GPSLatitude, which stores degrees, minutes & seconds.
    py_latitude = [Fraction(51), Fraction(30),
                   Fraction(4.6).limit_denominator(100000)]
    print("Python rational:", py_latitude)
    # Python -> Exiv2
    latitude = exiv2.RationalValue()
    # append values to initialise
    for x in py_latitude:
        latitude += x.numerator, x.denominator
    print("Exiv2 rational:", latitude)
    # modify a value by index
    latitude[1] = -63, 11
    print("Exiv2 rational:", latitude)
    # append a value
    latitude += 19, 3
    print("Exiv2 rational:", latitude)
    # Exiv2 -> Python
    py_latitude = [Fraction(*x) for x in latitude]
    print("Python rational:", py_latitude)

    print('==== XmpArrayValue ====')
    # This is used for XmpSeq, XmpBag and XmpAlt values. It stores one
    # or more strings.
    py_seq = ['First string', 'Second', 'Third']
    print("Python seq:", py_seq)
    # Python -> Exiv2
    seq = exiv2.XmpArrayValue(exiv2.TypeId.xmpBag)
    # append values to initialise
    for x in py_seq:
        seq += x
    print("Exiv2 seq:", seq)
    # Exiv2 -> Python
    py_seq = list(seq)
    print("Python seq:", py_seq)

    return 0


if __name__ == "__main__":
    sys.exit(main())
