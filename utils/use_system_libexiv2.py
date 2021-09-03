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
import subprocess
import sys


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.check_output(cmd, universal_newlines=True).split()
    except Exception:
        error('ERROR: command "%s" failed', ' '.join(cmd))
        raise


def main():
    # get libexiv2 version
    version = pkg_config('exiv2', 'modversion')[0]
    # create directory
    home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    target = os.path.join(home, 'libexiv2_' + version)
    os.makedirs(target, exist_ok=True)
    # open config file
    config_path = os.path.join(target, 'config.ini')
    config = configparser.ConfigParser()
    config.read(config_path)
    if 'libexiv2' not in config:
        config['libexiv2'] = {}
    library_dirs = [x[2:] for x in pkg_config('exiv2', 'libs-only-L')]
    config['libexiv2']['library_dirs'] = ' '.join(library_dirs)
    include_dirs = [x[2:] for x in pkg_config('exiv2', 'cflags-only-I')]
    include_dirs = include_dirs or ['/usr/include']
    config['libexiv2']['include_dirs'] = ' '.join(include_dirs)
    config['libexiv2']['version'] = version
    # save config file
    with open(config_path, 'w') as file:
        config.write(file)
    return 0


if __name__ == "__main__":
    sys.exit(main())
