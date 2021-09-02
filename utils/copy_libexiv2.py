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

import configparser
import os
import shutil
import sys


def main():
    if len(sys.argv) != 3:
        print('Usage: {} libexiv2_dir version'.format(sys.argv[0]))
        return 1;
    version = sys.argv[2]
    # get top level directories
    home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    target = os.path.join(home, 'libexiv2_' + version, sys.platform)
    if os.path.isdir(target):
        shutil.rmtree(target)
    # find library and include files
    lib_files = []
    incl_dir = None
    for root, dirs, files in os.walk(os.path.join(home, sys.argv[1])):
        for file in files:
            if sys.platform == 'linux':
                if file.startswith('libexiv2.'):
                    lib_files.append(os.path.normpath(os.path.join(root, file)))
            elif sys.platform == 'win32':
                if file in ['exiv2.lib', 'exiv2.dll']:
                    lib_files.append(os.path.normpath(os.path.join(root, file)))
            if file == 'exiv2.hpp':
                incl_dir = os.path.normpath(root)
    # open config file
    config_path = os.path.join(home, 'libexiv2.ini')
    config = configparser.ConfigParser()
    config.read(config_path)
    if 'libexiv2' not in config:
        config['libexiv2'] = {}
    config['libexiv2']['using_system'] = 'False'
    # copy library
    dest = os.path.join(target, 'lib')
    config['libexiv2']['library_dirs'] = dest
    os.makedirs(dest, exist_ok=True)
    for file in lib_files:
        shutil.copy2(file, dest, follow_symlinks=False)
    # copy include files
    dest = os.path.join(target, 'include', 'exiv2')
    config['libexiv2']['include_dirs'] = os.path.dirname(dest)
    shutil.copytree(incl_dir, dest)
    # save config file
    config['libexiv2']['version'] = version
    with open(config_path, 'w') as file:
        config.write(file)
    return 0


if __name__ == "__main__":
    sys.exit(main())
