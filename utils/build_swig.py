# python-gphoto2 - Python interface to exiv2
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


def main(argv=None):
    # get root dir
    root = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))
    # get python-exiv2 version
    with open(os.path.join(root, 'README.rst')) as rst:
        version = rst.readline().split()[-1]
    # get exiv2 library config
    cmd = ['pkg-config', '--modversion', 'exiv2']
    FNULL = open(os.devnull, 'w')
    try:
        exiv2_version = subprocess.check_output(
            cmd, stderr=FNULL, universal_newlines=True).split('.')
        exiv2_version = tuple(map(int, exiv2_version))
    except Exception:
        print('ERROR: command "{}" failed'.format(' '.join(cmd)))
        raise
    print('exiv2_version', exiv2_version)
    exiv2_flags = defaultdict(list)
    for flag in subprocess.check_output(
            ['pkg-config', '--cflags', '--libs', 'exiv2'],
            universal_newlines=True).split():
        exiv2_flags[flag[:2]].append(flag)
    print('exiv2_flags', exiv2_flags)
    exiv2_include  = exiv2_flags['-I']
    exiv2_libs     = exiv2_flags['-l']
    exiv2_lib_dirs = exiv2_flags['-L']
    # get list of modules (Python) and extensions (SWIG)
    file_names = os.listdir(os.path.join(root, 'src'))
    file_names = [x for x in file_names if x != 'preamble.i']
    file_names.sort()
    file_names = [os.path.splitext(x) for x in file_names]
    ext_names = [x[0] for x in file_names if x[1] == '.i']
    print('file_names', file_names)
    # make options list
    swig_opts = ['-c++', '-python', '-py3', '-O', '-I/usr/include',
                 '-Wextra', '-Werror', '-builtin']
    output_dir = os.path.join(root, 'swig')
    os.makedirs(output_dir, exist_ok=True)
    version_opts = ['-outdir', output_dir]
    version_opts += exiv2_include
    # do each swig module
    for ext_name in ext_names:
        cmd = ['swig'] + swig_opts + version_opts
        # -doxygen flag causes a syntax error on error.hpp
        if ext_name not in ('error', ):
            cmd.append('-doxygen')
        cmd += ['-o', os.path.join(root, output_dir, ext_name + '_wrap.cxx')]
        cmd += [os.path.join(root, 'src', ext_name + '.i')]
        print(' '.join(cmd))
        subprocess.check_output(cmd)
    # create init module
    init_file = os.path.join(root, output_dir, '__init__.py')
    with open(init_file, 'w') as im:
        im.write('__version__ = "{}"\n\n'.format(version))
        im.write('''
class AnyError(Exception):
    """Python exception raised by exiv2 library errors

    """
    pass

''')
        for name in ext_names:
            im.write('from exiv2.{} import *\n'.format(name))
        im.write('''
__all__ = dir()
''')
    return 0


if __name__ == "__main__":
    sys.exit(main())
