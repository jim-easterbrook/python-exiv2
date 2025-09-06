# python-exiv2 - Python interface to exiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2025  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This file is part of python-exiv2.
#
# python-exiv2 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# python-exiv2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with python-exiv2.  If not, see <http://www.gnu.org/licenses/>.

import enum
import warnings

from exiv2._enum_data import enum_data

class DeprecatedEnumMeta(enum.EnumMeta):
    def __getattribute__(cls, name):
        obj = super().__getattribute__(name)
        if isinstance(obj, enum.IntEnum):
            warnings.warn(cls._msg, DeprecationWarning, 2)
        return obj

class DeprecatedEnum(enum.IntEnum, metaclass=DeprecatedEnumMeta):
    pass

def _deprecated_enum(name, moved_to, new_enum):
    result = DeprecatedEnum(name, new_enum.__members__)
    result._msg = f"Use '{moved_to}.{name}' instead of '{name}'"
    return result

def _create_enum(module, name, alias_strip, members):
    data = enum_data[name]
    if alias_strip:
        alias_strip = int(alias_strip)
        members += [(k[alias_strip:], v) for (k, v) in members]
    result = enum.IntEnum(name.split('::')[-1], members)
    result.__module__ = 'exiv2.' + module[1:]
    if data['doc']:
        result.__doc__ = data['doc']
    for key, value in data['values'].items():
        if value['doc']:
            result[key].__doc__ = value['doc']
    return result

