python-exiv2 v\ 0.1.0
=====================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in libexiv2_, but with additional "Pythonic" helpers where necessary.

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

**This project is at an early stage of development.**
I've managed to get it to build and run with libexiv2_ v0.26 and v0.27.4 on Linux, and v0.27.4 on Windows.
Here is an example of what it can do::

    Python 3.6.12 (default, Dec 02 2020, 09:44:23) [GCC] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import exiv2
    >>> image = exiv2.ImageFactory.open('IMG_0211.JPG')
    >>> image.readMetadata()
    >>> data = image.exifData()
    >>> data['Exif.Image.Artist']._print()
    'Jim Easterbrook'
    >>>

There's still a lot to be done:

    * Package for PyPI_.
    * Create "wheels" for different Python versions.
    * More example files.

Documentation
-------------

The libexiv2_ library is well documented for C++ users, in Doxygen_ format.
Recent versions of SWIG_ can convert this documentation to pydoc_ format in the Python interface::

    pydoc3 exiv2.Image.exifData

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

    exifData["Exif.Image.SamplesPerPixel"] = uint16_t(162);

This forces the ``Exif.Image.SamplesPerPixel`` value to be an unsigned short.
Python doesn't have such specific integer types, so if you want to set the type you need to create an exiv2 value of the appropriate type and assign that::

    exifData["Exif.Image.SamplesPerPixel"] = exiv2.UShortValue(162)

This allows you to set the value to any type, just like in C++, but the Python interface warns you if you set a type that isn't the default for that tag.
Otherwise you can set the value to any Python object and let libexiv2_ convert the string representation of that object to the appropriate type::

    exifData["Exif.Image.SamplesPerPixel"] = 162

Iterators
---------

Several libexiv2_ classes use C++ iterators to expose private data, for example the ``ExifData`` class has a private member of ``std::list<Exifdatum>`` type.
The classes have public ``begin`` and ``end`` methods that return ``std::list`` iterators.
In C++ you can dereference one of these iterators to access the ``Exifdatum`` object, but Python doesn't have a dereference operator.

This Python interface converts the ``std::list`` iterator to a Python object that has a ``curr`` method to return the list value.
It is quite easy to use::

    Python 3.6.12 (default, Dec 02 2020, 09:44:23) [GCC] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import exiv2
    >>> image = exiv2.ImageFactory.open('IMG_0211.JPG')
    >>> image.readMetadata()
    >>> data = image.exifData()
    >>> b = data.begin()
    >>> b.curr().key()
    'Exif.Image.ProcessingSoftware'
    >>>

The Python iterators also have a ``next`` method that increments the iterator as well as returning the list value.
This can be used to iterate over the data in a very C++ like style::

    >>> data = image.exifData()
    >>> b = data.begin()
    >>> e = data.end()
    >>> while b != e:
    ...     b.next().key()
    ...
    'Exif.Image.ProcessingSoftware'
    'Exif.Image.ImageDescription'
    [skip 227 lines]
    'Exif.Thumbnail.JPEGInterchangeFormat'
    'Exif.Thumbnail.JPEGInterchangeFormatLength'
    >>>

You can also iterate in a more Pythonic style::

    >>> data = image.exifData()
    >>> for item in data:
    ...     item.key()
    ...
    'Exif.Image.ProcessingSoftware'
    'Exif.Image.ImageDescription'
    [skip 227 lines]
    'Exif.Thumbnail.JPEGInterchangeFormat'
    'Exif.Thumbnail.JPEGInterchangeFormatLength'
    >>>

I think this is much better.

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

Dependencies
------------

Eventually you will be able to install python-exiv2 with a single ``pip install exiv2`` command on many computers.
Until then the only way to install python-exiv2 is to compile it from source.
This requires the "development headers" of Python3_, and an appropriate compiler & linker (GNU C++ on Linux, `Visual C++`_ on Windows).
You will also need a pre-built libexiv2_, either the one provided with your operating system, or one downloaded from https://www.exiv2.org/download.html.


Building python-exiv2
---------------------

Once you've cloned the GitHub repository, or downloaded and unpacked a source archive, switch to the python-exiv2 directory.
If you are using the libexiv2_ installed by your operating system you just need to build python-exiv2 and install it as follows::

    python3 setup.py bdist_wheel
    sudo python3 -m pip install dist/exiv2-0.0.0-cp36-cp36m-linux_x86_64.whl

(The name of the wheel file will depend on your Python version and system architecture.)

If you are using a downloaded copy of libexiv2_ then a few more steps are required.
First you need to copy some files using the ``copy_libexiv2.py`` script.
This has two parameters: the exiv2 directory and the exiv2 version.
For example::

    python3 utils/copy_libexiv2.py ../exiv2-0.27.4-Linux64 0.27.4

This copies the exiv2 header files and runtime library to the directory ``libexiv2_0.27.4/linux/``.
Next you need to tell the build system to use this local copy::

    python3 utils/pre_build.py libexiv2_0.27.4

Now you can run ``setup.py`` as before::

    python3 setup.py bdist_wheel
    sudo python3 -m pip install dist/exiv2-0.0.0-cp36-cp36m-linux_x86_64.whl

When you try to import exiv2 into Python it's possible you might get an error like ``OSError: /lib64/libm.so.6: version `GLIBC_2.29' not found (required by /usr/lib64/python3.6/site-packages/exiv2/libexiv2.so.0.27.4)``.
This happens if the downloaded copy of libexiv2_ was built for a newer version of the GNU C library than is installed on your computer.
In this case the only option is to build libexiv2_ from source.

Download the exiv2 source archive, then follow the build instructions in ``README.md``, but make sure you install to a local directory rather than ``/usr/local``::

    $ mkdir build && cd build
    $ cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../local_install
    $ cmake --build .
    $ make install

Then, back in your python-exiv2 directory, copy sources from the newly created local directory::

    python3 utils/copy_libexiv2.py ../exiv2-0.27.4-Source/local_install 0.27.4

Problems?
---------

I think it's a bit early in the project to be using the "issues" page.
Please email jim@jim-easterbrook.me.uk if you find any problems (or solutions!).

.. _Doxygen:           https://www.doxygen.nl/
.. _exiv2:             https://www.exiv2.org/getting-started.html
.. _gexiv2:            https://wiki.gnome.org/Projects/gexiv2
.. _libexiv2:          https://www.exiv2.org/doc/index.html
.. _pyexiv2 (new):     https://github.com/LeoHsiao1/pyexiv2
.. _pyexiv2 (old):     https://launchpad.net/pyexiv2
.. _PyGObject:         https://pygobject.readthedocs.io/en/latest/
.. _PyPI:              https://pypi.org/
.. _SWIG:              http://swig.org/
.. _pydoc:             https://docs.python.org/3/library/pydoc.html
.. _Python3:           https://www.python.org/
.. _Visual C++:        https://wiki.python.org/moin/WindowsCompilers
