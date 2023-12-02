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

    def test_ExifTags(self):
        tags = exiv2.ExifTags
        key = exiv2.ExifKey(self.key_name)
        count = tags.defaultCount(key)
        self.assertIsInstance(count, int)
        self.assertEqual(count, 0)
        group_list = tags.groupList()
        self.assertIsInstance(group_list, tuple)
        self.assertGreater(len(group_list), 0)
        self.assertIsInstance(group_list[0], exiv2.GroupInfo)
        ifd_name = tags.ifdName(self.group_name)
        self.assertIsInstance(ifd_name, str)
        self.assertEqual(ifd_name, 'IFD0')
        is_exif = tags.isExifGroup(self.group_name)
        self.assertIsInstance(is_exif, bool)
        self.assertEqual(is_exif, True)
        is_maker = tags.isMakerGroup(self.group_name)
        self.assertIsInstance(is_maker, bool)
        self.assertEqual(is_maker, False)
        section = tags.sectionName(key)
        self.assertIsInstance(section, str)
        self.assertEqual(section, 'OtherTags')
        tag_list = tags.tagList(self.group_name)
        self.assertIsInstance(tag_list, tuple)
        self.assertGreater(len(tag_list), 0)
        self.assertIsInstance(tag_list[0], exiv2.TagInfo)

    def test_GroupInfo(self):
        info = exiv2.ExifTags.groupList()[0]
        group_name = info.groupName_
        self.assertIsInstance(group_name, str)
        self.assertEqual(group_name, 'Image')
        ifd_id = info.ifdId_
        self.assertIsInstance(ifd_id, int)
        self.assertEqual(ifd_id, 1)     # Exiv2::IfdId enum not in Python
        ifd_name = info.ifdName_
        self.assertIsInstance(ifd_name, str)
        self.assertEqual(ifd_name, 'IFD0')
        tag_list = info.tagList_
        self.assertIsInstance(tag_list, tuple)
        self.assertGreater(len(tag_list), 0)
        self.assertIsInstance(tag_list[0], exiv2.TagInfo)

    def test_TagInfo(self):
        info = exiv2.ExifTags.tagList(self.group_name)[0]
        count = info.count_
        self.assertIsInstance(count, int)
        self.assertEqual(count, 0)
        desc = info.desc_
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('The name and version of the software'))
        ifd_id = info.ifdId_
        self.assertIsInstance(ifd_id, int)
        self.assertEqual(ifd_id, 1)     # Exiv2::IfdId enum not in Python
        name = info.name_
        self.assertIsInstance(name, str)
        self.assertEqual(name, 'ProcessingSoftware')
        section_id = info.sectionId_
        self.assertIsInstance(section_id, int)
        self.assertEqual(section_id, 4)     # Exiv2::SectionId not in Python
        tag = info.tag_
        self.assertIsInstance(tag, int)
        self.assertEqual(tag, 11)
        title = info.title_
        self.assertIsInstance(title, str)
        self.assertEqual(title, 'Processing Software')
        type_id = info.typeId_
        self.assertIsInstance(type_id, int)
        self.assertEqual(type_id, exiv2.TypeId.asciiString)

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
        default_type_id = key.defaultTypeId()
        self.assertIsInstance(default_type_id, int)
        self.assertEqual(default_type_id, exiv2.TypeId.asciiString)
        family = key.familyName()
        self.assertIsInstance(family, str)
        self.assertEqual(family, self.key_name.split('.')[0])
        group = key.groupName()
        self.assertIsInstance(group, str)
        self.assertEqual(group, self.key_name.split('.')[1])
        idx = key.idx()
        self.assertIsInstance(idx, int)
        self.assertEqual(idx, 0)
        key_name = key.key()
        self.assertIsInstance(key_name, str)
        self.assertEqual(key_name, self.key_name)
        key.setIdx(123)
        self.assertEqual(key.idx(), 123)
        tag = key.tag()
        self.assertIsInstance(tag, int)
        self.assertEqual(tag, self.tag)
        desc = key.tagDesc()
        self.assertIsInstance(desc, str)
        self.assertTrue(desc.startswith('A character string giving the title'))
        label = key.tagLabel()
        self.assertIsInstance(label, str)
        self.assertEqual(label, 'Image Description')
        tag_name = key.tagName()
        self.assertIsInstance(tag_name, str)
        self.assertEqual(tag_name, self.key_name.split('.')[2])
        

if __name__ == '__main__':
    unittest.main()
