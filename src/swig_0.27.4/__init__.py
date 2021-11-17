
import logging
import sys

if sys.platform == 'win32':
    import os
    _dir = os.path.join(os.path.dirname(__file__), 'lib')
    if os.path.isdir(_dir):
        if hasattr(os, 'add_dll_directory'):
            os.add_dll_directory(_dir)
        os.environ['PATH'] = _dir + ';' + os.environ['PATH']

_logger = logging.getLogger(__name__)

class AnyError(Exception):
    """Python exception raised by exiv2 library errors"""
    pass

__version__ = "0.8.2"

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

__all__ = [x for x in dir() if x[0] != '_']
