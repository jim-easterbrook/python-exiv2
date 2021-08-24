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

from distutils.core import setup, Extension
import os


# python-exiv2 version
with open('README.rst') as rst:
    version = rst.readline().split()[-1]

# get exiv2 library config
exec(open('utils/exiv2_cfg.py').read())

# create extension modules list
ext_modules = []
mod_src_dir = 'swig'
extra_compile_args = exiv2_cfg['extra_compile_args'] + [
    '-O3', '-std=c++98', '-Wno-unused-variable', '-Wno-deprecated-declarations',
    '-Wno-unused-but-set-variable', '-Werror']
for file_name in os.listdir(mod_src_dir):
    if file_name[-9:] != '_wrap.cxx':
        continue
    ext_name = file_name[:-9]
    ext_modules.append(Extension(
        '_' + ext_name,
        sources = [os.path.join(mod_src_dir, file_name)],
        include_dirs = exiv2_cfg['include_dirs'],
        extra_compile_args = extra_compile_args,
        libraries = exiv2_cfg['libraries'],
        library_dirs = exiv2_cfg['library_dirs'],
        extra_link_args = exiv2_cfg['extra_link_args'],
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
