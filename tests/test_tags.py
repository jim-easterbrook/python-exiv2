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

import unittest

import exiv2


class TestTagsModule(unittest.TestCase):
    key_name = 'Exif.Image.ImageDescription'
    group_name = 'Image'
    tag = 270

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
        self.check_result(info.groupName_, str, 'Image')
        if exiv2.testVersion(0, 28, 0):
            self.check_result(info.ifdId_, int, exiv2.IfdId.ifd0Id)
        else:
            self.check_result(info.ifdId_, int, 1)
        self.check_result(info.ifdName_, str, 'IFD0')
        tag_list = info.tagList_()
        self.assertIsInstance(tag_list, list)
        self.assertGreater(len(tag_list), 0)
        self.assertIsInstance(tag_list[0], exiv2.TagInfo)
        for key, value in dict(info).items():
            self.assertEqual(value, getattr(info, key + '_'))

    def test_TagInfo(self):
        info = exiv2.ExifTags.tagList(self.group_name)[0]
        self.check_result(info.count_, int, 0)
        desc = info.desc_
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('The name and version of the software'))
        if exiv2.testVersion(0, 28, 0):
            self.check_result(info.ifdId_, int, exiv2.IfdId.ifd0Id)
        else:
            self.check_result(info.ifdId_, int, 1)
        self.check_result(info.name_, str, 'ProcessingSoftware')
        if exiv2.testVersion(0, 28, 0):
            self.check_result(info.sectionId_, int, exiv2.SectionId.otherTags)
        else:
            self.check_result(info.sectionId_, int, 4)
        self.check_result(info.tag_, int, 11)
        self.check_result(info.title_, str, 'Processing Software')
        self.check_result(info.typeId_, int, exiv2.TypeId.asciiString)
        for key, value in dict(info).items():
            self.assertEqual(value, getattr(info, key + '_'))

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
        self.check_result(key.defaultTypeId(), int, exiv2.TypeId.asciiString)
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
        

if __name__ == '__main__':
    unittest.main()
