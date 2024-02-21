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

import io
import os
import sys
import unittest

import exiv2


class TestXmpModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_dir = os.path.dirname(__file__)
        # open image in memory so we don't corrupt the file
        with open(os.path.join(test_dir, 'image_02.jpg'), 'rb') as f:
            cls.image = exiv2.ImageFactory.open(f.read())
        # clear locale
        name = 'en_US.UTF-8'
        os.environ['LC_ALL'] = name
        os.environ['LANG'] = name
        os.environ['LANGUAGE'] = name

    def test_XmpData(self):
        # empty container
        data = exiv2.XmpData()
        self.assertEqual(len(data), 0)
        # actual data
        self.image.readMetadata()
        data = self.image.xmpData()
        self.assertEqual(len(data), 26)
        # add data
        data.add(exiv2.Xmpdatum(
            exiv2.XmpKey('Xmp.xmp.CreatorTool'), exiv2.AsciiValue('Acme')))
        self.assertEqual('Xmp.xmp.CreatorTool' in data, True)
        self.assertIsInstance(data['Xmp.xmp.CreatorTool'], exiv2.Xmpdatum)
        data.add(exiv2.XmpKey('Xmp.xmp.Nickname'), exiv2.AsciiValue('Pic'))
        self.assertEqual('Xmp.xmp.Nickname' in data, True)
        self.assertIsInstance(data['Xmp.xmp.Nickname'], exiv2.Xmpdatum)
        # iterators
        b = iter(data)
        self.assertIsInstance(b, exiv2.XmpData_iterator)
        self.assertEqual(b.key(), 'Xmp.iptc.CountryCode')
        b = data.begin()
        self.assertIsInstance(b, exiv2.XmpData_iterator)
        self.assertEqual(b.key(), 'Xmp.iptc.CountryCode')
        next(b)
        self.assertEqual(b.key(), 'Xmp.iptc.CreatorContactInfo')
        e = data.end()
        self.assertIsInstance(e, exiv2.XmpData_iterator_base)
        k = data.findKey(exiv2.XmpKey('Xmp.xmp.CreateDate'))
        self.assertIsInstance(k, exiv2.XmpData_iterator)
        self.assertEqual(k.key(), 'Xmp.xmp.CreateDate')
        k = data.erase(k)
        self.assertIsInstance(k, exiv2.XmpData_iterator)
        self.assertEqual(k.key(), 'Xmp.xmp.ModifyDate')
        self.assertEqual(len(data), 27)
        k = data.findKey(exiv2.XmpKey('Xmp.iptcExt.LocationCreated'))
        data.eraseFamily(k)
        self.assertEqual(len(data), 21)
        # access by key
        self.image.readMetadata()
        self.assertEqual('Xmp.dc.creator' in data, True)
        self.assertIsInstance(data['Xmp.dc.creator'], exiv2.Xmpdatum)
        del data['Xmp.dc.creator']
        self.assertEqual('Xmp.dc.creator' in data, False)
        data['Xmp.dc.creator'] = 'Fred'
        self.assertEqual('Xmp.dc.creator' in data, True)
        self.assertIsInstance(data['Xmp.dc.creator'], exiv2.Xmpdatum)
        with self.assertRaises(TypeError):
            data['Xmp.tiff.Orientation'] = 4
        data['Xmp.tiff.Orientation'] = exiv2.UShortValue(4)
        del data['Xmp.tiff.Orientation']
        b = data.begin()
        e = data.end()
        self.assertIsInstance(str(b), str)
        self.assertIsInstance(str(e), str)
        count = 0
        while b != e:
            next(b)
            count += 1
        self.assertEqual(count, 26)
        count = 0
        for d in data:
            count += 1
        self.assertEqual(count, 26)
        count = len(list(data))
        self.assertEqual(count, 26)
        # sorting
        data.sortByKey()
        self.assertEqual(data.begin().key(), 'Xmp.dc.creator')
        # other methods
        self.assertEqual(data.count(), 26)
        self.assertEqual(data.empty(), False)
        data.clear()
        self.assertEqual(len(data), 0)
        self.assertEqual(data.empty(), True)
        self.image.readMetadata()
        self.assertEqual(len(data), 26)
        self.assertIsInstance(data.xmpPacket(), str)
        data.setPacket('')
        self.assertEqual(data.usePacket(), False)
        self.assertEqual(data.usePacket(True), False)
        self.assertEqual(data.usePacket(), True)

    def _test_datum(self, datum):
        self.assertIsInstance(str(datum), str)
        buf = bytearray(datum.size())
        with self.assertRaises(exiv2.Exiv2Error) as cm:
            datum.copy(buf, exiv2.ByteOrder.littleEndian)
        self.assertEqual(cm.exception.code,
                         exiv2.ErrorCode.kerFunctionNotSupported)
        self.assertEqual(datum.count(), 3)
        self.assertEqual(datum.familyName(), 'Xmp')
        self.assertIsInstance(datum.getValue(), exiv2.LangAltValue)
        with self.assertWarns(DeprecationWarning):
            self.assertIsInstance(
                datum.getValue(exiv2.TypeId.langAlt), exiv2.LangAltValue)
        self.assertEqual(datum.groupName(), 'dc')
        self.assertEqual(datum.key(), 'Xmp.dc.description')
        self.assertEqual(datum.print(), 'lang="x-default" Good view of the'
            ' lighthouse., lang="en-GB" Good view of the lighthouse., lang="de"'
            ' Gute Sicht auf den Leuchtturm.')
        with self.assertWarns(DeprecationWarning):
            self.assertEqual(datum._print(), datum.print())
        self.assertEqual(datum.size(), 130)
        self.assertEqual(datum.tag(), 0)
        self.assertEqual(datum.tagLabel(), 'Description')
        self.assertEqual(datum.tagName(), 'description')
        self.assertEqual(datum.toFloat(0), 0.0)
        if exiv2.testVersion(0, 28, 0):
            self.assertEqual(datum.toInt64(0), 0)
        else:
            self.assertEqual(datum.toLong(0), 0)
        self.assertEqual(datum.toRational(0), (0, 0))
        self.assertEqual(
            datum.toString(), 'lang="x-default" Good view of the lighthouse.,'
            ' lang="en-GB" Good view of the lighthouse., lang="de" Gute Sicht'
            ' auf den Leuchtturm.')
        self.assertEqual(datum.toString(0), 'Good view of the lighthouse.')
        self.assertEqual(datum.typeId(), exiv2.TypeId.langAlt)
        self.assertEqual(datum.typeName(), 'LangAlt')
        self.assertEqual(datum.typeSize(), 0)
        self.assertIsInstance(datum.value(), exiv2.LangAltValue)
        with self.assertWarns(DeprecationWarning):
            self.assertIsInstance(
                datum.value(exiv2.TypeId.langAlt), exiv2.LangAltValue)
        buf = io.StringIO()
        buf = datum.write(buf)
        self.assertEqual(buf.getvalue(), datum.toString())
        datum.setValue('fred')
        datum.setValue(exiv2.XmpTextValue('Acme'))
        with self.assertRaises(TypeError):
            datum.setValue(123)

    def test_XmpData_iterator(self):
        self.image.readMetadata()
        data = self.image.xmpData()
        datum_iter = data.findKey(exiv2.XmpKey('Xmp.dc.description'))
        self.assertIsInstance(datum_iter, exiv2.XmpData_iterator)
        self.assertIsInstance(iter(datum_iter), exiv2.XmpData_iterator)
        self._test_datum(datum_iter)

    def test_XmpDatum(self):
        datum = exiv2.Xmpdatum(
            exiv2.XmpKey('Xmp.xmp.CreatorTool'), exiv2.XmpTextValue('Acme'))
        self.assertIsInstance(datum, exiv2.Xmpdatum)
        datum2 = exiv2.Xmpdatum(datum)
        self.assertIsInstance(datum2, exiv2.Xmpdatum)
        del datum2
        self.image.readMetadata()
        data = self.image.xmpData()
        datum = data['Xmp.dc.description']
        self.assertIsInstance(datum, exiv2.Xmpdatum)
        self._test_datum(datum)

    def test_ref_counts(self):
        self.image.readMetadata()
        # xmpData keeps a reference to image
        self.assertEqual(sys.getrefcount(self.image), 2)
        data = self.image.xmpData()
        self.assertEqual(sys.getrefcount(self.image), 3)
        # iterator keeps a reference to data
        self.assertEqual(sys.getrefcount(data), 2)
        b = data.begin()
        self.assertEqual(sys.getrefcount(data), 3)
        e = data.end()
        self.assertEqual(sys.getrefcount(data), 4)
        i = iter(data)
        self.assertEqual(sys.getrefcount(data), 5)
        k = data.findKey(exiv2.XmpKey('Xmp.xmp.Rating'))
        self.assertEqual(sys.getrefcount(data), 6)
        k2 = data.erase(k)
        self.assertEqual(sys.getrefcount(data), 7)
        del b, e, i, k, k2
        self.assertEqual(sys.getrefcount(data), 2)
        # iterator of an iterator keeps a reference to iterator
        b = data.begin()
        self.assertEqual(sys.getrefcount(b), 2)
        i = iter(b)
        self.assertEqual(sys.getrefcount(b), 3)
        del i
        self.assertEqual(sys.getrefcount(b), 2)
        # iterator value keeps a reference to iterator
        v = b.value()
        self.assertEqual(sys.getrefcount(b), 3)
        del v
        self.assertEqual(sys.getrefcount(b), 2)
        del b
        # datum keeps a reference to data
        self.assertEqual(sys.getrefcount(data), 2)
        datum = data['Xmp.dc.description']
        self.assertEqual(sys.getrefcount(data), 3)
        # value keeps a reference to datum
        self.assertEqual(sys.getrefcount(datum), 2)
        v = datum.value()
        self.assertEqual(sys.getrefcount(datum), 3)
        del v
        self.assertEqual(sys.getrefcount(datum), 2)
        del datum
        self.assertEqual(sys.getrefcount(data), 2)
        del data
        self.assertEqual(sys.getrefcount(self.image), 2)


if __name__ == '__main__':
    unittest.main()
