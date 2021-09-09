python-exiv2 v\ 0.3.0
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
It is already usable, but please email jim@jim-easterbrook.me.uk if it doesn't work for you.
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

Installation
------------

Windows
^^^^^^^

Python "wheels" are available for Windows Python versions from 3.5 to 3.9.
These include the libexiv2 library and should not need any other software to be installed.
They can be installed with ``pip``, for example::

    C:\Users\Jim>"c:\Program Files\Python38\python.exe" -m pip install python-exiv2

Linux
^^^^^

Python "wheels" are available for Linux Python versions from 3.6 to 3.10.
These include the libexiv2 library and should not need any other software to be installed.
They can be installed with ``pip``, for example::

    sudo pip3 install python-exiv2

You can install for a single user with the ``--user`` option::

    pip3 install --user python-exiv2

If the available wheels are not compatible with your operating system then pip will download the python-exiv2 source and attempt to compile it.
This requires the "development headers" of Python3_ and an appropriate compiler & linker to be installed.

If the development headers of libexiv2 are installed then pip will try to build python-exiv2 to use the installed version.
Otherwise it will use the copy included in the download, which may not be compatible with your operating system.

Building python-exiv2
---------------------

If you want customise your installation of python-exiv2 you can build it yourself.
Download and unpack a source archive from PyPI_ or GitHub_, then switch to the python-exiv2 directory.
The ``setup.py`` script used to install python-exiv2 will use the libexiv2_ installed by your operating system if it can find it.
This usually requires the "development headers" package to be installed.
In this case you just need to build python-exiv2 and install it as follows::

    pip wheel -v .
    sudo pip3 install python_exiv2-0.2.3-cp36-cp36m-linux_x86_64.whl

(The name of the wheel file will depend on the python-exiv2 version, your Python version, and the system architecture.)

If you want to use your own downloaded copy of libexiv2_ then a few more steps are required.
First you need to copy some files using the ``copy_libexiv2.py`` script.
This has two parameters: the exiv2 directory and the exiv2 version.
For example::

    python3 utils/copy_libexiv2.py ../exiv2-0.27.4-Linux64 0.27.4

This copies the exiv2 header files and runtime library to the directory ``libexiv2_0.27.4/linux/``.
Now you can run ``pip`` as before.
Note that ``pip`` will still use the system installed version of libexiv2_ if it can find it.
Uninstalling the "development headers" package will prevent this.

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

Then run ``pip`` as before.

Problems?
---------

I think it's a bit early in the project to be using the "issues" page.
Please email jim@jim-easterbrook.me.uk if you find any problems (or solutions!).

.. _Doxygen:           https://www.doxygen.nl/
.. _exiv2:             https://www.exiv2.org/getting-started.html
.. _gexiv2:            https://wiki.gnome.org/Projects/gexiv2
.. _GitHub:            https://github.com/jim-easterbrook/python-exiv2
.. _libexiv2:          https://www.exiv2.org/doc/index.html
.. _pyexiv2 (new):     https://github.com/LeoHsiao1/pyexiv2
.. _pyexiv2 (old):     https://launchpad.net/pyexiv2
.. _PyGObject:         https://pygobject.readthedocs.io/en/latest/
.. _PyPI:              https://pypi.org/project/python-exiv2/
.. _SWIG:              http://swig.org/
.. _pydoc:             https://docs.python.org/3/library/pydoc.html
.. _Python3:           https://www.python.org/
.. _Visual C++:        https://wiki.python.org/moin/WindowsCompilers
