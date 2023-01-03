python-exiv2 v\ 0.13.0
======================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in libexiv2_, but with additional "Pythonic" helpers where necessary.
Not everything in libexiv2 is available in the Python interface.
If you need something that's not there, please let me know.

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
    >>> data['Exif.Image.Artist']._print()
    'Jim Easterbrook'
    >>>

Please see `<USAGE.rst>`_ for more help with using the Python interface to libexiv2.

Deprecation warnings
--------------------

As python-exiv2 is being developed better ways are being found to do some things.
Some parts of the interface are deprecated and will eventually be removed.
Please use Python's ``-Wd`` flag when testing your software to ensure it isn't using deprecated features.
(Do let me know if I've deprecated a feature you need and can't replace with an alternative.)

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

Unfortunately some documentation gets lost in the manipulations needed to make a useful interface.
The C++ documentation is still needed in these cases.

Support for bmff files (CR3, HEIF, HEIC, and AVIF)
--------------------------------------------------

Python-exiv2 from version 0.8.3 onwards is built with support for bmff files.
In order to use bmff files in your Python program you need to call the ``enableBMFF`` function.
Please read the Exiv2 `statement on bmff`_ patents before doing so.

Assignment
----------

libexiv2_ stores metadata values in a generalised container whose type can be set by the type of a value assigned to it, for example:

.. code:: C++

    // C or C++
    exifData["Exif.Image.SamplesPerPixel"] = uint16_t(162);

This forces the ``Exif.Image.SamplesPerPixel`` value to be an unsigned short.
Python doesn't have such specific integer types, so if you need to set the type you can create an exiv2 value of the appropriate type and assign that:

.. code:: python

    # Python
    exifData["Exif.Image.SamplesPerPixel"] = exiv2.UShortValue(162)

This allows you to set the value to any type, just like in C++, but the Python interface warns you if you set a type that isn't the default for that tag.
Alternatively you can use any Python object and let libexiv2_ convert the string representation of that object to the appropriate type:

.. code:: python

    # Python
    exifData["Exif.Image.SamplesPerPixel"] = 162

Error handling
--------------

libexiv2_ has a multilevel warning system a bit like Python's standard logger.
The Python interface redirects all Exiv2 messages to Python logging with an appropriate log level.
The ``exiv2.LogMsg.setLevel`` function can be used to control what severity of messages are logged.

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
For more information, and details of how to compile python-exiv2 and libexiv2, see `<INSTALL.rst>`_.

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
.. _statement on bmff: https://github.com/exiv2/exiv2#2-19
.. _Visual C++:        https://wiki.python.org/moin/WindowsCompilers
