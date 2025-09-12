.. This is part of the python-exiv2 documentation.
   Copyright (C)  2024-25  Jim Easterbrook.

Detailed API
============

This part of the documentation is auto-generated from the Doxygen_ format documentation in the libexiv2 "header" files.
There are many ways in which the conversion process can fail, so you may need to consult the `Exiv2 C++ API`_ documentation as well.

The documentation is split into several pages, one for each module in the Python interface.
This makes it easier to use than having all the classes and functions in one document.
Do not use the module names in your Python scripts: always use ``exiv2.name`` rather than ``exiv2.module.name`` or ``exiv2._module.name``.

See :ref:`genindex` for a full index to all classes, attributes, functions and methods.

.. rubric:: Package Attributes

.. autosummary::

   exiv2.__version__
   exiv2.__version_tuple__

.. rubric:: Package Modules

.. autosummary::
   :toctree: ../api
   :recursive:

   exiv2.image
   exiv2.exif
   exiv2.iptc
   exiv2.xmp
   exiv2.preview
   exiv2.value
   exiv2.types
   exiv2.tags
   exiv2.datasets
   exiv2.properties
   exiv2.version
   exiv2.error
   exiv2.easyaccess
   exiv2.basicio
   exiv2.metadatum
   exiv2.extras

.. _Doxygen: https://www.doxygen.nl/
.. _Exiv2 C++ API: https://exiv2.org/doc/index.html
