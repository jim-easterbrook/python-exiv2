#!/usr/bin/env python

# python-exiv2 - Python interface to libexiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

# Sample/test for high level XMP classes. See also addmoddel.py.

import locale
import sys

import exiv2

def main():
    locale.setlocale(locale.LC_ALL, '')
    try:
        exiv2.XmpParser.initialize()

        # The XMP property container
        xmpData = exiv2.XmpData()

        # --------------------------------------------------------------
        # Teaser: Setting XMP properties doesn't get much easier than
        # this:

        xmpData["Xmp.dc.source"]  = "xmpsample.cpp"     # a simple text value
        xmpData["Xmp.dc.subject"] = "Palmtree"          # an array item
        xmpData["Xmp.dc.subject"] = "Rubbertree"        # add a 2nd array item
        # a language alternative with two entries and without default
        xmpData["Xmp.dc.title"]   = "lang=de-DE Sonnenuntergang am Strand"
        xmpData["Xmp.dc.title"]   = "lang=en-US Sunset on the beach"

        # --------------------------------------------------------------
        # Any properties can be set provided the namespace is known.
        # Values of any type can be assigned to an Xmpdatum, if they
        # have an output operator. The default XMP value type for
        # unknown properties is a simple text value.

        xmpData["Xmp.dc.one"]     = -1
        xmpData["Xmp.dc.two"]     = 3.1415
        xmpData["Xmp.dc.three"]   = exiv2.RationalValue((5, 7))
        xmpData["Xmp.dc.four"]    = exiv2.UShortValue(255)
        xmpData["Xmp.dc.five"]    = 256
        xmpData["Xmp.dc.six"]     = False
 
    except exiv2.AnyError as e:
        print('Caught Exiv2 exception "{}"'.format(str(e)))
        return -1;
    finally:
        exiv2.XmpParser.terminate()
    return 0

if __name__ == "__main__":
    sys.exit(main())
