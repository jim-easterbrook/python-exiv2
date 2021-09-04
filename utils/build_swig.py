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
import configparser
import os
import re
import subprocess
import sys


def main():
    if len(sys.argv) != 2:
        print('Usage: {} libexiv2_dir'.format(sys.argv[0]))
        return 1
    # get directories
    home = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    target = os.path.abspath(sys.argv[1])
    # get config
    config = configparser.ConfigParser()
    config.read(os.path.join(target, 'config.ini'))
    # get python-exiv2 version
    with open(os.path.join(home, 'README.rst')) as rst:
        py_exiv2_version = rst.readline().split()[-1]
    # get list of modules (Python) and extensions (SWIG)
    file_names = os.listdir(os.path.join(home, 'src'))
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
    output_dir = os.path.join(target, 'swig')
    os.makedirs(output_dir, exist_ok=True)
    swig_opts = ['-c++', '-python', '-py3', '-builtin', '-O',
                 '-Wextra', '-Werror']
    incl_dir = config['libexiv2']['include_dirs']
    swig_opts.append('-I' + incl_dir)
    if os.path.exists(os.path.join(incl_dir, 'exiv2', 'xmp_exiv2.hpp')):
        swig_opts.append('-DHAS_XMP_EXIV2')
    swig_opts += ['-outdir', output_dir]
    # do each swig module
    for ext_name in ext_names:
        cmd = ['swig'] + swig_opts
        # use -doxygen ?
        if swig_version >= (4, 0, 0):
            # -doxygen flag causes a syntax error on error.hpp
            if ext_name not in ('error', ):
                cmd += ['-doxygen', '-DSWIG_DOXYGEN']
        cmd += ['-o', os.path.join(output_dir, ext_name + '_wrap.cxx')]
        cmd += [os.path.join(home, 'src', ext_name + '.i')]
        print(' '.join(cmd))
        subprocess.check_output(cmd)
    # create init module
    init_file = os.path.join(output_dir, '__init__.py')
    with open(init_file, 'w') as im:
        im.write('''
import logging
import sys

if sys.platform == 'linux':
    import os
    _lib = os.path.join(os.path.dirname(__file__), 'libexiv2.so')
    if os.path.exists(_lib):
        # import libexiv2 shared library (avoids setting LD_LIBRARY_PATH)
        from ctypes import cdll
        cdll.LoadLibrary(_lib)

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

''')
        im.write('__version__ = "{}"\n\n'.format(py_exiv2_version))
        for name in ext_names:
            im.write('from exiv2.{} import *\n'.format(name))
        im.write('''
__all__ = [x for x in dir() if x[0] != '_']
''')
    return 0


if __name__ == "__main__":
    sys.exit(main())
