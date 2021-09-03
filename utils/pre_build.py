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
    if len(sys.argv) != 2:
        print('Usage: {} libexiv2_dir'.format(sys.argv[0]))
        return 1
    # get top level directories
    home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    source = os.path.abspath(sys.argv[1])
    target = os.path.join(home, 'pre_build')
    if os.path.isdir(target):
        shutil.rmtree(target)
    # copy swig output
    swig_dir = os.path.join(target, 'swig')
    shutil.copytree(os.path.join(source, 'swig'), swig_dir)
    # copy libexiv2 library
    lib_dir = os.path.join(source, sys.platform, 'lib')
    for file in os.listdir(lib_dir):
        path = os.path.join(lib_dir, file)
        if not os.path.islink(path):
            shutil.copy2(path, swig_dir)
    # copy config file
    shutil.copy2(os.path.join(source, 'config.ini'), target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
