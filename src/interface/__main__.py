# python-exiv2 - Python interface to exiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2021-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

import argparse
import os
import pprint
import sys

import exiv2

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbosity', help='increase output verbosity',
                        action='store_true')
    args = parser.parse_args()
    print('libexiv2 version:', exiv2.version())
    print('python-exiv2 version:', exiv2.__version__)
    print('python-exiv2 examples:',
          os.path.join(os.path.dirname(__file__), 'examples'))
    if args.verbosity:
        print('libexiv2 build options:')
        pprint.pprint(exiv2.versionInfo())

if __name__ == "__main__":
    sys.exit(main())
