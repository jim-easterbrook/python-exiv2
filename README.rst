python-exiv2 v\ 0.0.0
=====================

python-exiv2 is a low level interface (or binding) to the exiv2_ C++ library.
It is built using SWIG_ to automatically generate the interface code.
The intention is to give direct access to all of the top-level classes in exiv2_, but with additional "Pythonic" helpers where necessary.

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

    * Get iterators working - a lot of exiv2_'s classes have ``begin`` and ``end`` methods that return iterators over the class's private data.
    * Build with different versions of exiv2_.
    * Build for Windows.
    * Package for PyPI_.
    * Error handling.

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
.. _PyPI:              https://pypi.org/
.. _SWIG:              http://swig.org/
.. _Python3:           https://www.python.org/
