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


class TestPropertiesModule(unittest.TestCase):
    key_name = 'Xmp.dc.description'
    namespace = 'http://purl.org/dc/elements/1.1/'
    prefix_name = 'dc'
    property_name = 'description'

    @classmethod
    def setUpClass(cls):
        exiv2.XmpParser.initialize()

    def test_XmpNsInfo(self):
        ns_info = exiv2.XmpProperties.nsInfo(self.prefix_name)
        self.assertIsInstance(ns_info, exiv2.XmpNsInfo)
        desc = ns_info.desc_
        self.assertIsInstance(desc, str)
        self.assertEqual(desc, 'Dublin Core schema')
        ns = ns_info.ns_
        self.assertIsInstance(ns, str)
        self.assertEqual(ns, self.namespace)
        prefix = ns_info.prefix_
        self.assertIsInstance(prefix, str)
        self.assertEqual(prefix, self.prefix_name)
        property_info = ns_info.xmpPropertyInfo_
        self.assertIsInstance(property_info, list)
        self.assertGreater(len(property_info), 0)
        self.assertIsInstance(property_info[0], exiv2.XmpPropertyInfo)

    def test_XmpProperties(self):
        properties = exiv2.XmpProperties
        ns = properties.ns(self.prefix_name)
        self.assertIsInstance(ns, str)
        self.assertEqual(ns, self.namespace)
        desc = properties.nsDesc(self.prefix_name)
        self.assertIsInstance(desc, str)
        self.assertEqual(desc, 'Dublin Core schema')
        ns_info = properties.nsInfo(self.prefix_name)
        self.assertIsInstance(ns_info, exiv2.XmpNsInfo)
        prefix = properties.prefix('http://purl.org/dc/elements/1.1/')
        self.assertIsInstance(prefix, str)
        self.assertEqual(prefix, self.prefix_name)
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
        property_title = properties.propertyTitle(key)
        self.assertIsInstance(property_title, str)
        self.assertEqual(property_title, 'Description')
        self.assertIsNone(properties.propertyTitle(key2))
        property_type = properties.propertyType(key)
        self.assertIsInstance(property_type, int)
        self.assertEqual(property_type, exiv2.TypeId.langAlt)
        self.assertEqual(properties.propertyType(key2), exiv2.TypeId.xmpText)
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
        desc = property_info.desc_
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('A textual description of'))
        name = property_info.name_
        self.assertIsInstance(name, str)
        self.assertEqual(name, 'description')
        title = property_info.title_
        self.assertIsInstance(title, str)
        self.assertEqual(title, 'Description')
        type_id = property_info.typeId_
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.langAlt)
        category = property_info.xmpCategory_
        self.assertIsInstance(category, int)
        self.assertEqual(category, exiv2.XmpCategory.External)
        value_type = property_info.xmpValueType_
        self.assertIsInstance(value_type, str)
        self.assertEqual(value_type, 'Lang Alt')

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
        family = key.familyName()
        self.assertIsInstance(family, str)
        self.assertEqual(family, self.key_name.split('.')[0])
        group = key.groupName()
        self.assertIsInstance(group, str)
        self.assertEqual(group, self.key_name.split('.')[1])
        key_name = key.key()
        self.assertIsInstance(key_name, str)
        self.assertEqual(key_name, self.key_name)
        namespace = key.ns()
        self.assertIsInstance(namespace, str)
        self.assertEqual(namespace, self.namespace)
        tag = key.tag()
        self.assertIsInstance(tag, int)
        self.assertEqual(tag, 0)
        label = key.tagLabel()
        self.assertIsInstance(label, str)
        self.assertEqual(label, 'Description')
        tag_name = key.tagName()
        self.assertIsInstance(tag_name, str)
        self.assertEqual(tag_name, self.key_name.split('.')[2])
        

if __name__ == '__main__':
    unittest.main()
