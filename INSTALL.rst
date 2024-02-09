Installation
============

As mentioned in `README.rst`_, on most computers `python-exiv2`_ can be installed with a simple pip_ command::

    C:\>pip install exiv2
    Collecting exiv2
      Downloading exiv2-0.11.0-cp38-cp38-win_amd64.whl (1.7 MB)
         ---------------------------------------- 1.7/1.7 MB 589.2 kB/s eta 0:00:00
    Installing collected packages: exiv2
    Successfully installed exiv2-0.11.0

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
      Downloading exiv2-0.15.0.tar.gz (2.2 MB)
         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2.2/2.2 MB 912.8 kB/s eta 0:00:00
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.15.0-cp310-cp310-linux_x86_64.whl size=4777620 sha256=79ca170d02df3daadda0b05c0c03c9092ac29909c32f5d64adb949c0bfcd80f2
      Stored in directory: /home/jim/.cache/pip/wheels/e5/e7/0a/1c8b815209c41d573386e5bf8baa563cd0df990a7a95b42b0d
    Successfully built exiv2
    Installing collected packages: exiv2
    Successfully installed exiv2-0.15.0

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

    $ pip3 install --user wheel

Use pre-built libexiv2
----------------------

The Exiv2 project provides builds_ for several operating systems.
Download and unpack the appropriate one for your operating system, then you can compile `python-exiv2`_ to use this source.
Note the use of the ``EXIV2_ROOT`` environment variable to select the source::

    $ EXIV2_ROOT=../exiv2-0.27.7-Linux64 pip3 wheel .
    Processing /home/jim/python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.15.0-cp310-cp310-linux_x86_64.whl size=7643561 sha256=7f35d4eb5a8306c1a67fef055f74a03ad000e99dee19f12268b80a89d1d51607
      Stored in directory: /home/jim/.cache/pip/wheels/b6/c0/a3/68cf7238e1b7de98ca8bbce0f5f3f0bf6b85f9b6468a097cca
    Successfully built exiv2

As before, you can use pip_'s ``-v`` option to see what's happening as it compiles each python-exiv2 module.

If this worked you can now install the wheel_ you've just built::

    $ pip3 install --user exiv2-0.15.0-cp310-cp310-linux_x86_64.whl 
    Processing ./exiv2-0.15.0-cp310-cp310-linux_x86_64.whl
    Installing collected packages: exiv2
    Successfully installed exiv2-0.15.0

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

    C:\Users\Jim\python-exiv2>set EXIV2_ROOT=..\exiv2-0.27.7-2019msvc64
    C:\Users\Jim\python-exiv2>pip wheel .
    Processing c:\users\jim\python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.15.0-cp38-cp38-win_amd64.whl size=2248240 sha256=bd8ca67d397014442bf5052d0b563511f3170ba6643b89eeaf5e631334671397
      Stored in directory: c\users\jim\appdata\local\pip\cache\wheels\a3\3b\d4\d35463afd5940a14f17983a106ed52ffafc07877192bcc881a
    Successfully built exiv2

Install the wheel::

    C:\Users\Jim\python-exiv2>pip install exiv2-0.15.0-cp38-cp38-win_amd64.whl
    Processing c:\users\jim\python-exiv2\exiv2-0.15.0-cp38-cp38-win_amd64.whl
    Installing collected packages: exiv2
    Successfully installed exiv2-0.15.0

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
    > -DEXIV2_BUILD_EXIV2_COMMAND=OFF -DEXIV2_ENABLE_BMFF=ON \
    > -DEXIV2_ENABLE_NLS=ON -DCMAKE_CXX_STANDARD=98

Note the use of ``-DCMAKE_INSTALL_PREFIX=../local_install`` to create a local copy of libexiv2, rather than installing it in ``/usr/local``.
(Other cmake options enable localisation and use of BMFF files, and select the c++98 standard used by exiv2 prior to version 0.28.0.)

If this worked you can now compile and install (to the local folder) libexiv2::

    $ cmake --build .
    $ cmake --install .

Back in your python-exiv2 directory, you can build the wheel as before, but using your new build::

    $ EXIV2_ROOT=../exiv2-0.27.7-Source/local_install pip3 wheel .
    Processing /home/jim/python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.15.0-cp310-cp310-linux_x86_64.whl size=7514448 sha256=bc632e82c62fce1acc91cb9b0eb285dc3d2eba3ea11d92fdb5c10d12792f9eb4
      Stored in directory: /home/jim/.cache/pip/wheels/b6/c0/a3/68cf7238e1b7de98ca8bbce0f5f3f0bf6b85f9b6468a097cca
    Successfully built exiv2

Then install the wheel as before.

Windows
^^^^^^^

Once again, doing this on Windows is just a bit more complicated.

The dependencies zlib_, expat_, and libiconv_ are installed with conan_.
First install conan with pip_::

    C:\Users\Jim\exiv2-0.27.7-Source>pip install conan==1.59.0

Now create a build directory, then change to it and run conan::

    C:\Users\Jim\exiv2-0.27.7-Source>mkdir build
    C:\Users\Jim\exiv2-0.27.7-Source>cd build
    C:\Users\Jim\exiv2-0.27.7-Source\build>conan install .. --build missing

This installs the dependencies and creates a file ``conanbuildinfo.cmake`` that tells CMake_ where they are.

Now you can configure CMake::

    C:\Users\Jim\exiv2-0.27.7-Source\build>cmake .. -DCMAKE_BUILD_TYPE=Release ^
    More? -DCMAKE_INSTALL_PREFIX=../local_install -DEXIV2_ENABLE_WIN_UNICODE=ON ^
    More? -DEXIV2_BUILD_SAMPLES=OFF -DEXIV2_BUILD_EXIV2_COMMAND=OFF ^
    More? -DEXIV2_ENABLE_BMFF=ON -G "Visual Studio 16 2019" -A x64

(The ``^`` characters are used to split this very long command.)
Note the use of ``-DCMAKE_INSTALL_PREFIX=../local_install`` to install to a local directory and ``-DEXIV2_ENABLE_WIN_UNICODE=ON`` to enable the use of Windows Unicode paths.

If that worked you can compile and install libexiv2::

    C:\Users\Jim\exiv2-0.27.7-Source\build>cmake --build . --config Release
    C:\Users\Jim\exiv2-0.27.7-Source\build>cmake --install . --config Release

Back in your python-exiv2 directory, build a wheel using your newly compiled libexiv2 from the local folder::

    C:\Users\Jim\python-exiv2>set EXIV2_ROOT=..\exiv2-0.27.7-Source\local_install
    C:\Users\Jim\python-exiv2>pip wheel .
    Processing c:\users\jim\python-exiv2
      Installing build dependencies ... done
      Getting requirements to build wheel ... done
      Installing backend dependencies ... done
      Preparing metadata (pyproject.toml) ... done
    Building wheels for collected packages: exiv2
      Building wheel for exiv2 (pyproject.toml) ... done
      Created wheel for exiv2: filename=exiv2-0.15.0-cp38-cp38-win_amd64.whl size=2259118 sha256=eca8b01f50cc76aa5c41f2672303c46c9b4ddda00339ba927feb9c1ec419ba95
      Stored in directory: c:\users\jim\appdata\local\pip\cache\wheels\a3\3b\d4\d35463afd5940a14f17983a106ed52ffafc07877192bcc881a
    Successfully built exiv2

Then install the wheel as before.

Running SWIG
------------

You should only need to run SWIG_ if your installed libexiv2 has extras, such as Windows Unicode paths, that aren't available with the SWIG generated files included with python-exiv2.
Note that versions of SWIG lower than 4.0.0 may not work correctly on the highly complex libexiv2 header files.

The ``build_swig.py`` script has one required parameter - the path of the exiv2 include directory.
If you've downloaded or build exiv2 you can run ``build_swig.py`` on the local copy::

    $ python3 utils/build_swig.py ../exiv2-0.27.7-Source/local_install/include

Or you can run it on the system installed libexiv2::

    $ python3 utils/build_swig.py /usr/include

If you need to generate the minimal interface included with python-exiv2 you can add ``minimal`` to the command::

    $ python3 utils/build_swig.py ../exiv2-0.27.7-Source/local_install/include minimal

After running ``build_swig.py`` you can build and install a wheel as before::

    $ EXIV2_ROOT=../exiv2-0.27.7-Source/local_install pip3 wheel .
    $ pip3 install --user exiv2-0.15.0-cp310-cp310-linux_x86_64.whl 

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
