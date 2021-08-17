python-exiv2 v\ 0.0.0
=====================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in exiv2_, but with additional "Pythonic" helpers where necessary.

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

**This project is at a very early stage of development.**
I've managed to get it to build and run with exiv2_ v0.26 (as that's what's installed on my main Linux computer) but it's not yet very useful.
Here is an example of what it can do so far::

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

    * Build with different versions of libexiv2_.
    * Build for Windows.
    * Package for PyPI_.
    * Error handling.
    * Example files.

Iterators
---------

Several libexiv2_'s classes use C++ iterators to expose private data, for example the ``ExifData`` class has a private member of ``std::list<Exifdatum>`` type.
The classes have public ``begin`` and ``end`` methods that return ``std::list`` iterators.
In C++ you can dereference one of these iterators to access the ``Exifdatum`` object, but Python doesn't have a dereference operator.

This Python interface converts a ``std::list`` iterator to a Python object that has a ``curr`` method to return the list value.
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

Dependencies
------------

Currently the only way to install python-exiv2 is to compile it from source.
This requires swig_, the "development headers" of exiv2_ and Python3_, and the usual GNU C++ compiler and linker.
These should all be installable with your operating system's package manager.

Building python-exiv2
---------------------

Once you've cloned the GitHub repository, or downloaded and unpacked a source archive, switch to the python-exiv2 directory and run::

    python3 utils/build_swig.py

This should run swig_ on each interface file in ``src`` to generate ``.py`` and ``.cxx`` files in ``swig``.
These files can then be compiled and linked using ``setup.py``::

    python3 setup.py build
    sudo python3 setup.py install

Problems?
---------

I think it's a bit early in the project to be using the "issues" page.
Please email jim@jim-easterbrook.me.uk if you find any problems (or solutions!).


.. _exiv2:             https://www.exiv2.org/getting-started.html
.. _gexiv2:            https://wiki.gnome.org/Projects/gexiv2
.. _libexiv2:          https://www.exiv2.org/doc/index.html
.. _pyexiv2 (new):     https://github.com/LeoHsiao1/pyexiv2
.. _pyexiv2 (old):     https://launchpad.net/pyexiv2
.. _PyGObject:         https://pygobject.readthedocs.io/en/latest/
.. _PyPI:              https://pypi.org/
.. _SWIG:              http://swig.org/
.. _Python3:           https://www.python.org/
