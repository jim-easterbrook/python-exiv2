# python-exiv2 - Python interface to exiv2
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

import os
import re
import shutil
import subprocess
import sys
import tempfile


def get_version(incl_dir):
    with open(os.path.join(incl_dir, 'exv_conf.h')) as cnf:
        for line in cnf.readlines():
            words = line.split()
            if len(words) < 3:
                continue
            if words[0] == '#define' and words[1] == 'EXV_PACKAGE_VERSION':
                version = [int(x) for x in eval(words[2]).split('.')]
                return tuple(version + [0, 0])
    return 0, 0, 0, 0


def main():
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
    if swig_version < (4, 1, 0):
        print('SWIG version 4.1.0 or later required')
        return 1
    # get source to SWIG
    if len(sys.argv) != 2:
        print('Usage: %s path' % sys.argv[0])
        return 1
    # get config
    platform = sys.platform
    if platform == 'win32' and 'GCC' in sys.version:
        platform = 'mingw'
    incl_dir = os.path.normpath(sys.argv[1])
    if os.path.basename(incl_dir) != 'exiv2':
        incl_dir = os.path.join(incl_dir, 'exiv2')
    if not os.path.isdir(incl_dir):
        print('Directory %s not found' % incl_dir)
        return 2
    if 'exiv2.hpp' not in os.listdir(incl_dir):
        print('Exiv2 header files not found in %s' % incl_dir)
        return 3
    # get exiv2 version
    exiv2_version = get_version(incl_dir)
    # get exiv2 build options
    options = {}
    with open(os.path.join(incl_dir, 'exv_conf.h')) as cnf:
        for line in cnf.readlines():
            words = line.split()
            if len(words) < 2:
                continue
            if words[0] == '#define' and words[1].startswith('EXV_'):
                options[words[1]] = ' '.join(words[2:]) or None
    # get python-exiv2 version
    with open('README.rst') as rst:
        py_exiv2_version = rst.readline().split()[-1]
    # get list of modules (Python) and extensions (SWIG)
    interface_dir = os.path.join('src', 'interface')
    file_names = os.listdir(interface_dir)
    file_names.sort()
    file_names = [os.path.splitext(x) for x in file_names]
    mod_names = [x[0] + x[1] for x in file_names if x[1] == '.py']
    ext_names = [x[0] for x in file_names if x[1] == '.i']
    # convert exiv2 version to hex
    exiv2_version_hex = '0x{:02x}{:02x}{:02x}{:02x}'.format(*exiv2_version)
    # create output dir
    output_dir = os.path.join('src', 'swig-{}_{}_{}'.format(*exiv2_version))
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    # copy Python modules
    for mod_name in mod_names:
        shutil.copy2(os.path.join('src', 'interface', mod_name),
                     os.path.join(output_dir, mod_name))
    # pre-process include files to a temporary directory
    subst = {
        'basicio.hpp': [('/*isWriteable*/', 'isWriteable')],
        'image.hpp': [('getType(const byte* data, size_t size',
                       'getType(const byte* data, size_t A'),
                      ('getType(const byte* data, long size',
                       'getType(const byte* data, long A'),
                      ('open(const byte* data, size_t size',
                       'open(const byte* data, size_t B'),
                      ('open(const byte* data, long size',
                       'open(const byte* data, long B'),
                      ('/*! @brief', '/*!\n    @brief')],
        'metadatum.hpp': [('toString(size_t n)', 'toString(size_t i)'),
                          ('toString(long n)', 'toString(long i)')],
        'preview.hpp': [('_{};', '_;')],
        }
    for key in ('exif.hpp', 'iptc.hpp', 'value.hpp',
                'xmp.hpp', 'xmp_exiv2.hpp'):
        subst[key] = subst['metadatum.hpp']
    if swig_version < (4, 2, 0):
        subst['basicio.hpp'].append(('static constexpr auto',
                                     'static const char*'))
    with tempfile.TemporaryDirectory() as copy_dir:
        dest = os.path.join(copy_dir, 'exiv2')
        os.makedirs(dest)
        for file in os.listdir(incl_dir):
            if file in subst:
                with open(os.path.join(incl_dir, file), 'r') as in_file:
                    with open(os.path.join(dest, file), 'w') as out_file:
                        for line in in_file.readlines():
                            for from_to in subst[file]:
                                line = line.replace(*from_to)
                            out_file.write(line)
            else:
                shutil.copy(os.path.join(incl_dir, file),
                            os.path.join(dest, file))
        # make options list
        swig_opts = ['-c++', '-python', '-builtin', '-doxygen',
                     '-fastdispatch', '-fastproxy', '-Wextra', '-Werror',
                     '-DEXIV2_VERSION_HEX=' + exiv2_version_hex]
        for k, v in options.items():
            if v is None:
                swig_opts.append('-D{}'.format(k))
            else:
                swig_opts.append('-D{}={}'.format(k, v))
        swig_opts += ['-I' + copy_dir, '-outdir', output_dir]
        # do each swig module
        for ext_name in ext_names:
            cmd = ['swig'] + swig_opts
            # Functions with just one parameter and a default value don't
            # work with fastunpack.
            # See https://github.com/swig/swig/issues/2786
            if swig_version < (4, 4, 0) and ext_name in (
                    'basicio', 'exif', 'iptc', 'metadatum', 'value', 'xmp'):
                cmd.append('-nofastunpack')
            cmd += ['-o', os.path.join(output_dir, ext_name + '_wrap.cxx')]
            cmd += [os.path.join(interface_dir, ext_name + '.i')]
            print(' '.join(cmd))
            subprocess.check_call(cmd)
    # create init module
    init_file = os.path.join(output_dir, '__init__.py')
    with open(init_file, 'w') as im:
        im.write(f'''
import os
import sys

if sys.platform == 'win32':
    _dir = os.path.join(os.path.dirname(__file__), 'lib')
    if os.path.isdir(_dir):
        if hasattr(os, 'add_dll_directory'):
            os.add_dll_directory(_dir)
        os.environ['PATH'] = _dir + ';' + os.environ['PATH']

class Exiv2Error(Exception):
    """Python exception raised by exiv2 library errors.

    :ivar ErrorCode code: The Exiv2 error code that caused the exception.
    :ivar str message: The message associated with the exception.
    """
    def __init__(self, code, message):
        self.code= code
        self.message = message

#: python-exiv2 version as a string
__version__ = "{py_exiv2_version}"
#: python-exiv2 version as a tuple of ints
__version_tuple__ = tuple(({', '.join(re.split(r'[-.]', py_exiv2_version))}))

__all__ = ["Exiv2Error"]
''')
        for name in ext_names:
            im.write(f'from exiv2.{name} import *\n')
            im.write(f'__all__ += exiv2._{name}.__all__\n')
        im.write("""
__all__ = [x for x in __all__ if x[0] != '_']
__all__.sort()
""")
    # update ReadTheDocs config
    with open('src/doc/requirements.txt', 'w') as f:
        f.write(f'''exiv2 <= {py_exiv2_version}
sphinx == 7.2.6
sphinx-rtd-theme == 2.0.0
''')
    return 0


if __name__ == "__main__":
    sys.exit(main())
