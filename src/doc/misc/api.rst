.. This is part of the python-exiv2 documentation.
   Copyright (C)  2024  Jim Easterbrook.

Detailed API
============

This part of the documentation is auto-generated from the Doxygen_ format documentation in the libexiv2 "header" files.
There are many ways in which the conversion process can fail, so you may need to consult the `Exiv2 C++ API`_ documentation as well.

The documentation is split into several pages, one for each module in the Python interface.
This makes it easier to use than having all the classes and functions in one document.
Do not use the module names in your Python scripts: always use ``exiv2.name`` rather than ``exiv2.module.name`` or ``exiv2._module.name``.

See :ref:`genindex` for a full index to all classes, attributes, functions and methods.

.. autosummary::
   :toctree: ../api
   :recursive:
   :template: module.rst

   exiv2._image
   exiv2._exif
   exiv2._iptc
   exiv2._xmp
   exiv2._preview
   exiv2._value
   exiv2._types
   exiv2._tags
   exiv2._datasets
   exiv2._properties
   exiv2._version
   exiv2._error
   exiv2._easyaccess
   exiv2._basicio
   exiv2._metadatum

.. _Doxygen: https://www.doxygen.nl/
.. _Exiv2 C++ API: https://exiv2.org/doc/index.html
