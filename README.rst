python-exiv2 v\ 0.6.0
=====================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in libexiv2_, but with additional "Pythonic" helpers where necessary.
Not everything in libexiv2 is available in the Python interface.
If you need something that's not there, please let me know.

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
Here is an example of its use::

    Python 3.6.12 (default, Dec 02 2020, 09:44:23) [GCC] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import exiv2
    >>> image = exiv2.ImageFactory.open('IMG_0211.JPG')
    >>> image.readMetadata()
    >>> data = image.exifData()
    >>> data['Exif.Image.Artist']._print()
    'Jim Easterbrook'
    >>>

Documentation
-------------

The libexiv2_ library is well documented for C++ users, in Doxygen_ format.
Recent versions of SWIG_ can convert this documentation to pydoc_ format in the Python interface::

    $ pydoc3 exiv2.Image.exifData

    Help on method_descriptor in exiv2.Image:

    exiv2.Image.exifData = exifData(...)
        Returns an ExifData instance containing currently buffered
            Exif data.

        The contained Exif data may have been read from the image by
        a previous call to readMetadata() or added directly. The Exif
        data in the returned instance will be written to the image when
        writeMetadata() is called.

        :rtype: :py:class:`ExifData`
        :return: modifiable ExifData instance containing Exif values

Assignment
----------

libexiv2_ stores metadata values in a generalised container whose type can be set by the type of a value assigned to it, for example::

    // C or C++
    exifData["Exif.Image.SamplesPerPixel"] = uint16_t(162);

This forces the ``Exif.Image.SamplesPerPixel`` value to be an unsigned short.
Python doesn't have such specific integer types, so if you want to set the type you need to create an exiv2 value of the appropriate type and assign that::

    # Python
    exifData["Exif.Image.SamplesPerPixel"] = exiv2.UShortValue(162)

This allows you to set the value to any type, just like in C++, but the Python interface warns you if you set a type that isn't the default for that tag.
Alternatively you can use any Python object and let libexiv2_ convert the string representation of that object to the appropriate type::

    # Python
    exifData["Exif.Image.SamplesPerPixel"] = 162

Iterators
---------

Several libexiv2_ classes use C++ iterators to expose private data, for example the ``ExifData`` class has a private member of ``std::list<Exifdatum>`` type.
The classes have public ``begin`` and ``end`` methods that return ``std::list`` iterators.
In C++ you can dereference one of these iterators to access the ``Exifdatum`` object, but Python doesn't have a dereference operator.

This Python interface converts the ``std::list`` iterator to a Python object that has access to all the ``Exifdatum`` object's methods.
For example::

    Python 3.6.12 (default, Dec 02 2020, 09:44:23) [GCC] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import exiv2
    >>> image = exiv2.ImageFactory.open('IMG_0211.JPG')
    >>> image.readMetadata()
    >>> data = image.exifData()
    >>> b = data.begin()
    >>> b.key()
    'Exif.Image.ProcessingSoftware'
    >>>

The Python objects can be used to iterate over the data in a very C++ like style::

    >>> data = image.exifData()
    >>> b = data.begin()
    >>> e = data.end()
    >>> while b != e:
    ...     b.key()
    ...     next(b)
    ...
    'Exif.Image.ProcessingSoftware'
    <Swig Object of type 'ExifDataIterator *' at 0x7f2cbf6c2fb8>
    'Exif.Image.ImageDescription'
    <Swig Object of type 'ExifDataIterator *' at 0x7f2cbf6c2fb8>
    [skip 227 line pairs]
    'Exif.Thumbnail.JPEGInterchangeFormat'
    <Swig Object of type 'ExifDataIterator *' at 0x7f2cbf6c2fb8>
    'Exif.Thumbnail.JPEGInterchangeFormatLength'
    <Swig Object of type 'ExifDataIterator *' at 0x7f2cbf6c2fb8>
    >>>

The ``<Swig Object of type 'ExifDataIterator *' at 0x7f2cbf6c2fb8>`` lines are the Python interpreter showing the return value of ``next(b)``.
You can also iterate in a more Pythonic style::

    >>> data = image.exifData()
    >>> for datum in data:
    ...     datum.key()
    ...
    'Exif.Image.ProcessingSoftware'
    'Exif.Image.ImageDescription'
    [skip 227 lines]
    'Exif.Thumbnail.JPEGInterchangeFormat'
    'Exif.Thumbnail.JPEGInterchangeFormatLength'
    >>>

Warning: segmentation faults
----------------------------

It is easy to crash python-exiv2 if you delete objects which contain data that another object is pointing to.
For example, deleting an ``Image`` after extracting its metadata can cause a segfault when the metadata is accessed.
Ideally the Python interface to libexiv2 would use Python objects' reference counts to ensure this doesn't happen, preventing the deletion of the ``Image`` object until all references to it have been deleted.
Unfortunately I haven't found a sensible way to do this in the Python interface, so some care is needed when using it.

Error handling
--------------

libexiv2_ has a multilevel warning system a bit like Python's standard logger.
The Python interface redirects all Exiv2 messages to Python logging with an appropriate log level.
The ``exiv2.LogMsg.setLevel`` function can be used to control what severity of messages are logged.

Installation
------------

Python "wheels" are available for Windows (Python 3.5 to 3.9) and Linux & MacOS (Python 3.6 to 3.10).
These include the libexiv2 library and should not need any other software to be installed.
They can be installed with Python's pip_ package.
For example, on Windows::

    C:\Users\Jim>pip install python-exiv2

or on Linux or MacOS::

    $ sudo pip3 install python-exiv2

You can install for a single user with the ``--user`` option::

    $ pip3 install --user python-exiv2

If the available wheels are not compatible with your operating system then pip will download the python-exiv2 source and attempt to compile it.
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
.. _PyPI:              https://pypi.org/project/python-exiv2/
.. _SWIG:              http://swig.org/
.. _pydoc:             https://docs.python.org/3/library/pydoc.html
.. _Python3:           https://www.python.org/
.. _Visual C++:        https://wiki.python.org/moin/WindowsCompilers
