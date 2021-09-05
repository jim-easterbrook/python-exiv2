# python-exiv2 - Python interface to libexiv2
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

from setuptools import setup, Extension
import os
import shutil
import subprocess
import sys


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.check_output(cmd, universal_newlines=True).split()
    except Exception:
        return None

mod_src_dir = None

if sys.platform != 'win32':
    # attempt to use installed libexiv2
    exiv2_version = pkg_config('exiv2', 'modversion')
    if exiv2_version:
        exiv2_version = exiv2_version[0]
        mod_src_dir = os.path.join('libexiv2_' + exiv2_version, 'swig')
        if os.path.exists(mod_src_dir):
            library_dirs = [x[2:] for x in pkg_config('exiv2', 'libs-only-L')]
            include_dirs = [x[2:] for x in pkg_config('exiv2', 'cflags-only-I')]
            include_dirs = include_dirs or ['/usr/include']
        else:
            mod_src_dir = None

if not mod_src_dir:
    # installed libexiv2 not found, use our own
    for name in os.listdir('.'):
        if not name.startswith('libexiv2_'):
            continue
        mod_src_dir = os.path.join(name, 'swig')
        lib_dir = os.path.join(name, sys.platform, 'lib')
        inc_dir = os.path.join(name, sys.platform, 'include')
        if not (os.path.exists(lib_dir) and os.path.exists(inc_dir)):
            mod_src_dir = None
            continue
        exiv2_version = name.split('_', 1)[1]
        library_dirs = [lib_dir]
        include_dirs = [inc_dir]
        # link libraries into package
        for name in os.listdir(lib_dir):
            if name == 'exiv2.lib':
                continue
            dest = os.path.join(mod_src_dir, name)
            if not os.path.exists(dest):
                if sys.platform == 'win32':
                    shutil.copy2(os.path.join(lib_dir, name), dest)
                else:
                    os.symlink(
                        os.path.join('..', sys.platform, 'lib', name), dest)
        break

if not mod_src_dir:
    print('ERROR: No SWIG source for libexiv2 version {}'.format(exiv2_version))
    sys.exit(1)

# create extension modules list
ext_modules = []
if sys.platform == 'linux':
    extra_compile_args = [
        '-std=c++98', '-O3', '-Wno-unused-variable',
        '-Wno-deprecated-declarations', '-Wno-unused-but-set-variable',
        '-Wno-deprecated', '-Werror']
elif sys.platform == 'win32':
    extra_compile_args = ['/wd4101', '/wd4290']
elif sys.platform == 'darwin':
    extra_compile_args = []
for file_name in os.listdir(mod_src_dir):
    if file_name[-9:] != '_wrap.cxx':
        continue
    ext_name = file_name[:-9]
    ext_modules.append(Extension(
        '_' + ext_name,
        sources = [os.path.join(mod_src_dir, file_name)],
        include_dirs = include_dirs,
        extra_compile_args = extra_compile_args,
        libraries = ['exiv2'],
        library_dirs = library_dirs,
        ))

# set options for building source distributions
command_options = {}
command_options['sdist'] = {
    'formats' : ('setup.py', 'zip'),
    }

with open('README.rst') as ldf:
    long_description = ldf.read()
py_exiv2_version = long_description.splitlines()[0].split()[-1]

setup(name = 'python-exiv2',
      version = py_exiv2_version,
      description = 'Python interface to libexiv2',
      long_description = long_description,
      author = 'Jim Easterbrook',
      author_email = 'jim@jim-easterbrook.me.uk',
      url = 'https://github.com/jim-easterbrook/python-exiv2',
      classifiers = [
          'Development Status :: 3 - Alpha',
          'Intended Audience :: Developers',
          'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
          'Operating System :: MacOS',
          'Operating System :: MacOS :: MacOS X',
          'Operating System :: POSIX',
          'Operating System :: POSIX :: Linux',
          'Operating System :: Microsoft',
          'Operating System :: Microsoft :: Windows',
          'Programming Language :: Python :: 3',
          'Topic :: Multimedia',
          'Topic :: Multimedia :: Graphics',
          ],
      platforms = ['POSIX', 'MacOS'],
      license = 'GNU GPL',
      command_options = command_options,
      ext_package = 'exiv2',
      ext_modules = ext_modules,
      packages = ['exiv2'],
      package_dir = {'exiv2': mod_src_dir},
      include_package_data = True,
      package_data = {'': ['*.dll', 'libexiv2.*']},
      exclude_package_data = {'': ['*.cxx']},
      zip_safe = False,
      )
