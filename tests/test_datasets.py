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
import tempfile
import unittest

import exiv2


class TestDatasetsModule(unittest.TestCase):
    def test_DataSet(self):
        dataset = exiv2.IptcDataSets.application2RecordList()[0]
        self.assertIsInstance(dataset, dict)
        self.assertEqual(dataset['desc'][:27], 'A binary number identifying')
        self.assertEqual(dataset['mandatory'], True)
        self.assertEqual(dataset['maxbytes'], 2)
        self.assertEqual(dataset['minbytes'], 2)
        self.assertEqual(dataset['name'], 'RecordVersion')
        self.assertEqual(dataset['number'], 0)
        self.assertEqual(dataset['photoshop'], '')
        self.assertEqual(dataset['recordId'], exiv2.IptcDataSets.application2)
        self.assertEqual(dataset['repeatable'], False)
        self.assertEqual(dataset['title'], 'Record Version')
        self.assertEqual(dataset['type'], exiv2.TypeId.unsignedShort)

    def test_IptcDataSets(self):
        # number and record id of Iptc.Application2.Caption
        number = exiv2.IptcDataSets.Caption
        record_id = exiv2.IptcDataSets.application2
        # static data lists
        datasets = exiv2.IptcDataSets.application2RecordList()
        self.assertIsInstance(datasets, list)
        self.assertIsInstance(datasets[0], dict)
        datasets = exiv2.IptcDataSets.envelopeRecordList()
        self.assertIsInstance(datasets, list)
        self.assertIsInstance(datasets[0], dict)
        # test other methods 
        self.assertEqual(exiv2.IptcDataSets.dataSet(
            'Caption', record_id), exiv2.IptcDataSets.Caption)
        self.assertEqual(exiv2.IptcDataSets.dataSetDesc(
            number, record_id), 'A textual description of the object data.')
        self.assertEqual(exiv2.IptcDataSets.dataSetName(
            number, record_id), 'Caption')
        self.assertEqual(exiv2.IptcDataSets.dataSetPsName(
            number, record_id), 'Description')
        self.assertEqual(exiv2.IptcDataSets.dataSetRepeatable(
            number, record_id), False)
        self.assertEqual(exiv2.IptcDataSets.dataSetTitle(
            number, record_id), 'Caption')
        self.assertEqual(exiv2.IptcDataSets.dataSetType(
            number, record_id), exiv2.TypeId.string)
        self.assertEqual(exiv2.IptcDataSets.recordDesc(
            record_id), 'IIM application record 2')
        self.assertEqual(exiv2.IptcDataSets.recordId(
            'Application2'), exiv2.IptcDataSets.application2)
        self.assertEqual(exiv2.IptcDataSets.recordName(
            exiv2.IptcDataSets.application2), 'Application2')

    def test_IptcKey(self):
        key_name = 'Iptc.Application2.Caption'
        # constructors
        key = exiv2.IptcKey(key_name)
        self.assertIsInstance(key, exiv2.IptcKey)
        key2 = exiv2.IptcKey(key.tag(), key.record())
        self.assertIsInstance(key2, exiv2.IptcKey)
        self.assertEqual(key2.key(), key_name)
        # copy
        key2 = key.clone()
        self.assertEqual(key2.key(), key_name)
        # other methods
        self.assertEqual(key.familyName(), key_name.split('.')[0])
        self.assertEqual(key.groupName(), key_name.split('.')[1])
        self.assertEqual(key.key(), key_name)
        self.assertEqual(key.record(), exiv2.IptcDataSets.application2)
        self.assertEqual(key.recordName(), key_name.split('.')[1])
        self.assertEqual(key.tag(), exiv2.IptcDataSets.Caption)
        self.assertEqual(key.tagLabel(), key_name.split('.')[2])
        self.assertEqual(key.tagName(), key_name.split('.')[2])
        

if __name__ == '__main__':
    unittest.main()
