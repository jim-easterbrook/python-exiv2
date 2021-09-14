
import logging
import sys

if sys.platform == 'win32' and 'GCC' not in sys.version:
    import os
    _dir = os.path.join(os.path.dirname(__file__), 'lib')
    if hasattr(os, 'add_dll_directory'):
        os.add_dll_directory(_dir)
    else:
        os.environ['PATH'] = _dir + ';' + os.environ['PATH']

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

__version__ = "0.3.2"

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
