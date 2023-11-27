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

import os
import sys
import unittest

import exiv2


class TestIptcModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()
        test_dir = os.path.dirname(__file__)
        # open image in memory so we don't corrupt the file
        with open(os.path.join(test_dir, 'image_02.jpg'), 'rb') as f:
            cls.image = exiv2.ImageFactory.open(f.read())

    def test_IptcData(self):
        # empty container
        data = exiv2.IptcData()
        self.assertEqual(len(data), 0)
        # actual data
        self.image.readMetadata()
        data = self.image.iptcData()
        self.assertEqual(len(data), 19)
        # add data
        data.add(exiv2.Iptcdatum(
            exiv2.IptcKey('Iptc.Application2.LocationCode'),
            exiv2.AsciiValue('XYZ')))
        self.assertEqual('Iptc.Application2.LocationCode' in data, True)
        self.assertIsInstance(
            data['Iptc.Application2.LocationCode'], exiv2.Iptcdatum)
        data.add(exiv2.IptcKey('Iptc.Application2.LocationName'),
                 exiv2.AsciiValue('Erewhon'))
        self.assertEqual('Iptc.Application2.LocationName' in data, True)
        self.assertIsInstance(
            data['Iptc.Application2.LocationName'], exiv2.Iptcdatum)
        # iterators
        b = iter(data)
        self.assertIsInstance(b, exiv2.IptcData_iterator)
        self.assertEqual(b.key(), 'Iptc.Envelope.CharacterSet')
        b = data.begin()
        self.assertIsInstance(b, exiv2.IptcData_iterator)
        self.assertEqual(b.key(), 'Iptc.Envelope.CharacterSet')
        next(b)
        self.assertEqual(b.key(), 'Iptc.Application2.Contact')
        e = data.end()
        self.assertIsInstance(e, exiv2.IptcData_iterator_end)
        k = data.findKey(exiv2.IptcKey('Iptc.Application2.SpecialInstructions'))
        self.assertIsInstance(k, exiv2.IptcData_iterator)
        self.assertEqual(k.key(), 'Iptc.Application2.SpecialInstructions')
        k = data.erase(k)
        self.assertIsInstance(k, exiv2.IptcData_iterator)
        self.assertEqual(k.key(), 'Iptc.Application2.Keywords')
        # access by key
        self.assertEqual('Iptc.Application2.Byline' in data, True)
        self.assertIsInstance(data['Iptc.Application2.Byline'], exiv2.Iptcdatum)
        del data['Iptc.Application2.Byline']
        self.assertEqual('Iptc.Application2.Byline' in data, False)
        data['Iptc.Application2.Byline'] = 'Fred'
        self.assertEqual('Iptc.Application2.Byline' in data, True)
        self.assertIsInstance(data['Iptc.Application2.Byline'], exiv2.Iptcdatum)
        # sorting
        data.sortByKey()
        self.assertEqual(data.begin().key(), 'Iptc.Application2.Byline')
        data.sortByTag()
        self.assertEqual(data.begin().key(), 'Iptc.Application2.ObjectName')
        # other methods
        self.assertEqual(data.count(), 20)
        self.assertEqual(data.empty(), False)
        data.clear()
        self.assertEqual(len(data), 0)
        self.assertEqual(data.empty(), True)

    def test_ref_counts(self):
        self.image.readMetadata()
        # iptcData keeps a reference to image
        self.assertEqual(sys.getrefcount(self.image), 2)
        data = self.image.iptcData()
        self.assertEqual(sys.getrefcount(self.image), 3)
        # iterator keeps a reference to data
        self.assertEqual(sys.getrefcount(data), 2)
        b = data.begin()
        self.assertEqual(sys.getrefcount(data), 3)
        e = data.end()
        self.assertEqual(sys.getrefcount(data), 4)
        i = iter(data)
        self.assertEqual(sys.getrefcount(data), 5)
        k = data.findKey(exiv2.IptcKey('Iptc.Application2.Caption'))
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
        datum = data['Iptc.Application2.Contact']
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