
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
__version__ = "0.17.1"
#: python-exiv2 version as a tuple of ints
__version_tuple__ = tuple((0, 17, 1))

__all__ = ["Exiv2Error"]
from exiv2.basicio import *
__all__ += exiv2._basicio.__all__
from exiv2.datasets import *
__all__ += exiv2._datasets.__all__
from exiv2.easyaccess import *
__all__ += exiv2._easyaccess.__all__
from exiv2.error import *
__all__ += exiv2._error.__all__
from exiv2.exif import *
__all__ += exiv2._exif.__all__
from exiv2.image import *
__all__ += exiv2._image.__all__
from exiv2.iptc import *
__all__ += exiv2._iptc.__all__
from exiv2.metadatum import *
__all__ += exiv2._metadatum.__all__
from exiv2.preview import *
__all__ += exiv2._preview.__all__
from exiv2.properties import *
__all__ += exiv2._properties.__all__
from exiv2.tags import *
__all__ += exiv2._tags.__all__
from exiv2.types import *
__all__ += exiv2._types.__all__
from exiv2.value import *
__all__ += exiv2._value.__all__
from exiv2.version import *
__all__ += exiv2._version.__all__
from exiv2.xmp import *
__all__ += exiv2._xmp.__all__

__all__ = [x for x in __all__ if x[0] != '_']
__all__.sort()
