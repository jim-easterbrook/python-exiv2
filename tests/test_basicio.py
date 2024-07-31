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

import locale
import os
import shutil
import sys
import tempfile
import unittest

import exiv2


class TestBasicIoModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_dir = os.path.dirname(__file__)
        cls.image_path = os.path.join(test_dir, 'image_02.jpg')
        cls.data = b'The quick brown fox jumps over the lazy dog'

    @unittest.skipUnless(exiv2.versionInfo()['EXV_USE_CURL'],
                         'CurlIo not included')
    def test_CurlIo(self):
        https_image = ('https://raw.githubusercontent.com/jim-easterbrook'
                       '/python-exiv2/main/tests/image_02.jpg')
        io = exiv2.ImageFactory.createIo(https_image)
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.ioType(), 'CurlIo')
        self.assertEqual(io.error(), False)
        self.assertEqual(io.path(), https_image)
        self.assertEqual(io.size(), 0)
        # open and close
        self.assertEqual(io.isopen(), False)
        self.assertEqual(io.open(), 0)
        self.assertEqual(io.size(), 15125)
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.close(), 0)
        self.assertEqual(io.isopen(), True)

    @unittest.skipUnless(exiv2.versionInfo()['EXV_ENABLE_FILESYSTEM'],
                         'EXV_ENABLE_FILESYSTEM is off')
    def test_FileIo(self):
        # most functions are tested in test_MemIo
        io = exiv2.ImageFactory.createIo(self.image_path)
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.ioType(), 'FileIo')
        self.assertEqual(io.error(), False)
        self.assertEqual(io.path(), self.image_path)
        self.assertEqual(io.size(), 15125)
        # open and close
        self.assertEqual(io.isopen(), False)
        self.assertEqual(io.open(), 0)
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.close(), 0)
        self.assertEqual(io.isopen(), False)

    def test_MemIo(self):
        # empty buffer
        io = exiv2.ImageFactory.createIo(b'')
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.ioType(), 'MemIo')
        self.assertEqual(io.size(), 0)
        # mmap data access
        with io.mmap(False) as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, b'')
            self.assertEqual(view.readonly, True)
            with self.assertRaises(TypeError):
                view[0] = 0
        self.assertEqual(io.munmap(), 0)
        with io.mmap(True) as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, b'')
            self.assertEqual(view.readonly, False)
            with self.assertRaises(IndexError):
                view[0] = 0
        self.assertEqual(io.munmap(), 0)
        # Python buffer interface
        with memoryview(io) as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, b'')
            self.assertEqual(view.readonly, False)
            with self.assertRaises(IndexError):
                view[0] = 0
        # non-empty buffer
        io = exiv2.ImageFactory.createIo(self.data)
        self.assertIsInstance(io, exiv2.BasicIo)
        self.assertEqual(io.ioType(), 'MemIo')
        self.assertEqual(io.error(), False)
        self.assertEqual(io.path(), 'MemIo')
        self.assertEqual(io.size(), len(self.data))
        self.assertEqual(len(io), len(self.data))
        # open and close, MemIo is always open
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.close(), 0)
        self.assertEqual(io.isopen(), True)
        self.assertEqual(io.open(), 0)
        self.assertEqual(io.isopen(), True)
        # mmap data access
        with io.mmap() as view:
            self.assertIsInstance(view, memoryview)
            self.assertEqual(view, self.data)
        self.assertEqual(io.munmap(), 0)
        # Python buffer interface
        with memoryview(io) as view:
            self.assertEqual(view, self.data)
            self.assertEqual(view.readonly, False)
        # seek & tell
        with self.assertWarns(DeprecationWarning):
            self.assertEqual(io.seek(0, exiv2.Position.beg), 0)
        self.assertEqual(io.tell(), 0)
        if exiv2.testVersion(0, 28, 0):
            self.assertEqual(
                io.seek(len(self.data) + 10, exiv2.BasicIo.Position.beg),
                exiv2.ErrorCode.kerGeneralError)
            with self.assertRaises(exiv2.Exiv2Error) as cm:
                io.seekOrThrow(len(self.data) + 10, exiv2.BasicIo.Position.beg)
            self.assertEqual(cm.exception.code,
                             exiv2.ErrorCode.kerCorruptedMetadata)
        else:
            self.assertEqual(
                io.seek(len(self.data) + 10, exiv2.BasicIo.Position.beg),
                exiv2.ErrorCode.kerErrorMessage)
        self.assertEqual(io.seek(0, exiv2.BasicIo.Position.end), 0)
        self.assertEqual(io.tell(), len(self.data))
        # reading data
        self.assertEqual(io.seek(0, exiv2.BasicIo.Position.beg), 0)
        self.assertEqual(io.getb(), self.data[0])
        self.assertEqual(io.tell(), 1)
        self.assertEqual(memoryview(io.read(10000)), self.data[1:])
        self.assertEqual(io.tell(), len(self.data))
        self.assertEqual(io.eof(), True)
        self.assertEqual(io.seek(0, exiv2.BasicIo.Position.beg), 0)
        buf = bytearray(len(self.data))
        self.assertEqual(io.read(buf, len(self.data)), len(self.data))
        self.assertEqual(buf, self.data)
        if exiv2.testVersion(0, 28, 0):
            with self.assertRaises(exiv2.Exiv2Error) as cm:
                io.readOrThrow(buf, len(self.data))
            self.assertEqual(cm.exception.code,
                             exiv2.ErrorCode.kerCorruptedMetadata)
        self.assertEqual(io.tell(), len(self.data))
        self.assertEqual(io.getb(), -1)
        # writing data
        self.assertEqual(io.putb(ord('+')), ord('+'))
        self.assertEqual(io.eof(), True)
        self.assertEqual(len(io), len(self.data) + 1)
        self.assertEqual(io.write(exiv2.ImageFactory.createIo(b'fred')), 4)
        self.assertEqual(len(io), len(self.data) + 5)
        self.assertEqual(io.write(b'+jim'), 4)
        self.assertEqual(len(io), len(self.data) + 9)
        self.assertEqual(memoryview(io), self.data + b'+fred+jim')

    def test_ref_counts(self):
        # MemIo keeps a reference to the data buffer
        self.assertEqual(sys.getrefcount(self.data), 3)
        io = exiv2.ImageFactory.createIo(self.data)
        self.assertEqual(sys.getrefcount(self.data), 4)
        del io
        self.assertEqual(sys.getrefcount(self.data), 3)

    @unittest.skipUnless(exiv2.versionInfo()['EXV_ENABLE_FILESYSTEM'],
                         'EXV_ENABLE_FILESYSTEM is off')
    def test_unicode_paths(self):
        cp = locale.getpreferredencoding()
        with tempfile.TemporaryDirectory() as tmp_dir:
            for file_name, codes in (
                    ('Lâtín.jpg', ('UTF-8', 'cp65001', 'cp1252', 'cp850')),
                    ('Русский.jpg', ('UTF-8', 'cp65001', 'cp20866', 'cp20880',
                                     'cp866', 'cp855')),
                    ('中国人.jpg', ('UTF-8', 'cp65001', 'cp54936', 'cp936'))):
                with self.subTest(file_name=file_name, codes=codes):
                    tmp_path = os.path.normcase(os.path.join(tmp_dir, file_name))
                    shutil.copyfile(self.image_path, tmp_path)
                    io = exiv2.ImageFactory.createIo(tmp_path)
                    if cp in codes:
                        self.assertEqual(io.path(), tmp_path)
                    else:
                        self.skipTest("code page '{}' not suitable for file "
                                      "name '{}'".format(cp, file_name))


if __name__ == '__main__':
    unittest.main()
