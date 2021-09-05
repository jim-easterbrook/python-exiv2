
import logging
import sys

if sys.platform == 'linux':
    import os
    _lib = os.path.join(os.path.dirname(__file__), 'libexiv2.so')
    if os.path.exists(_lib):
        # import libexiv2 shared library (avoids setting LD_LIBRARY_PATH)
        from ctypes import cdll
        cdll.LoadLibrary(_lib)

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

__version__ = "0.2.2"

from exiv2.datasets import *
from exiv2.error import *
from exiv2.exif import *
from exiv2.image import *
from exiv2.iptc import *
from exiv2.metadatum import *
from exiv2.properties import *
from exiv2.tags import *
from exiv2.types import *
from exiv2.value import *
from exiv2.version import *
from exiv2.xmp import *

__all__ = [x for x in dir() if x[0] != '_']
