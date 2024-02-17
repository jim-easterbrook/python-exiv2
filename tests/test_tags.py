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
import unittest

import exiv2


class TestTagsModule(unittest.TestCase):
    key_name = 'Exif.Image.ImageDescription'
    group_name = 'Image'
    tag = 270

    @classmethod
    def setUpClass(cls):
        # clear locale
        name = 'en_US.UTF-8'
        os.environ['LC_ALL'] = name
        os.environ['LANG'] = name
        os.environ['LANGUAGE'] = name

    def check_result(self, result, expected_type, expected_value):
        self.assertIsInstance(result, expected_type)
        self.assertEqual(result, expected_value)

    def test_ExifTags(self):
        tags = exiv2.ExifTags
        key = exiv2.ExifKey(self.key_name)
        self.check_result(tags.defaultCount(key), int, 0)
        group_list = tags.groupList()
        self.assertIsInstance(group_list, list)
        self.assertGreater(len(group_list), 0)
        self.assertIsInstance(group_list[0], exiv2.GroupInfo)
        self.check_result(tags.ifdName(self.group_name), str, 'IFD0')
        self.check_result(tags.isExifGroup(self.group_name), bool, True)
        self.check_result(tags.isMakerGroup(self.group_name), bool, False)
        self.check_result(tags.sectionName(key), str, 'OtherTags')
        tag_list = tags.tagList(self.group_name)
        self.assertIsInstance(tag_list, list)
        self.assertGreater(len(tag_list), 0)
        self.assertIsInstance(tag_list[0], exiv2.TagInfo)

    def test_GroupInfo(self):
        info = exiv2.ExifTags.groupList()[0]
        self.check_result(info['groupName'], str, 'Image')
        if exiv2.testVersion(0, 28, 0):
            self.check_result(info['ifdId'], int, exiv2.IfdId.ifd0Id)
        else:
            self.check_result(info['ifdId'], int, 1)
        self.check_result(info['ifdName'], str, 'IFD0')
        tag_list = info['tagList']()
        self.assertIsInstance(tag_list, list)
        self.assertGreater(len(tag_list), 0)
        self.assertIsInstance(tag_list[0], exiv2.TagInfo)

    def test_TagInfo(self):
        info = exiv2.ExifTags.tagList(self.group_name)[0]
        self.check_result(info['count'], int, 0)
        desc = info['desc']
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('The name and version of the software'))
        if exiv2.testVersion(0, 28, 0):
            self.check_result(info['ifdId'], int, exiv2.IfdId.ifd0Id)
        else:
            self.check_result(info['ifdId'], int, 1)
        self.check_result(info['name'], str, 'ProcessingSoftware')
        if exiv2.testVersion(0, 28, 0):
            self.check_result(
                info['sectionId'], exiv2.SectionId, exiv2.SectionId.otherTags)
        else:
            self.check_result(info['sectionId'], int, 4)
        self.check_result(info['tag'], int, 11)
        self.check_result(info['title'], str, 'Processing Software')
        self.check_result(
            info['typeId'], exiv2.TypeId, exiv2.TypeId.asciiString)

    def test_ExifKey(self):
        # constructors
        key = exiv2.ExifKey(self.key_name)
        self.assertIsInstance(key, exiv2.ExifKey)
        key2 = exiv2.ExifKey(self.tag, self.group_name)
        self.assertIsInstance(key2, exiv2.ExifKey)
        self.assertIsNot(key2, key)
        key2 = exiv2.ExifKey(key)
        self.assertIsInstance(key2, exiv2.ExifKey)
        self.assertIsNot(key2, key)
        # other methods
        self.assertEqual(str(key), self.key_name)
        key2 = key.clone()
        self.assertIsNot(key2, key)
        self.assertIsInstance(key2, exiv2.ExifKey)
        self.check_result(
            key.defaultTypeId(), exiv2.TypeId, exiv2.TypeId.asciiString)
        self.check_result(key.familyName(), str, self.key_name.split('.')[0])
        self.check_result(key.groupName(), str, self.key_name.split('.')[1])
        self.check_result(key.idx(), int, 0)
        self.check_result(key.key(), str, self.key_name)
        key.setIdx(123)
        self.check_result(key.idx(), int, 123)
        self.check_result(key.tag(), int, self.tag)
        desc = key.tagDesc()
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('A character string giving the title'))
        self.check_result(key.tagLabel(), str, 'Image Description')
        self.check_result(key.tagName(), str, self.key_name.split('.')[2])
        buf = io.StringIO()
        buf = key.write(buf)
        self.assertEqual(buf.getvalue(), self.key_name)


if __name__ == '__main__':
    unittest.main()
