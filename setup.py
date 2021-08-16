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

from collections import defaultdict
from distutils.core import setup, Extension
from distutils.log import error
import os
import subprocess
import sys

# python-exiv2 version
with open('README.rst') as rst:
    version = rst.readline().split()[-1]

# get exiv2 library config
cmd = ['pkg-config', '--modversion', 'exiv2']
FNULL = open(os.devnull, 'w')
try:
    exiv2_version = subprocess.check_output(
        cmd, stderr=FNULL, universal_newlines=True).split('.')
    exiv2_version = tuple(map(int, exiv2_version))
except Exception:
    error('ERROR: command "%s" failed', ' '.join(cmd))
    raise
exiv2_flags = defaultdict(list)
for flag in subprocess.check_output(
        ['pkg-config', '--cflags', '--libs', 'exiv2'],
        universal_newlines=True).split():
    exiv2_flags[flag[:2]].append(flag)
exiv2_include  = exiv2_flags['-I']
exiv2_libs     = exiv2_flags['-l']
exiv2_lib_dirs = exiv2_flags['-L']

# create extension modules list
ext_modules = []
mod_src_dir = 'swig'
extra_compile_args = [
    '-O3', '-Wno-unused-variable', '-Wno-deprecated-declarations',
    '-Wno-unused-but-set-variable', '-Werror']
libraries = [x.replace('-l', '') for x in exiv2_libs]
library_dirs = [x.replace('-L', '') for x in exiv2_lib_dirs]
include_dirs = [x.replace('-I', '') for x in exiv2_include]
for file_name in os.listdir(mod_src_dir):
    if file_name[-9:] != '_wrap.cxx':
        continue
    ext_name = file_name[:-9]
    ext_modules.append(Extension(
        '_' + ext_name,
        sources = [os.path.join(mod_src_dir, file_name)],
        libraries = libraries,
        library_dirs = library_dirs,
        runtime_library_dirs = library_dirs,
        include_dirs = include_dirs,
        extra_compile_args = extra_compile_args,
        ))

with open('README.rst') as ldf:
    long_description = ldf.read()

setup(name = 'exiv2',
      version = version,
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
      ext_package = 'exiv2',
      ext_modules = ext_modules,
      packages = ['exiv2'],
      package_dir = {'exiv2' : mod_src_dir},
      data_files = [
          ('share/python-exiv2', ['LICENSE', 'README.rst']),
          ],
      )
