# python-exiv2 - Python interface to libexiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
import subprocess
import sys


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.check_output(cmd, universal_newlines=True).strip()
    except Exception as ex:
        print(str(ex))
        return None

def get_version(inc_dir):
    with open(os.path.join(inc_dir, 'exiv2', 'exv_conf.h')) as cnf:
        for line in cnf.readlines():
            words = line.split()
            if len(words) < 3:
                continue
            if words[0] == '#define' and words[1] == 'EXV_PACKAGE_VERSION':
                return [int(x) for x in eval(words[2]).split('.')]
    return [0, 0]

# get list of available swigged versions
swigged_versions = []
for name in os.listdir('src'):
    parts = name.split('_')
    if parts[0] == 'swig' and parts[1] not in swigged_versions:
        swigged_versions.append([int(x) for x in parts[1].split('.')])
swigged_versions.sort(reverse=True)

def get_mod_src_dir(exiv2_version):
    for version in swigged_versions:
        if exiv2_version + [0] >= version:
            return os.path.join('src', 'swig_{}.{}.{}'.format(*version))
    return None

mod_src_dir = None
platform = sys.platform
if platform == 'win32' and 'GCC' in sys.version:
    platform = 'mingw'

packages = ['exiv2', 'exiv2.examples']
package_dir = {'exiv2.examples': 'examples'}
package_data = {'exiv2.examples': ['*.py', '*.rst']}

if 'EXIV2_ROOT' in os.environ:
    # use local copy of libexiv2
    packages.append('exiv2.lib')
    package_dir['exiv2.lib'] = None
    include_dirs = []
    library_dirs = []
    for root, dirs, files in os.walk(os.path.normpath(os.environ['EXIV2_ROOT'])):
        for file in files:
            if file == 'exiv2.hpp':
                include_dirs = [os.path.dirname(root)]
                break
            if file == 'exiv2.mo':
                if 'exiv2.messages' not in packages:
                    # add exiv2.messages package for libexiv2 localisation files
                    packages.append('exiv2.messages')
                    package_dir['exiv2.messages'] = os.path.dirname(
                        os.path.dirname(root))
                    package_data['exiv2.messages'] = ['*/LC_MESSAGES/exiv2.mo']
                break
            if file in ('exiv2.lib', 'libexiv2.dll.a'):
                # win32, mingw, cygwin
                library_dirs = [root]
                break
            parts = file.split('.')
            if not (parts[0] in ('exiv2', 'libexiv2')
                    or parts[0].startswith('cygexiv2')):
                continue
            if len(parts) == 2 and parts[1] == 'dll':
                # win32, mingw, cygwin
                package_dir['exiv2.lib'] = root
                package_data['exiv2.lib'] = [file]
                break
            if len(parts) == 3 and (parts[1] == 'so' or parts[2] == 'dylib'):
                # linux, darwin
                library_dirs = [root]
                package_dir['exiv2.lib'] = root
                package_data['exiv2.lib'] = [file]
                break
        if (include_dirs and library_dirs and package_dir['exiv2.lib']
                and 'exiv2.messages' in packages):
            break
    if not (include_dirs and library_dirs and package_dir['exiv2.lib']):
        print('ERROR: Include and library files not found')
        sys.exit(1)
    # get exiv2 version from include files
    exiv2_version = get_version(include_dirs[0])
    mod_src_dir = get_mod_src_dir(exiv2_version)
    if platform == 'linux':
        extra_link_args = ['-Wl,-rpath,$ORIGIN/lib']
    elif platform == 'darwin':
        extra_link_args = ['-Wl,-rpath,@loader_path/lib']
    else:
        extra_link_args = []
else:
    # use installed libexiv2
    exiv2_version = pkg_config('exiv2', 'modversion')
    if exiv2_version:
        exiv2_version = [int(x) for x in exiv2_version.split('.')]
        mod_src_dir = get_mod_src_dir(exiv2_version)
        if mod_src_dir:
            library_dirs = pkg_config('exiv2', 'libs-only-L').split('-L')
            library_dirs = [x.strip() for x in library_dirs]
            library_dirs = [x.replace(r'\ ', ' ') for x in library_dirs if x]
            include_dirs = pkg_config('exiv2', 'cflags-only-I').split('-I')
            include_dirs = [x.strip() for x in include_dirs]
            include_dirs = [x.replace(r'\ ', ' ') for x in include_dirs if x]
            extra_link_args = []

if not mod_src_dir:
    print('ERROR: No SWIG source for libexiv2 version {}'.format(exiv2_version))
    sys.exit(1)

print('Using libexiv2 v{} with SWIG files from {}'.format(
    '.'.join(map(str, exiv2_version)), mod_src_dir))

package_dir['exiv2'] = mod_src_dir

# create extension modules list
ext_modules = []
extra_compile_args = []
if platform in ('linux', 'darwin', 'mingw'):
    extra_compile_args = [
        '-O3', '-Wno-unused-variable', '-Wno-unused-function',
        '-Wno-deprecated-declarations', '-Wno-deprecated']
    if platform in ['linux', 'mingw']:
        extra_compile_args.append('-Wno-unused-but-set-variable')
    if 'PYTHON_EXIV2_STRICT' in os.environ:
        extra_compile_args.append('-Werror')
    if exiv2_version >= [1, 0]:
        extra_compile_args.append('-std=gnu++17')
    else:
        extra_compile_args.append('-std=c++98')
if platform == 'win32':
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
        define_macros = [('PY_SSIZE_T_CLEAN', None)],
        libraries = ['exiv2'],
        library_dirs = library_dirs,
        extra_link_args = extra_link_args,
        ))

# set options for building source distributions
command_options = {}
command_options['sdist'] = {
    'formats' : ('setup.py', 'zip'),
    }

with open('README.rst') as ldf:
    long_description = ldf.read()
py_exiv2_version = long_description.splitlines()[0].split()[-1]

setup(name = 'exiv2',
      version = py_exiv2_version,
      description = 'Python interface to libexiv2',
      long_description = long_description,
      author = 'Jim Easterbrook',
      author_email = 'jim@jim-easterbrook.me.uk',
      url = 'https://github.com/jim-easterbrook/python-exiv2',
      classifiers = [
          'Development Status :: 4 - Beta',
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
      platforms = ['POSIX', 'MacOS', 'Windows'],
      license = 'GNU GPL',
      command_options = command_options,
      ext_package = 'exiv2',
      ext_modules = ext_modules,
      packages = packages,
      package_dir = package_dir,
      package_data = package_data,
      zip_safe = False,
      )
