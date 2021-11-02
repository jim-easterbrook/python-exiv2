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
import subprocess
import sys


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.Popen(
            cmd, stdout=subprocess.PIPE,
            universal_newlines=True).communicate()[0].split()
    except Exception:
        print('ERROR: command "%s" failed' % ' '.join(cmd))
        raise


def main():
    # get version to SWIG
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print('Usage: %s version | "system" ["minimal"]' % sys.argv[0])
        return 1
    # get exiv2 version
    if sys.argv[1] == 'system':
        exiv2_version = pkg_config('exiv2', 'modversion')[0]
    else:
        exiv2_version = sys.argv[1]
    # minimal build?
    minimal = len(sys.argv) >= 3 and sys.argv[2] == 'minimal'
    # get config
    platform = sys.platform
    if platform == 'win32' and 'GCC' in sys.version:
        platform = 'mingw'
    if sys.argv[1] == 'system':
        incl_dir = [x[2:] for x in pkg_config('exiv2', 'cflags-only-I')]
        incl_dir = incl_dir or ['/usr/include']
        incl_dir = incl_dir[0]
    else:
        incl_dir = os.path.join(
            'libexiv2_' + exiv2_version, platform, 'include')
        if not os.path.exists(incl_dir):
            incl_dir = os.path.join(
                'libexiv2_' + exiv2_version, 'linux', 'include')
    # get exiv2 build options
    options = {
        'EXV_ENABLE_BMFF'  : False,
        'EXV_ENABLE_VIDEO' : False,
        'EXV_UNICODE_PATH' : False,
        }
    if not minimal:
        with open(os.path.join(incl_dir, 'exiv2', 'exv_conf.h')) as cnf:
            for line in cnf.readlines():
                for key in options:
                    if key not in line:
                        continue
                    words = line.split()
                    if words[1] != key:
                        continue
                    if words[0] == '#define':
                        options[key] = True
                    elif words[0] == '#undef':
                        options[key] = False
    # get python-exiv2 version
    with open('README.rst') as rst:
        py_exiv2_version = rst.readline().split()[-1]
    # get list of modules (Python) and extensions (SWIG)
    interface_dir = os.path.join('src', 'interface')
    file_names = os.listdir(interface_dir)
    file_names = [x for x in file_names if x != 'preamble.i']
    file_names.sort()
    file_names = [os.path.splitext(x) for x in file_names]
    mod_names = [x[0] + x[1] for x in file_names if x[1] == '.py']
    ext_names = [x[0] for x in file_names if x[1] == '.i']
    # get SWIG version
    cmd = ['swig', '-version']
    try:
        swig_version = str(subprocess.Popen(
            cmd, stdout=subprocess.PIPE,
            universal_newlines=True).communicate()[0])
    except Exception:
        print('ERROR: command "%s" failed' % ' '.join(cmd))
        raise
    for line in swig_version.splitlines():
        if 'Version' in line:
            swig_version = tuple(map(int, line.split()[-1].split('.')))
            break
    # convert exiv2 version to hex
    exiv2_version_hex = '0x{:02x}{:02x}{:02x}{:02x}'.format(
        *map(int, (exiv2_version + '.0.0').split('.')[:4]))
    # create output dir
    output_dir = os.path.join('src', 'swig_' + exiv2_version)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    # copy Python modules
    for mod_name in mod_names:
        shutil.copy2(os.path.join('src', 'interface', mod_name),
                     os.path.join(output_dir, mod_name))
    # make options list
    swig_opts = ['-c++', '-python', '-py3', '-builtin',
                 '-fastdispatch', '-fastproxy',
                 '-Wextra', '-Werror']
    swig_opts.append('-I' + incl_dir)
    for key in options:
        if options[key]:
            swig_opts.append('-D' + key)
    swig_opts.append('-DEXIV2_VERSION_HEX=' + exiv2_version_hex)
    swig_opts += ['-outdir', output_dir]
    # do each swig module
    for ext_name in ext_names:
        cmd = ['swig'] + swig_opts
        # use -doxygen ?
        if swig_version >= (4, 0, 0):
            # -doxygen flag causes a syntax error on error.hpp in v0.26
            if exiv2_version > "0.26" or ext_name not in ('error', ):
                cmd += ['-doxygen', '-DSWIG_DOXYGEN']
        cmd += ['-o', os.path.join(output_dir, ext_name + '_wrap.cxx')]
        cmd += [os.path.join(interface_dir, ext_name + '.i')]
        print(' '.join(cmd))
        subprocess.check_call(cmd)
    # create init module
    init_file = os.path.join(output_dir, '__init__.py')
    with open(init_file, 'w') as im:
        im.write('''
import logging
import sys

if sys.platform == 'win32':
    import os
    _dir = os.path.join(os.path.dirname(__file__), 'lib')
    if os.path.isdir(_dir):
        if hasattr(os, 'add_dll_directory'):
            os.add_dll_directory(_dir)
        os.environ['PATH'] = _dir + ';' + os.environ['PATH']

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

''')
        im.write('__version__ = "%s"\n\n' % py_exiv2_version)
        for name in ext_names:
            im.write('from exiv2.%s import *\n' % name)
        im.write('''
__all__ = [x for x in dir() if x[0] != '_']
''')
    return 0


if __name__ == "__main__":
    sys.exit(main())
