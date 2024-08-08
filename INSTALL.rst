Installation
============

As mentioned in `README.rst`_, on most computers `python-exiv2`_ can be installed with a simple pip_ command::

    C:\>pip install exiv2
    Collecting exiv2
      Downloading exiv2-0.17.0-cp38-cp38-win_amd64.whl.metadata (7.3 kB)
    Downloading exiv2-0.17.0-cp38-cp38-win_amd64.whl (8.5 MB)
       ---------------------------------------- 8.5/8.5 MB 963.3 kB/s eta 0:00:00
    Installing collected packages: exiv2
    Successfully installed exiv2-0.17.0

If this doesn't work, or you need a non-standard installation, there are other ways to install `python-exiv2`_.

.. contents::
    :backlinks: top

Use installed libexiv2
----------------------

In the example above, pip_ installs a "binary wheel_".
This is pre-compiled and includes a copy of the libexiv2_ library, which makes installation quick and easy.
Wheels for `python-exiv2`_ are available for Windows, Linux, and MacOS with Python versions from 3.6 to 3.12.

If your computer already has libexiv2_ installed (typically by your operating system's "package manager") then pip_ might be able to compile `python-exiv2`_ to use it.
First you need to check what version of python-exiv2 you have::

    $ pkg-config --modversion exiv2
    0.27.5

If this command fails it might be because you don't have the "development headers" of libexiv2_ installed.
On some operating systems these are a separate package, with a name like ``exiv2-dev``.

If the ``pkg-config`` command worked, and your version of libexiv2 is 0.27.0 or later, then you should be able to install `python-exiv2`_ from source::

    $ pip3 install --user exiv2 --no-binary :all:
    Collecting exiv2
      Downloading exiv2-0.17.0.tar.gz (1.6 MB)
         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.6/1.6 MB 870.6 kB/s eta 0:00:00
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.17.0-cp310-cp310-linux_x86_64.whl size=4586091 sha256=09d7f0d2a3654c1cf4bb944ed04d594a92e6f6eaa8a1a0acd5fa45cdf8746ffd
      Stored in directory: /home/jim/.cache/pip/wheels/e5/18/69/fc2199ac2c24b13e88a56c4660720fea109d69b0747e05eb1d
    Successfully built exiv2
    Installing collected packages: exiv2
    Successfully installed exiv2-0.17.0

This will take some time as python-exiv2 has to be compiled, and some of its modules are quite large.
If you want to see what's happening you can use the ``-v`` option to increase pip_'s verbosity.

If you change your installed libexiv2_, for example as part of an operating system update, then your installation of python-exiv2 will probably stop working.
If this happens you need to reinstall python-exiv2 to use the new version of libexiv2::

    $ pip3 install --user exiv2 --no-binary :all: --force-reinstall

Note the use of ``--force-reinstall`` to make pip reinstall python-exiv2 even if the latest version is already installed.

Download python-exiv2 source
----------------------------

The following installation procedures all require access to the `python-exiv2`_ source code.
You can download this from GitHub_ (use the most recent release) or, if you are familiar with git_, you could "clone" the GitHub repo.
The rest of this document assumes you have the source code and are in your ``python-exiv2`` directory.

You may also need to install the wheel package used to build Python wheels::

    $ pip3 install --user wheel

Use pre-built libexiv2
----------------------

The Exiv2 project provides builds_ for several operating systems.
Download and unpack the appropriate one for your operating system, then you can compile `python-exiv2`_ to use this source.
Note the use of the ``EXIV2_ROOT`` environment variable to select the source::

    $ EXIV2_ROOT=../exiv2-0.28.3-Linux64/ pip3 wheel .
    Processing /home/jim/python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.17.0-cp310-cp310-linux_x86_64.whl size=11839757 sha256=a7de01eadbf9bf608ff07cda506db1453fcb91c9b55cc9d5cbc93546ee6c52c7
      Stored in directory: /home/jim/.cache/pip/wheels/b6/c0/a3/68cf7238e1b7de98ca8bbce0f5f3f0bf6b85f9b6468a097cca
    Successfully built exiv2

As before, you can use pip_'s ``-v`` option to see what's happening as it compiles each python-exiv2 module.

If this worked you can now install the wheel_ you've just built::

    $ pip3 install --user exiv2-0.17.0-cp310-cp310-linux_x86_64.whl
    Processing ./exiv2-0.17.0-cp310-cp310-linux_x86_64.whl
    Installing collected packages: exiv2
    Successfully installed exiv2-0.17.0

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

Build a wheel::

    C:\Users\Jim\python-exiv2>set EXIV2_ROOT=..\exiv2-0.28.3-2019msvc64

    C:\Users\Jim\python-exiv2>pip wheel .
    Processing c:\users\jim\python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.17.0-cp38-cp38-win_amd64.whl size=8448722 sha256=0408f9c99a1ca772dc62ec6689dc6ce8dd8d7027d7cb8808a91e8312590c498d
      Stored in directory: c:\users\jim\appdata\local\pip\cache\wheels\a3\3b\d4\d35463afd5940a14f17983a106ed52ffafc07877192bcc881a
    Successfully built exiv2

Install the wheel::

    C:\Users\Jim\python-exiv2>pip install exiv2-0.17.0-cp38-cp38-win_amd64.whl
    Processing c:\users\jim\python-exiv2\exiv2-0.17.0-cp38-cp38-win_amd64.whl
    Installing collected packages: exiv2
    Successfully installed exiv2-0.17.0

Build your own libexiv2
-----------------------

In some circumstances a pre-built libexiv2_ supplied by the exiv2 project may not be suitable.
For example, the Linux build might use newer libraries than are installed on your computer.

Building libexiv2 requires CMake_.
This should be available from your operating system's package manager.
If not (e.g. on Windows) then download an installer from the CMake web site.
You will also need to install the "development headers" of zlib_ and expat_.
Exiv2 provides some `build instructions`_, but I don't follow them exactly.

Download and unpack the exiv2 source, then change to its directory.
Then configure the build::

    $ cmake --preset linux-release -D CONAN_AUTO_INSTALL=OFF \
    > -D EXIV2_BUILD_SAMPLES=OFF -D EXIV2_BUILD_UNIT_TESTS=OFF \
    > -D EXIV2_BUILD_EXIV2_COMMAND=OFF -D EXIV2_ENABLE_NLS=ON

(The cmake options enable localisation and turn off building bits we don't need.)

If this worked you can now compile and install (to the local folder) libexiv2::

    $ cmake --build build-linux-release --config Release
    $ cmake --install build-linux-release --config Release

Back in your python-exiv2 directory, you can build the wheel as before, but using your new build::

    $ EXIV2_ROOT=../exiv2-0.28.3/build-linux-release/install pip3 wheel .
    Processing /home/jim/python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.17.0-cp310-cp310-linux_x86_64.whl size=11979058 sha256=85cf8d78bd8d6b82de6aae6fd8bb58ffb76a381cc921bc1bd77fbfb77e46e2dc
      Stored in directory: /home/jim/.cache/pip/wheels/b6/c0/a3/68cf7238e1b7de98ca8bbce0f5f3f0bf6b85f9b6468a097cca
    Successfully built exiv2

Then install the wheel as before.

Windows
^^^^^^^

Once again, doing this on Windows is just a bit more complicated.

The dependencies zlib_, expat_, and libiconv_ are installed with conan_.
First install conan with pip_::

    C:\Users\Jim\exiv2-0.28.3>pip install conan==1.59.0

Then configure CMake::

    C:\Users\Jim\exiv2-0.28.3>cmake --preset msvc -D CMAKE_BUILD_TYPE=Release ^
    More? -D EXIV2_BUILD_SAMPLES=OFF -D EXIV2_BUILD_EXIV2_COMMAND=OFF ^
    More? -D EXIV2_BUILD_UNIT_TESTS=OFF -G "Visual Studio 16 2019"

(The ``^`` characters are used to split this very long command.)

If that worked you can compile and install libexiv2::

    C:\Users\Jim\exiv2-0.28.3>cmake --build build-msvc --config Release

    C:\Users\Jim\exiv2-0.28.3>cmake --install build-msvc --config Release

Back in your python-exiv2 directory, build a wheel using your newly compiled libexiv2::

    C:\Users\Jim\python-exiv2>set EXIV2_ROOT=..\exiv2-0.28.3\build-msvc\install

    C:\Users\Jim\python-exiv2>pip wheel .
    Processing c:\users\jim\python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.17.0-cp38-cp38-win_amd64.whl size=8428068 sha256=c9c1364c0aaddb1455b2272cbd9ee64bc22d290f13eb7dc289b2ee67dcda87f3
      Stored in directory: c:\users\jim\appdata\local\pip\cache\wheels\a3\3b\d4\d35463afd5940a14f17983a106ed52ffafc07877192bcc881a
    Successfully built exiv2

Then install the wheel as before.

Running SWIG
------------

You should only need to run SWIG_ if your installed libexiv2 has extras, such as Windows Unicode paths, that aren't available with the SWIG generated files included with python-exiv2.
Note that SWIG version 4.1.0 or later is required to process the highly complex libexiv2 header files.

The ``build_swig.py`` script has one required parameter - the path of the exiv2 include directory.
If you've downloaded or build exiv2 you can run ``build_swig.py`` on the local copy::

    $ python3 utils/build_swig.py ../exiv2-0.28.3/build-linux-release/install/include/

Or you can run it on the system installed libexiv2::

    $ python3 utils/build_swig.py /usr/include

After running ``build_swig.py`` you can build and install a wheel as before::

    $ EXIV2_ROOT=../exiv2-0.28.3/build-linux-release/install pip3 wheel .
    $ pip3 install --user exiv2-0.17.0-cp310-cp310-linux_x86_64.whl

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
.. _README.rst:   README.rst
