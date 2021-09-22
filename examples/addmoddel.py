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

# Sample program showing how to add, modify and delete Exif metadata.

import sys

import exiv2

def main():
    try:
        exiv2.XmpParser.initialize()
        if len(sys.argv) != 2:
            print('Usage: {} file'.format(sys.argv[0]))
            return 1;
        file = sys.argv[1]
        # Container for exif metadata. This is an example of creating
        # exif metadata from scratch. If you want to add, modify, delete
        # metadata that exists in an image, start with
        # ImageFactory::open
        exifData = exiv2.ExifData()

        # **************************************************************
        # Add to the Exif data

        # This is the quickest way to add (simple) Exif data. If a
        # metadatum for a given key already exists, its value is
        # overwritten. Otherwise a new tag is added.
        exifData["Exif.Image.Model"] = "Test 1"                 # AsciiValue
        exifData["Exif.Image.SamplesPerPixel"] = exiv2.UShortValue(162) # UShortValue
        exifData["Exif.Image.XResolution"] = exiv2.LongValue(-2)        # LongValue
        exifData["Exif.Image.YResolution"] = exiv2.RationalValue((-2, 3)) # Rational
        print("Added a few tags the quick way.")

        # Create a ASCII string value (note the use of create)
        v = exiv2.Value.create(exiv2.TypeId.asciiString)
        # Set the value to a string
        v.read("1999:12:31 23:59:59")
        # Add the value together with its key to the Exif data container
        key = exiv2.ExifKey("Exif.Photo.DateTimeOriginal")
        exifData.add(key, v)
        print('Added key "{}", value "{}"'.format(key, v))

        # Now create a more interesting value (without using the create method)
        rv = exiv2.URationalValue()
        # Set two rational components from a string
        rv.read("1/2 1/3")
        # Add more elements through the extended interface of rational value
        rv.value_.push_back((2,3))
        rv.value_.push_back((3,4))
        # Add the key and value pair to the Exif data
        key = exiv2.ExifKey("Exif.Image.PrimaryChromaticities")
        exifData.add(key, rv)
        print('Added key "{}", value "{}"'.format(key, rv))

        # **************************************************************
        # Modify Exif data

        # Since we know that the metadatum exists (or we don't mind
        # creating a new tag if it doesn't), we can simply do this:
        tag = exifData["Exif.Photo.DateTimeOriginal"]
        date = tag.toString()
        date = '2000' + date[4:]
        tag.setValue(date)
        print('Modified key "{}", new value "{}"'.format(
            tag.key(), tag.value()))

        # Alternatively, we can use findKey()
        key = exiv2.ExifKey("Exif.Image.PrimaryChromaticities")
        pos = exifData.findKey(key)
        if pos == exifData.end():
            raise exiv2.AnyError("Key not found")
        # Get a copy of the value
        v = pos.getValue()
        # Downcast the Value pointer to its actual type
        rv = exiv2.URationalValue.downCast(v)
        # Modify the value directly through the interface of URationalValue
        rv.value_[2] = 88,77

        # **************************************************************
        # Delete metadata from the Exif data container

        # Delete the metadatum at iterator position pos
        key = exiv2.ExifKey("Exif.Image.PrimaryChromaticities")
        pos = exifData.findKey(key)
        if pos == exifData.end():
            raise exiv2.AnyError("Key not found")
        exifData.erase(pos)
        print('Deleted key "{}"'.format(key))

        # **************************************************************
        # Finally, write the remaining Exif data to the image file
        image = exiv2.ImageFactory.open(file)

        image.setExifData(exifData)
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
