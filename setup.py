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

import configparser
from setuptools import setup, Extension
import os
import subprocess
import sys


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.check_output(cmd, universal_newlines=True).split()
    except Exception:
        error('ERROR: command "%s" failed', ' '.join(cmd))
        raise

# get source directory and config
if os.path.exists('pre_build'):
    # building with a local copy of libexiv2
    mod_src_dir = os.path.join('pre_build', 'swig')
    config = configparser.ConfigParser()
    config.read(os.path.join('pre_build', 'config.ini'))
    library_dirs = config['libexiv2']['library_dirs'].split()
    include_dirs = config['libexiv2']['include_dirs'].split()
else:
    # building with system installed libexiv2
    exiv2_version = pkg_config('exiv2', 'modversion')[0]
    mod_src_dir = os.path.join('libexiv2_' + exiv2_version, 'swig')
    library_dirs = [x[2:] for x in pkg_config('exiv2', 'libs-only-L')]
    include_dirs = [x[2:] for x in pkg_config('exiv2', 'cflags-only-I')]
    include_dirs = include_dirs or ['/usr/include']

# create extension modules list
ext_modules = []
if sys.platform == 'linux':
    extra_compile_args = [
        '-std=c++98', '-O3', '-Wno-unused-variable',
        '-Wno-deprecated-declarations', '-Wno-unused-but-set-variable',
        '-Wno-deprecated', '-Werror']
elif sys.platform == 'win32':
    extra_compile_args = ['/wd4101', '/wd4290']
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

command_options = {}

# set options for building source distributions
command_options['sdist'] = {
    'formats' : ('setup.py', 'zip'),
    }

with open('README.rst') as rst:
    py_exiv2_version = rst.readline().split()[-1]

with open('README.rst') as ldf:
    long_description = ldf.read()

setup(name = 'python-exiv2',
      version = py_exiv2_version,
      description = 'Python interface to libexiv2',
      long_description = long_description,
      author = 'Jim Easterbrook',
      author_email = 'jim@jim-easterbrook.me.uk',
      url = 'https://github.com/jim-easterbrook/python-exiv2',
      classifiers = [
          'Development Status :: 2 - Pre-Alpha',
          'Intended Audience :: Developers',
          'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
          'Operating System :: MacOS',
          'Operating System :: MacOS :: MacOS X',
          'Operating System :: POSIX',
          'Operating System :: POSIX :: BSD :: FreeBSD',
          'Operating System :: POSIX :: BSD :: NetBSD',
          'Operating System :: POSIX :: Linux',
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
      package_data = {'': ['exiv2.dll', 'libexiv2.*']},
      exclude_package_data = {'': ['*.cxx']},
      zip_safe = False,
      )
