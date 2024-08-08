# python-exiv2 - Python interface to libexiv2
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

from setuptools import setup, Extension
from setuptools import __version__ as setuptools_version
import os
import re
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
    parts = name.split('-')
    if parts[0] == 'swig' and parts[1] not in swigged_versions:
        swigged_versions.append([int(x) for x in parts[1].split('_')])
    swigged_versions.sort()

def get_mod_src_dir(exiv2_version):
    if len(exiv2_version) < 3:
        exiv2_version += [0]
    swigged_versions.sort()
    for v in swigged_versions:
        if v >= exiv2_version and v[:2] == exiv2_version[:2]:
            return os.path.join('src', 'swig-{}_{}_{}'.format(*v))
    swigged_versions.sort(reverse=True)
    for v in swigged_versions:
        if v[:2] == exiv2_version[:2]:
            return os.path.join('src', 'swig-{}_{}_{}'.format(*v))
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
    exiv2_root = os.path.normpath(os.environ['EXIV2_ROOT'])
    # header files
    path = os.path.join(exiv2_root, 'include')
    if not os.path.isfile(os.path.join(path, 'exiv2', 'exiv2.hpp')):
        print('ERROR: Include files not found')
        sys.exit(1)
    include_dirs = [path]
    # library files
    packages.append('exiv2.lib')
    if platform == 'linux':
        path = os.path.join(exiv2_root, 'lib64')
        if not os.path.exists(path):
            path = os.path.join(exiv2_root, 'lib')
        library_dirs = [path]
        package_dir['exiv2.lib'] = path
        package_data['exiv2.lib'] = [x for x in os.listdir(path)
                                     if re.fullmatch('libexiv2\.so\.\d+', x)]
    elif platform == 'darwin':
        path = os.path.join(exiv2_root, 'lib')
        library_dirs = [path]
        package_dir['exiv2.lib'] = path
        package_data['exiv2.lib'] = [x for x in os.listdir(path)
                                     if re.fullmatch('libexiv2\.\d+\.dylib', x)]
    elif platform in ('win32', 'mingw'):
        library_dirs = [os.path.join(exiv2_root, 'lib')]
        package_dir['exiv2.lib'] = os.path.join(exiv2_root, 'bin')
        package_data['exiv2.lib'] = ['*.dll']
    if not os.path.isdir(package_dir['exiv2.lib']):
        print('ERROR: Library files not found')
        sys.exit(1)
    # locale files
    path = os.path.join(exiv2_root, 'share', 'locale')
    if not os.path.isdir(path):
        print('WARNING: Locale files not found')
    else:
        packages.append('exiv2.locale')
        package_dir['exiv2.locale'] = path
        package_data['exiv2.locale'] = ['*/LC_MESSAGES/exiv2.mo']
        for name in os.listdir(path):
            if os.path.isfile(os.path.join(
                    path, name, 'LC_MESSAGES', 'exiv2.mo')):
                packages.append('exiv2.locale.' + name + '.' + 'LC_MESSAGES')
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
define_macros = [('PY_SSIZE_T_CLEAN', None),
                 ('SWIG_TYPE_TABLE', 'exiv2')]
if platform in ('linux', 'darwin', 'mingw'):
    extra_compile_args = [
        '-O3', '-Wno-unused-variable', '-Wno-unused-function',
        '-Wno-deprecated-declarations', '-Wno-deprecated']
    if platform in ['linux', 'mingw']:
        extra_compile_args.append('-Wno-unused-but-set-variable')
    if 'PYTHON_EXIV2_STRICT' in os.environ:
        extra_compile_args.append('-Werror')
    if exiv2_version >= [0, 28]:
        extra_compile_args.append('-std=gnu++17')
    else:
        extra_compile_args.append('-std=c++98')
if platform == 'win32':
    extra_compile_args = ['/wd4101', '/wd4290']
if platform == 'darwin':
    cmd = ['brew', '--prefix']
    try:
        prefix = subprocess.check_output(cmd, universal_newlines=True).strip()
        include_dirs.append(os.path.join(prefix, 'include'))
        library_dirs.append(os.path.join(prefix, 'lib'))
    except Exception as ex:
        print(str(ex))
for file_name in os.listdir(mod_src_dir):
    if file_name[-9:] != '_wrap.cxx':
        continue
    ext_name = file_name[:-9]
    ext_modules.append(Extension(
        '_' + ext_name,
        sources = [os.path.join(mod_src_dir, file_name)],
        include_dirs = include_dirs,
        extra_compile_args = extra_compile_args,
        define_macros = define_macros,
        libraries = ['exiv2'],
        library_dirs = library_dirs,
        extra_link_args = extra_link_args,
        ))

setup_kwds = {
    'ext_package': 'exiv2',
    'ext_modules': ext_modules,
    'packages': packages,
    'package_dir': package_dir,
    'package_data': package_data,
    'exclude_package_data': {'exiv2': ['*.cxx']},
    }

if tuple(map(int, setuptools_version.split('.')[:2])) < (61, 0):
    # get metadata from pyproject.toml
    import toml
    metadata = toml.load('pyproject.toml')

    with open(metadata['project']['readme']) as ldf:
        long_description = ldf.read()
    py_exiv2_version = long_description.splitlines()[0].split()[-1]

    setup_kwds.update(
        name = metadata['project']['name'],
        version = py_exiv2_version,
        description = metadata['project']['description'],
        long_description = long_description,
        author = metadata['project']['authors'][0]['name'],
        author_email = metadata['project']['authors'][0]['email'],
        url = metadata['project']['urls']['Homepage'],
        classifiers = metadata['project']['classifiers'],
        platforms = metadata['tool']['setuptools']['platforms'],
        license = metadata['project']['license']['text'],
        zip_safe = metadata['tool']['setuptools']['zip-safe'],
        )

setup(**setup_kwds)
