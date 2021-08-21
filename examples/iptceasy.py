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

# The quickest way to access, set or modify IPTC metadata.

import sys

import exiv2

def main():
    try:
        exiv2.XmpParser.initialize()
        if len(sys.argv) != 2:
            print('Usage: {} file'.format(sys.argv[0]))
            return 1;
        file = sys.argv[1]

        iptcData = exiv2.IptcData()

        iptcData["Iptc.Application2.Headline"] = "The headline I am"
        iptcData["Iptc.Application2.Keywords"] = "Yet another keyword"
        iptcData["Iptc.Application2.DateCreated"] = "2004-8-3"
        iptcData["Iptc.Application2.Urgency"] = exiv2.UShortValue(1)
        iptcData["Iptc.Envelope.ModelVersion"] = 42
        iptcData["Iptc.Envelope.TimeSent"] = "14:41:0-05:00"
        iptcData["Iptc.Application2.RasterizedCaption"] = "230 42 34 2 90 84 23 146"
        iptcData["Iptc.0x0009.0x0001"] = "Who am I?"

        value = exiv2.StringValue()
        value.read("very!")
        iptcData["Iptc.Application2.Urgency"] = value

        print("Time sent: {}".format(iptcData["Iptc.Envelope.TimeSent"]))

        # Open image file
        image = exiv2.ImageFactory.open(file)

        # Set IPTC data and write it to the file
        image.setIptcData(iptcData)
        image.writeMetadata()

        return 0
    except exiv2.AnyError as e:
        print('Caught Exiv2 exception "{}"'.format(str(e)))
        return -1;
    finally:
        exiv2.XmpParser.terminate()
    return 0

if __name__ == "__main__":
    sys.exit(main())
