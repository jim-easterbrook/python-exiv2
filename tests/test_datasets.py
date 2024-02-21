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
import tempfile
import unittest

import exiv2


class TestDatasetsModule(unittest.TestCase):
    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_DataSet(self):
        dataset = exiv2.IptcDataSets.application2RecordList()[0]
        self.assertIsInstance(dataset, exiv2.DataSet)
        self.assertEqual(dataset['desc'][:27], 'A binary number identifying')
        self.check_result(dataset['mandatory'], bool, True)
        self.check_result(dataset['maxbytes'], int, 2)
        self.check_result(dataset['minbytes'], int, 2)
        self.check_result(dataset['name'], str, 'RecordVersion')
        self.check_result(dataset['number'], int, 0)
        self.check_result(dataset['photoshop'], str, '')
        self.check_result(dataset['recordId'],
                          int, exiv2.IptcDataSets.application2)
        self.check_result(dataset['repeatable'], bool, False)
        self.check_result(dataset['title'], str, 'Record Version')
        self.check_result(dataset['type'],
                          exiv2.TypeId, exiv2.TypeId.unsignedShort)

    def test_IptcDataSets(self):
        # number and record id of Iptc.Application2.Caption
        number = exiv2.IptcDataSets.Caption
        record_id = exiv2.IptcDataSets.application2
        # static data lists
        datasets = exiv2.IptcDataSets.application2RecordList()
        self.assertIsInstance(datasets, list)
        self.assertIsInstance(datasets[0], exiv2.DataSet)
        datasets = exiv2.IptcDataSets.envelopeRecordList()
        self.assertIsInstance(datasets, list)
        self.assertIsInstance(datasets[0], exiv2.DataSet)
        # test other methods 
        self.check_result(exiv2.IptcDataSets.dataSet('Caption', record_id),
                          int, exiv2.IptcDataSets.Caption)
        self.check_result(exiv2.IptcDataSets.dataSetDesc(number, record_id),
                          str, 'A textual description of the object data.')
        self.check_result(exiv2.IptcDataSets.dataSetName(number, record_id),
                          str, 'Caption')
        self.check_result(exiv2.IptcDataSets.dataSetPsName(number, record_id),
                          str, 'Description')
        self.check_result(exiv2.IptcDataSets.dataSetRepeatable(
            number, record_id), bool, False)
        self.check_result(exiv2.IptcDataSets.dataSetTitle(
            number, record_id), str, 'Caption')
        self.check_result(exiv2.IptcDataSets.dataSetType(
            number, record_id), exiv2.TypeId, exiv2.TypeId.string)
        self.check_result(exiv2.IptcDataSets.recordDesc(
            record_id), str, 'IIM application record 2')
        self.check_result(exiv2.IptcDataSets.recordId('Application2'),
                          int, exiv2.IptcDataSets.application2)
        self.check_result(exiv2.IptcDataSets.recordName(
            exiv2.IptcDataSets.application2), str, 'Application2')

    def test_IptcKey(self):
        key_name = 'Iptc.Application2.Caption'
        # constructors
        key = exiv2.IptcKey(key_name)
        self.assertIsInstance(key, exiv2.IptcKey)
        key2 = exiv2.IptcKey(key.tag(), key.record())
        self.assertIsInstance(key2, exiv2.IptcKey)
        self.check_result(key2.key(), str, key_name)
        # copy
        key2 = key.clone()
        self.check_result(key2.key(), str, key_name)
        # other methods
        self.check_result(key.familyName(), str, key_name.split('.')[0])
        self.check_result(key.groupName(), str, key_name.split('.')[1])
        self.check_result(key.key(), str, key_name)
        self.check_result(key.record(), int, exiv2.IptcDataSets.application2)
        self.check_result(key.recordName(), str, key_name.split('.')[1])
        self.check_result(key.tag(), int, exiv2.IptcDataSets.Caption)
        self.check_result(key.tagLabel(), str, key_name.split('.')[2])
        self.check_result(key.tagName(), str, key_name.split('.')[2])
        buf = io.StringIO()
        buf = key.write(buf)
        self.assertEqual(buf.getvalue(), key_name)


if __name__ == '__main__':
    unittest.main()
