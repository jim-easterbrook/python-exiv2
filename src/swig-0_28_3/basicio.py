# This file was automatically generated by SWIG (https://www.swig.org).
# Version 4.2.1
#
# Do not make changes to this file unless you know what you are doing - modify
# the SWIG interface file instead.

from sys import version_info as _swig_python_version_info
import exiv2.types

# Pull in all the attributes from the low-level C/C++ module
if __package__ or "." in __name__:
    from ._basicio import *
else:
    from _basicio import *


import enum

class PositionMeta(enum.EnumMeta):
    def __getattribute__(cls, name):
        obj = super().__getattribute__(name)
        if isinstance(obj, enum.Enum):
            import warnings
            warnings.warn(
                "Use 'BasicIo.Position' instead of 'Position'",
                DeprecationWarning)
        return obj

class DeprecatedPosition(enum.IntEnum, metaclass=PositionMeta):
    pass

Position = DeprecatedPosition('Position', _enum_list_Position())
Position.__doc__ = "Seek starting positions."

