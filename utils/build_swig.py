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

from collections import defaultdict
import os
import re
import subprocess
import sys


# get root dir
root = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
# get exiv2 library config
exec(open(os.path.join(root, 'utils', 'exiv2_cfg.py')).read())


def main(argv=None):
    # get python-exiv2 version
    with open(os.path.join(root, 'README.rst')) as rst:
        version = rst.readline().split()[-1]
    # get list of modules (Python) and extensions (SWIG)
    file_names = os.listdir(os.path.join(root, 'src'))
    file_names = [x for x in file_names if x != 'preamble.i']
    file_names.sort()
    file_names = [os.path.splitext(x) for x in file_names]
    ext_names = [x[0] for x in file_names if x[1] == '.i']
    # get SWIG version
    cmd = ['swig', '-version']
    try:
        swig_version = str(
            subprocess.check_output(cmd, universal_newlines=True))
    except Exception:
        print('ERROR: command "{}" failed'.format(' '.join(cmd)))
        raise
    for line in swig_version.splitlines():
        if 'Version' in line:
            swig_version = tuple(map(int, line.split()[-1].split('.')))
            break
    # make options list
    output_dir = os.path.join(root, 'swig')
    os.makedirs(output_dir, exist_ok=True)
    swig_opts = ['-c++', '-python', '-py3', '-O', '-I/usr/include',
                 '-Wextra', '-Werror', '-builtin', '-outdir', output_dir]
    swig_opts += exiv2_cfg['include_dirs']
    # do each swig module
    for ext_name in ext_names:
        cmd = ['swig'] + swig_opts
        # use -doxygen ?
        if swig_version >= (4, 0, 0):
            # -doxygen flag causes a syntax error on error.hpp
            if ext_name not in ('error', ):
                cmd += ['-doxygen', '-DSWIG_DOXYGEN']
        cmd += ['-o', os.path.join(root, output_dir, ext_name + '_wrap.cxx')]
        cmd += [os.path.join(root, 'src', ext_name + '.i')]
        print(' '.join(cmd))
        subprocess.check_output(cmd)
    # create init module
    init_file = os.path.join(root, output_dir, '__init__.py')
    with open(init_file, 'w') as im:
        im.write('''
import logging

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

''')
        im.write('__version__ = "{}"\n\n'.format(version))
        for name in ext_names:
            im.write('from exiv2.{} import *\n'.format(name))
        im.write('''
__all__ = [x for x in dir() if x[0] != '_']
''')
    return 0


if __name__ == "__main__":
    sys.exit(main())
