
import logging
import os
import sys
import warnings

if sys.platform == 'win32':
    _dir = os.path.join(os.path.dirname(__file__), 'lib')
    if os.path.isdir(_dir):
        if hasattr(os, 'add_dll_directory'):
            os.add_dll_directory(_dir)
        os.environ['PATH'] = _dir + ';' + os.environ['PATH']

_logger = logging.getLogger(__name__)

class Exiv2Error(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

if sys.version_info < (3, 7):
    # provide old AnyError for compatibility
    AnyError = Exiv2Error
else:
    # issue deprecation warning if user imports AnyError
    def __getattr__(name):
        if name == 'AnyError':
            warnings.warn("Please replace 'AnyError' with 'Exiv2Error'",
                          DeprecationWarning)
            return Exiv2Error
        raise AttributeError

__version__ = "0.13.0"

from exiv2.basicio import *
from exiv2.datasets import *
from exiv2.easyaccess import *
from exiv2.error import *
from exiv2.exif import *
from exiv2.image import *
from exiv2.iptc import *
from exiv2.metadatum import *
from exiv2.preview import *
from exiv2.properties import *
from exiv2.tags import *
from exiv2.types import *
from exiv2.value import *
from exiv2.version import *
from exiv2.xmp import *

_dir = os.path.join(os.path.dirname(__file__), 'messages')
if os.path.isdir(_dir):
    exiv2.types._set_locale_dir(_dir)

__all__ = [x for x in dir() if x[0] != '_']
