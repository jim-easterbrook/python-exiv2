python-exiv2 v\ 0.17.1
======================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in libexiv2_, but with additional "Pythonic" helpers where necessary.
Not everything in libexiv2 is available in the Python interface.
If you need something that's not there, please let me know.

.. note::
    This project has taken over the PyPI exiv2 package created by Michael Vanslembrouck.
    If you need to use Michael's project, it is available at https://bitbucket.org/zmic/exiv2-python/src/master/ and can be installed with pip_::

        pip install exiv2==0.3.1

.. contents::
    :backlinks: top

Introduction
------------

There are several other ways to access libexiv2_ from within Python.
The first one I used was `pyexiv2 (old)`_.
After its development ceased I moved on to using gexiv2_ and PyGObject_.
This works well, providing a ``Metadata`` object with high level functions such as ``set_tag_string`` and ``set_tag_multiple`` to get and set metadata values.

A more recent development is `pyexiv2 (new)`_.
This new project is potentially very useful, providing a simple interface with functions to read and modify metadata using Python ``dict`` parameters.

For more complicated metadata operations I think a lower level interface is required, which is where this project comes in.
Here is an example of its use:

.. code:: python

    Python 3.6.12 (default, Dec 02 2020, 09:44:23) [GCC] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import exiv2
    >>> image = exiv2.ImageFactory.open('IMG_0211.JPG')
    >>> image.readMetadata()
    >>> data = image.exifData()
    >>> data['Exif.Image.Artist'].print()
    'Jim Easterbrook'
    >>>

Please see `USAGE.rst`_ for more help with using the Python interface to libexiv2.

Transition to libexiv2 v0.28.x
------------------------------

Before python-exiv2 v0.16 the "binary wheels" available from PyPI_ incorporated libexiv2 v0.27.7 or earlier.
Binary wheels for python-exiv2 v0.16.3 incorporate libexiv2 v0.28.2, and those for python-exiv2 v0.16.2 incorporate libexiv2 v0.27.7.
Binary wheels for python-exiv2 v0.17.0 incorporate libexiv2 v0.28.3.
If your software is currently incompatible with libexiv2 v0.28.x you can use the older version of libexiv2 by explicitly installing python-exiv2 v0.16.2::

    $ pip install --user exiv2==0.16.2

There are some changes in the libexiv2 API between v0.27.7 and v0.28.x.
Future versions of python-exiv2 will all incorporate libexiv2 v0.28.x, so please update your software to use the changed API.

Documentation
-------------

The libexiv2_ library is well documented for C++ users, in Doxygen_ format.
Recent versions of SWIG_ can convert this documentation to pydoc_ format in the Python interface::

    $ pydoc3 exiv2.Image.readMetadata
    Help on method_descriptor in exiv2.Image:

    exiv2.Image.readMetadata = readMetadata(...)
        Read all metadata supported by a specific image format from the
            image. Before this method is called, the image metadata will be
            cleared.

        This method returns success even if no metadata is found in the
        image. Callers must therefore check the size of individual metadata
        types before accessing the data.

        :raises: Error if opening or reading of the file fails or the image
                data is not valid (does not look like data of the specific image
                type).

This is then converted to web pages by Sphinx_ and hosted on ReadTheDocs_.

Unfortunately some documentation gets lost in the manipulations needed to make a useful interface.
The C++ documentation is still needed in these cases.

Support for bmff files (e.g. CR3, HEIF, HEIC, AVIF, JPEG XL)
------------------------------------------------------------

Python-exiv2 from version 0.17.0 has support for BMFF files enabled by default if libexiv2 was compiled with support for BMFF files enabled.
In earlier versions you need to call the ``enableBMFF`` function before using BMFF files in your program.
Use of BMFF files may infringe patents.
Please read the Exiv2 `statement on BMFF`_ patents before doing so.

Installation
------------

Python "binary wheels" are available for Windows, Linux, and MacOS.
These include the libexiv2 library and should not need any other software to be installed.
They can be installed with Python's pip_ package.
For example, on Windows::

    C:\Users\Jim>pip install exiv2

or on Linux or MacOS::

    $ pip3 install --user exiv2

If the available wheels are not compatible with your operating system or Python version then pip will download the python-exiv2 source and attempt to compile it.
For more information, and details of how to compile python-exiv2 and libexiv2, see `INSTALL.rst`_.

Problems?
---------

Please email jim@jim-easterbrook.me.uk if you find any problems (or solutions!).

.. _Doxygen:           https://www.doxygen.nl/
.. _exiv2:             https://www.exiv2.org/getting-started.html
.. _gexiv2:            https://wiki.gnome.org/Projects/gexiv2
.. _GitHub:            https://github.com/jim-easterbrook/python-exiv2
.. _libexiv2:          https://www.exiv2.org/doc/index.html
.. _pip:               https://pip.pypa.io/
.. _pyexiv2 (new):     https://github.com/LeoHsiao1/pyexiv2
.. _pyexiv2 (old):     https://launchpad.net/pyexiv2
.. _PyGObject:         https://pygobject.readthedocs.io/en/latest/
.. _PyPI:              https://pypi.org/project/exiv2/
.. _SWIG:              http://swig.org/
.. _pydoc:             https://docs.python.org/3/library/pydoc.html
.. _Python3:           https://www.python.org/
.. _ReadTheDocs:       https://python-exiv2.readthedocs.io/
.. _Sphinx:            https://www.sphinx-doc.org/
.. _statement on BMFF: https://github.com/exiv2/exiv2#BMFF
.. _Visual C++:        https://wiki.python.org/moin/WindowsCompilers
.. _INSTALL.rst:       INSTALL.rst
.. _USAGE.rst:         USAGE.rst
