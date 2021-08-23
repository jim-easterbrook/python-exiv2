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

# Sample program showing how to set the Exif comment of an image.

import sys

import exiv2

def main():
    try:
        exiv2.XmpParser.initialize()
        if len(sys.argv) != 2:
            print('Usage: {} file'.format(sys.argv[0]))
            return 1;
        file = sys.argv[1]

        image = exiv2.ImageFactory.open(file)
        image.readMetadata()
        exifData = image.exifData()

        # Exiv2 uses a CommentValue for Exif user comments. The format
        # of the comment string includes an optional charset
        # specification at the beginning:
 
        # [charset=[Ascii|Jis|Unicode|Undefined]] comment
 
        # Undefined is used as a default if the comment doesn't start
        # with a charset definition.
 
        # Following are a few examples of valid comments. The last one
        # is written to the file.

        exifData["Exif.Photo.UserComment"] = (
            "charset=Unicode A Unicode Exif comment added with Exiv2")
        exifData["Exif.Photo.UserComment"] = (
            "charset=Undefined An undefined Exif comment added with Exiv2")
        exifData["Exif.Photo.UserComment"] = (
            "Another undefined Exif comment added with Exiv2")
        exifData["Exif.Photo.UserComment"] = (
            "charset=Ascii An ASCII Exif comment added with Exiv2")

        print("Writing user comment '{}' back to the image.".format(
            exifData["Exif.Photo.UserComment"]))
 
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
