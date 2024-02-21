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


class TestPropertiesModule(unittest.TestCase):
    key_name = 'Xmp.dc.description'
    namespace = 'http://purl.org/dc/elements/1.1/'
    prefix_name = 'dc'
    property_name = 'description'

    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()

    @classmethod
    def tearDownClass(cls):
        exiv2.XmpParser.terminate()

    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_XmpNsInfo(self):
        ns_info = exiv2.XmpProperties.nsInfo(self.prefix_name)
        self.assertIsInstance(ns_info, exiv2.XmpNsInfo)
        self.check_result(ns_info['desc'], str, 'Dublin Core schema')
        self.check_result(ns_info['ns'], str, self.namespace)
        self.check_result(ns_info['prefix'], str, self.prefix_name)
        property_info = ns_info['xmpPropertyInfo']
        self.assertIsInstance(property_info, list)
        self.assertGreater(len(property_info), 0)
        self.assertIsInstance(property_info[0], exiv2.XmpPropertyInfo)

    def test_XmpProperties(self):
        properties = exiv2.XmpProperties
        self.check_result(properties.ns(self.prefix_name), str, self.namespace)
        self.check_result(properties.nsDesc(self.prefix_name),
                          str, 'Dublin Core schema')
        self.assertIsInstance(properties.nsInfo(self.prefix_name),
                              exiv2.XmpNsInfo)
        self.check_result(properties.prefix('http://purl.org/dc/elements/1.1/'),
                          str, self.prefix_name)
        key = exiv2.XmpKey(self.key_name)
        key2 = exiv2.XmpKey('Xmp.dc.unknown')
        property_desc = properties.propertyDesc(key)
        self.assertIsInstance(property_desc, str)
        self.assertTrue(property_desc.startswith('A textual description of'))
        self.assertIsNone(properties.propertyDesc(key2))
        property_info = properties.propertyInfo(key)
        self.assertIsInstance(property_info, exiv2.XmpPropertyInfo)
        self.assertIsNone(properties.propertyInfo(key2))
        property_list = properties.propertyList(self.prefix_name)
        self.assertIsInstance(property_list, list)
        self.assertGreater(len(property_list), 0)
        self.assertIsInstance(property_list[0], exiv2.XmpPropertyInfo)
        self.check_result(properties.propertyTitle(key), str, 'Description')
        self.assertIsNone(properties.propertyTitle(key2))
        self.check_result(properties.propertyType(key),
                          exiv2.TypeId, exiv2.TypeId.langAlt)
        self.check_result(properties.propertyType(key2),
                          exiv2.TypeId, exiv2.TypeId.xmpText)
        namespaces = properties.registeredNamespaces()
        self.assertIsInstance(namespaces, dict)
        self.assertGreater(len(namespaces), 0)
        self.assertEqual(namespaces[self.prefix_name], self.namespace)
        # these don't seem to have any effect
        properties.registerNs('http://example.com/', 'exmpl')
        properties.unregisterNs('http://example.com/')
        properties.unregisterNs()

    def test_XmpPropertyInfo(self):
        key = exiv2.XmpKey(self.key_name)
        property_info = exiv2.XmpProperties.propertyInfo(key)
        self.assertIsInstance(property_info, exiv2.XmpPropertyInfo)
        desc = property_info['desc']
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('A textual description of'))
        self.check_result(property_info['name'], str, 'description')
        self.check_result(property_info['title'], str, 'Description')
        self.check_result(property_info['typeId'],
                          exiv2.TypeId, exiv2.TypeId.langAlt)
        self.check_result(property_info['xmpCategory'],
                          exiv2.XmpCategory, exiv2.XmpCategory.External)
        self.check_result(property_info['xmpValueType'], str, 'Lang Alt')

    def test_XmpKey(self):
        # constructors
        key = exiv2.XmpKey(self.key_name)
        self.assertIsInstance(key, exiv2.XmpKey)
        key2 = exiv2.XmpKey(self.prefix_name, self.property_name)
        self.assertIsInstance(key2, exiv2.XmpKey)
        self.assertIsNot(key2, key)
        key2 = exiv2.XmpKey(key)
        self.assertIsInstance(key2, exiv2.XmpKey)
        self.assertIsNot(key2, key)
        # other methods
        self.assertEqual(str(key), self.key_name)
        key2 = key.clone()
        self.assertIsNot(key2, key)
        self.assertIsInstance(key2, exiv2.XmpKey)
        self.check_result(key.familyName(), str, self.key_name.split('.')[0])
        self.check_result(key.groupName(), str, self.key_name.split('.')[1])
        self.check_result(key.key(), str, self.key_name)
        self.check_result(key.ns(), str, self.namespace)
        self.check_result(key.tag(), int, 0)
        self.check_result(key.tagLabel(), str, 'Description')
        self.check_result(key.tagName(), str, self.key_name.split('.')[2])
        buf = io.StringIO()
        buf = key.write(buf)
        self.assertEqual(buf.getvalue(), self.key_name)


if __name__ == '__main__':
    unittest.main()
