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

import subprocess


def pkg_config(library, option):
    cmd = ['pkg-config', '--' + option, library]
    try:
        return subprocess.check_output(cmd, universal_newlines=True).split()
    except Exception:
        error('ERROR: command "%s" failed', ' '.join(cmd))
        raise


exiv2_cfg = {
    'version': pkg_config('exiv2', 'modversion')[0].split('.'),
    'include_dirs': [x[2:] for x in pkg_config('exiv2', 'cflags-only-I')],
    'extra_compile_args': pkg_config('exiv2', 'cflags-only-other'),
    'libraries': [x[2:] for x in pkg_config('exiv2', 'libs-only-l')],
    'library_dirs': [x[2:] for x in pkg_config('exiv2', 'libs-only-L')],
    'extra_link_args': pkg_config('exiv2', 'libs-only-other'),
    }
