# python-exiv2 - Python interface to exiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2021  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import shutil
import sys


def main():
    if len(sys.argv) != 3:
        print('Usage: {} libexiv2_dir version'.format(sys.argv[0]))
        return 1
    version = sys.argv[2]
    platform = sys.platform
    if platform == 'win32' and 'GCC' in sys.version:
        platform = 'mingw'
    # get top level directory
    home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    # find library and include files
    lib_files = []
    incl_dir = None
    new_platform = platform
    for root, dirs, files in os.walk(os.path.join(home, sys.argv[1])):
        for file in files:
            if file == 'exiv2.hpp':
                incl_dir = os.path.normpath(root)
                continue
            if file in ('exiv2.dll', 'exiv2.lib'):
                new_platform = 'win32'
            elif file in ('libexiv2.dll', 'libexiv2.dll.a'):
                new_platform = 'mingw'
            elif file.endswith('.dylib'):
                new_platform = 'darwin'
            elif file.startswith('libexiv2.so'):
                new_platform = 'linux'
            else:
                continue
            lib_files.append(os.path.normpath(os.path.join(root, file)))
            if platform != new_platform:
                print('platform {} -> {}'.format(platform, new_platform))
                platform = new_platform
    # get output directory
    target = os.path.join(home, 'libexiv2_' + version, platform)
    if os.path.isdir(target):
        shutil.rmtree(target)
    # copy library
    dest = os.path.join(target, 'lib')
    os.makedirs(dest, exist_ok=True)
    for file in lib_files:
        shutil.copy2(file, dest, follow_symlinks=False)
    # copy include files
    dest = os.path.join(target, 'include', 'exiv2')
    shutil.copytree(incl_dir, dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
