Installation
============

As mentioned in `<README.rst>`_, on most computers `python-exiv2`_ can be installed with a simple pip_ command::

    C:\>pip install python-exiv2
    Collecting python-exiv2
      Downloading python_exiv2-0.3.0-cp38-cp38-win_amd64.whl (1.7 MB)
         |████████████████████████████████| 1.7 MB 595 kB/s
    Installing collected packages: python-exiv2
    Successfully installed python-exiv2-0.3.0

If this doesn't work, or you need a non-standard installation, there are other ways to install `python-exiv2`_.

.. contents::
    :backlinks: top

Use installed libexiv2
----------------------

In the example above, pip_ installs a "binary wheel_".
This is pre-compiled and includes a copy of the libexiv2_ library, which makes installation quick and easy.
Wheels for `python-exiv2`_ are available for Windows (Python 3.5 to 3.10) and Linux & MacOS (Python 3.6 to 3.10).

If your computer already has libexiv2_ installed (typically by your operating system's "package manager") then pip_ might be able to compile `python-exiv2`_ to use it.
First you need to check what version of python-exiv2 you have::

    $ pkg-config --modversion exiv2
    0.26

If this command fails it might be because you don't have the "development headers" of libexiv2_ installed.
On some operating systems these are a separate package, with a name like ``exiv2-dev``.

If the ``pkg-config`` command worked, and your version of libexiv2 is between 0.26 and 0.27.5, then you should be able to install `python-exiv2`_ from source::
    
    $ sudo pip install python-exiv2 --no-binary :all:
    Collecting python-exiv2
      Downloading python-exiv2-0.3.0.zip (6.4 MB)
         |████████████████████████████████| 6.4 MB 590 kB/s 
    Skipping wheel build for python-exiv2, due to binaries being disabled for it.
    Installing collected packages: python-exiv2
        Running setup.py install for python-exiv2 ... done
    Successfully installed python-exiv2-0.3.0

This will take some time as python-exiv2 has to be compiled, and some of its modules are quite large.
If you want to see what's happening you can use the ``-v`` option to increase pip_'s verbosity.

This installation uses a "minimal" Python interface that should be compatible with any sensible installation of libexiv2_.
If the installed libexiv2 has extras, such as support for BMFF files, they might not be available from Python.
In this case you need to download the python-exiv2 source and run SWIG to create an interface tuned to your libexiv2 build.

Download python-exiv2 source
----------------------------

The following installation procedures all require access to the `python-exiv2`_ source code.
You can download this from GitHub_ (use the most recent release) or, if you are familiar with git_, you could "clone" the GitHub repo.
The rest of this document assumes you have the source code and are in your ``python-exiv2`` directory.

You may also need to install the wheel package used to build Python wheels::

    $ sudo pip install wheel

Use pre-built libexiv2
----------------------

The Exiv2 project provides builds_ for several operating systems.
Download and unpack the appropriate one for your operating system, then use the ``copy_libexiv2.py`` script provided with python-exiv2 to copy the required files.
This script takes two parameters, the source directory and the exiv2 version, for example::

    $ python3 utils/copy_libexiv2.py ../exiv2-0.27.5-Linux64 0.27.5

Next you can compile `python-exiv2`_ to use this source.
Note the use of the ``EXIV2_VERSION`` environment variable to select the source::

    $ EXIV2_VERSION=0.27.5 pip wheel .
    Processing /home/jim/python-exiv2
    Building wheels for collected packages: python-exiv2
      Building wheel for python-exiv2 (setup.py) ... done
      Created wheel for python-exiv2: filename=python_exiv2-0.3.1-cp36-cp36m-linux_x86_64.whl size=4850527 sha256=72f2e85ebf14f414f66b6b939c4c7a9787be242a2b623c42a65d8f538c0f6b5a
      Stored in directory: /home/jim/.cache/pip/wheels/95/11/3c/2536c604d8cc5593cd723bb1f3f8b0439c0c11bed5626debfb
    Successfully built python-exiv2

As before, you can use pip_'s ``-v`` option to see what's happening as it compiles each python-exiv2 module.

If this worked you can now install the wheel_ you've just built::

    $ sudo pip install python_exiv2-0.3.1-cp36-cp36m-linux_x86_64.whl 
    Processing ./python_exiv2-0.3.1-cp36-cp36m-linux_x86_64.whl
    Installing collected packages: python-exiv2
    Successfully installed python-exiv2-0.3.1

Windows
^^^^^^^

The above instructions apply to Unix-like systems such as Linux, MacOS, and MinGW.
However, it is also possible to build `python-exiv2`_ on Windows.
There is a lot of confusing and contradictory information available about building Python extensions on Windows.
The following is what has worked for me.

First you need to install a compiler.
Python versions 3.5 onwards need Visual C++ 14.x.
Fortunately Microsoft provides a free `Visual C++ 14.2 standalone`_.
Download and install this first.

Copy the required libexiv2_ files::

    c:\Users\Jim\python-exiv2>python utils\copy_libexiv2.py ..\exiv2-0.27.5-2019msvc64 0.27.5

Build a wheel::

    c:\Users\Jim\python-exiv2>set EXIV2_VERSION=0.27.5
    c:\Users\Jim\python-exiv2>pip wheel .
    Processing c:\users\jim\python-exiv2
    Building wheels for collected packages: python-exiv2
      Building wheel for python-exiv2 (setup.py) ... done
      Created wheel for python-exiv2: filename=python_exiv2-0.3.1-cp38-cp38-win_amd64.whl size=1744137 sha256=b1cbc43b200ae48ce88a68d45b8dc702aef6ecc5ba317b96212c0e592a36682c
      Stored in directory: c:\users\jim\appdata\local\pip\cache\wheels\77\a8\d0\50e43a228b0acffc6f77d6ea1c651044ee197bfebb6f0387cc
    Successfully built python-exiv2

Install the wheel::

    c:\Users\Jim\python-exiv2>pip install python_exiv2-0.3.1-cp38-cp38-win_amd64.whl
    Processing c:\users\jim\python-exiv2\python_exiv2-0.3.1-cp38-cp38-win_amd64.whl
    Installing collected packages: python-exiv2
    Successfully installed python-exiv2-0.3.1

Build your own libexiv2
-----------------------

In some circumstances a pre-built libexiv2_ supplied by the exiv2 project may not be suitable.
For example, the Linux build might use newer libraries than are installed on your computer, or you might need the Windows Unicode path option that's not enabled by default.

Building libexiv2 requires CMake_.
This should be available from your operating system's package manager.
If not (e.g. on Windows) then download an installer from the CMake web site.
You will also need to install the "development headers" of zlib_ and expat_.
Exiv2 provides some `build instructions`_, but I don't follow them exactly.

Download and unpack the exiv2 source, then change to its directory.
Create a build directory and change to it, then configure the build::

    $ mkdir build
    $ cd build
    $ cmake .. -DCMAKE_BUILD_TYPE=Release \
    > -DCMAKE_INSTALL_PREFIX=../local_install -DEXIV2_BUILD_SAMPLES=OFF \
    > -DEXIV2_BUILD_EXIV2_COMMAND=OFF -DEXIV2_ENABLE_BMFF=OFF

Note the use of ``-DCMAKE_INSTALL_PREFIX=../local_install`` to create a local copy of libexiv2, rather than installing it in ``/usr/local``.

If this worked you can now compile and install (to the local folder) libexiv2::

    $ cmake --build .
    $ make install

Back in your python-exiv2 directory, copy your newly compiled libexiv2 from the local folder::

    $ python3 utils/copy_libexiv2.py ../exiv2-0.27.5-Source/local_install 0.27.5

Then build and install a wheel as before.

Windows
^^^^^^^

Once again, doing this on Windows is just a bit more complicated.

The dependencies zlib_, expat_, and libiconv_ are installed with conan_.
First install conan with pip_::

    c:\Users\Jim\exiv2-0.27.5-Source>pip install conan

The dependencies required by libexiv2 are defined in the file ``conanfile.py``.
Unfortunately this file is out of date and needs to be replaced by the one supplied with python-exiv2::

    c:\Users\Jim\exiv2-0.27.5-Source>copy ..\python-exiv2\conanfile.py .

Now create a build directory, then change to it and run conan::

    c:\Users\Jim\exiv2-0.27.5-Source>mkdir build
    c:\Users\Jim\exiv2-0.27.5-Source>cd build
    c:\Users\Jim\exiv2-0.27.5-Source\build>conan install .. --build missing

This installs the dependencies and creates a file ``conanbuildinfo.cmake`` that tells CMake_ where they are.

Now you can configure CMake::

    c:\Users\Jim\exiv2-0.27.5-Source\build>cmake .. -DCMAKE_BUILD_TYPE=Release ^
    More? -DCMAKE_INSTALL_PREFIX=../local_install -DEXIV2_ENABLE_WIN_UNICODE=ON ^
    More? -DEXIV2_BUILD_SAMPLES=OFF -DEXIV2_BUILD_EXIV2_COMMAND=OFF ^
    More? -DEXIV2_ENABLE_BMFF=OFF -G "Visual Studio 16 2019" -A x64

(The ``^`` characters are used to split this very long command.)
Note the use of ``-DCMAKE_INSTALL_PREFIX=../local_install`` to install to a local directory and ``-DEXIV2_ENABLE_WIN_UNICODE=ON`` to enable the use of Windows Unicode paths.

If that worked you can compile and install libexiv2::

    c:\Users\Jim\exiv2-0.27.5-Source\build>cmake --build . --config Release
    c:\Users\Jim\exiv2-0.27.5-Source\build>cmake --install . --config Release --prefix ../local_install

Yes, you need to specify the local directory again.
``cmake --install`` seems to ignore the ``-DCMAKE_INSTALL_PREFIX`` set earlier.

Back in your python-exiv2 directory, copy your newly compiled libexiv2 from the local folder::

    c:\Users\Jim\python-exiv2>python utils\copy_libexiv2.py ..\exiv2-0.27.5-Source\local_install 0.27.5

Then build and install a wheel as before.

Running SWIG
------------

You should only need to run SWIG_ if your installed libexiv2 has extras, such as Windows Unicode paths, that aren't available with the SWIG generated files included with python-exiv2.
Note that versions of SWIG lower than 4.0.0 may not work correctly on the highly complex libexiv2 header files.

After you've run ``copy_libexiv2.py`` you can run ``build_swig.py`` on the local copy of libexiv2::

    $ python3 utils/build_swig.py 0.27.5

Or you can run it on the system installed libexiv2::

    $ python3 utils/build_swig.py system

If you need to generate the minimal interface included with python-exiv2 you can add ``minimal`` to the command::

    $ python3 utils/build_swig.py 0.27.5 minimal

After running ``build_swig.py`` you can build and install a wheel as before::

    $ EXIV2_VERSION=0.27.5 pip wheel .
    $ sudo pip install python_exiv2-0.6.1-cp36-cp36m-linux_x86_64.whl


.. _build instructions:
    https://github.com/exiv2/exiv2#2
.. _builds:       https://www.exiv2.org/download.html
.. _CMake:        https://cmake.org/
.. _conan:        https://conan.io/
.. _expat:        https://libexpat.github.io/
.. _git:          https://git-scm.com/
.. _GitHub:       https://github.com/jim-easterbrook/python-exiv2/releases
.. _libexiv2:     https://www.exiv2.org/getting-started.html
.. _libiconv:     https://www.gnu.org/software/libiconv/
.. _pip:          https://pip.pypa.io/
.. _python-exiv2: https://github.com/jim-easterbrook/python-exiv2
.. _SWIG:         http://www.swig.org/
.. _Visual C++ 14.2 standalone:
    https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019
.. _wheel:        https://www.python.org/dev/peps/pep-0427/
.. _zlib:         https://zlib.net/
