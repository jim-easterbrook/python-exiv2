Hints and tips
==============

Here are some ideas on how to use python-exiv2.
In many cases there's more than one way to do it, but some ways are more "Pythonic" than others.
Some of this is only applicable to python-exiv2 v0.16.0 onwards.
You can find out what version of python-exiv2 you have with either ``pip3 show exiv2`` or ``python3 -m exiv2``.

Documentation of python-exiv2 is split across several files.

+------------------+---------------------------------------------------+
| `<README.rst>`_  | Introduction to python-exiv2                      |
+------------------+---------------------------------------------------+
| `<INSTALL.rst>`_ | Help with installing python-exiv2                 |
+------------------+---------------------------------------------------+
| `<USAGE.rst>`_   | Hints and tips for using python-exiv2 (this file) |
+------------------+---------------------------------------------------+
| libexiv2_        | Exiv2 C++ API documentation                       |
+------------------+---------------------------------------------------+

.. contents::
    :backlinks: top

Deprecation warnings
--------------------

As python-exiv2 is being developed better ways are being found to do some things.
Some parts of the interface are deprecated and will eventually be removed.
Please use Python's ``-Wd`` flag when testing your software to ensure it isn't using deprecated features.
(Do let me know if I've deprecated a feature you need and can't replace with an alternative.)

Enums
-----

The C++ libexiv2 library often uses ``enum`` classes to list related data, such as the value type identifiers stored in `Exiv2::TypeId`_.
SWIG's default processing of such enums is to add all the values as named constants to the top level of the module, e.g. ``exiv2.asciiString``.
In python-exiv2 most of the C++ enums are represented by Python enum_ classes, e.g. ``exiv2.TypeId.asciiString`` is a member of ``exiv2.TypeId``.

Unfortunately there is no easy way to deprecate the SWIG generated top level constants, but they will eventually be removed from python-exiv2.
Please ensure you only use the enum classes in your use of python-exiv2.


Segmentation faults
-------------------

There are many places in the libexiv2 C++ API where objects hold references to data in other objects.
This is more efficient than copying the data, but can cause segmentation faults if an object is deleted while another objects refers to its data.

The Python interface tries to protect the user from this but in some cases this is not possible.
For example, an `Exiv2::Metadatum`_ object holds a reference to data that can easily be invalidated:

.. code:: python

    exifData = image.exifData()
    datum = exifData['Exif.GPSInfo.GPSLatitude']
    print(str(datum.value()))                       # no problem
    del exifData['Exif.GPSInfo.GPSLatitude']
    print(str(datum.value()))                       # segfault!

Segmentation faults are also easily caused by careless use of iterators or memory blocks, as discussed below.
There may be other cases where the Python interface doesn't prevent segfaults.
Please let me know if you find any.

Reading data values
-------------------

Exiv2 stores metadata as (key, value) pairs in `Exiv2::Metadatum`_ objects.
The datum has two methods to retrieve the value: ``value()`` and ``getValue()``.
The first gets a reference to the value and the second makes a copy.
Use ``value()`` when you don't need to modify the data.
``getValue()`` copies the data to a new object that you can modify.

In the C++ API these methods both return (a pointer to) an `Exiv2::Value`_ base class object.
The Python interface uses the value's ``typeId()`` method to determine its type and casts the return value to the appropriate derived type.

Recasting data values
^^^^^^^^^^^^^^^^^^^^^

In some cases, such as ``Exif.Photo.UserComment``, the value's type id is not specific enough to choose a useful ``Exiv2::Value`` subclass.
The Python interface allows a datum's value to be obtained as a different type.
This can be used to decode an Exif user comment:

.. code:: python

    datum = exifData['Exif.Photo.UserComment']
    value = datum.value(exiv2.TypeId.comment)
    result = value.comment()

Exiv2::ValueType< T >
---------------------

Exiv2 uses a template class `Exiv2::ValueType< T >`_ to store Exif numerical values such as the unsigned rationals used for GPS coordinates.
This class stores the actual data in a ``std::vector`` attribute ``value_``.
In the Python interface this attribute is hidden and the data is accessed by indexing:

.. code:: python

    datum = exifData['Exif.GPSInfo.GPSLatitude']
    value = datum.getValue()
    print(value[0])
    value[0] = (47, 1)

Python read access to the data can be simplified by using it to initialise a list or tuple:

.. code:: python

    datum = exifData['Exif.GPSInfo.GPSLatitude']
    value = list(datum.value())

You can also construct new values from a Python list or tuple:

.. code:: python

    value = exiv2.URationalValue([(47, 1), (49, 1), (31822, 1000)])
    exifData['Exif.GPSInfo.GPSLatitude'] = value

String values
^^^^^^^^^^^^^

If you don't want to use the data numerically then you can just use strings for everything:

.. code:: python

    datum = exifData['Exif.GPSInfo.GPSLatitude']
    value = str(datum.value())
    exifData['Exif.GPSInfo.GPSLatitude'] = '47/1 49/1 31822/1000'

Iterators
---------

The ``Exiv2::ExifData``, ``Exiv2::IptcData``, and ``Exiv2::XmpData`` classes use C++ iterators to expose private data, for example the ``ExifData`` class has a private member of ``std::list<Exifdatum>`` type.
The classes have public ``begin()``, ``end()``, and ``findKey()`` methods that return ``std::list`` iterators.
In C++ you can dereference one of these iterators to access the ``Exifdatum`` object, but Python doesn't have a dereference operator.

This Python interface converts the ``std::list`` iterator to a Python object that has access to all the ``Exifdatum`` object's methods without dereferencing.
For example:

.. code:: python

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

Before using an iterator you must ensure that it is not equal to the ``end()`` value.

You can iterate over the data in a very C++ like style:

.. code:: python

    >>> data = image.exifData()
    >>> b = data.begin()
    >>> e = data.end()
    >>> while b != e:
    ...     b.key()
    ...     next(b)
    ...
    'Exif.Image.ProcessingSoftware'
    <Swig Object of type 'Exiv2::Exifdatum *' at 0x7fd6053f9030>
    'Exif.Image.ImageDescription'
    <Swig Object of type 'Exiv2::Exifdatum *' at 0x7fd6053f9030>
    [skip 227 line pairs]
    'Exif.Thumbnail.JPEGInterchangeFormat'
    <Swig Object of type 'Exiv2::Exifdatum *' at 0x7fd6053f9030>
    'Exif.Thumbnail.JPEGInterchangeFormatLength'
    <Swig Object of type 'Exiv2::Exifdatum *' at 0x7fd6053f9030>
    >>>

The ``<Swig Object of type 'Exiv2::Exifdatum *' at 0x7fd6053f9030>`` lines are the Python interpreter showing the return value of ``next(b)``.
You can also iterate in a more Pythonic style:

.. code:: python

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

The data container classes are like a cross between a Python list_ of ``Metadatum`` objects and a Python dict_ of ``(key, Value)`` pairs.
(One way in which they are not like a dict_ is that you can have more than one member with the same key.)
This allows them to be used in a very Pythonic style:

.. code:: python

    data = image.exifData()
    print(data['Exif.Image.ImageDescription'].toString())
    if 'Exif.Image.ProcessingSoftware' in data:
        del data['Exif.Image.ProcessingSoftware']
    data = image.iptcData()
    while 'Iptc.Application2.Keywords' in data:
        del data['Iptc.Application2.Keywords']

Warning: segmentation faults
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If an iterator is invalidated, e.g. by deleting the datum it points to, then your Python program may crash with a segmentation fault if you try to use the invalid iterator.
Just as in C++, there is no way to detect that an iterator has become invalid.

Binary data input
-----------------

Some libexiv2 functions, e.g. `Exiv2::ExifThumb::setJpegThumbnail`_, have an ``Exiv2::byte*`` parameter and a length parameter.
In python-exiv2 these are replaced by a single `bytes-like object`_ parameter that can be any Python object that exposes a simple `buffer interface`_, e.g. bytes_, bytearray_, memoryview_:

.. code:: python

    # Use Python imaging library to make a small JPEG image
    pil_im = PIL.Image.open('IMG_9999.JPG')
    pil_im.thumbnail((160, 120), PIL.Image.ANTIALIAS)
    data = io.BytesIO()
    pil_im.save(data, 'JPEG')
    # Set image thumbnail to small JPEG image
    thumb = exiv2.ExifThumb(image.exifData())
    thumb.setJpegThumbnail(data.getbuffer())

Binary data output
------------------

Some libexiv2 functions, e.g. `Exiv2::DataBuf::data`_, return ``Exiv2::byte*``, a pointer to a block of memory.
In python-exiv2 from v0.15.0 onwards this is converted directly to a Python memoryview_ object.
This allows direct access to the block of memory without unnecessary copying.
In some cases this includes writing to the data.

.. code:: python

    thumb = exiv2.ExifThumb(image.exifData())
    buf = thumb.copy()
    thumb_im = PIL.Image.open(io.BytesIO(buf.data()))

In python-exiv2 before v0.15.0 the memory block is converted to an object with a buffer interface.
A Python memoryview_ can be used to access the data without copying.
(Converting to bytes_ would make a copy of the data, which we don't usually want.)

Warning: segmentation faults
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Note that the memory block must not be deleted or resized while the memoryview exists.
Doing so will invalidate the memoryview and may cause a segmentation fault:

.. code:: python

    buf = exiv2.DataBuf(b'fred')
    data = buf.data()
    print(bytes(data))              # Prints b'fred'
    buf.alloc(128)
    print(bytes(data))              # Prints random values, may segfault

Image data in memory
--------------------

The `Exiv2::ImageFactory`_ class has a method ``open(const byte *data, size_t size)`` to create an `Exiv2::Image`_ from data stored in memory, rather than in a file.
In python-exiv2 the ``data`` and ``size`` parameters are replaced with a single `bytes-like object`_ such as bytes_ or bytearray_.
The buffered data isn't actually read until ``Image::readMetadata`` is called, so python-exiv2 stores a reference to the buffer to stop the user accidentally deleting it.

When ``Image::writeMetadata`` is called exiv2 allocates a new block of memory to store the modified data.
The ``Image::io`` method returns an `Exiv2::MemIo`_ object that provides access to this data.
(`Exiv2::MemIo`_ is derived from `Exiv2::BasicIo`_.)

The ``BasicIo::mmap`` method allows access to the image file data without unnecessary copying.
However it is rather error prone, crashing your Python program with a segmentation fault if anything goes wrong.

The ``Exiv2::BasicIo`` object must be opened before calling ``mmap()``.
A Python `context manager`_ can be used to ensure that the ``open()`` and ``mmap()`` calls are paired with ``munmap()`` and ``close()`` calls:

.. code:: python

    from contextlib import contextmanager

    @contextmanager
    def get_file_data(image):
        exiv_io = image.io()
        exiv_io.open()
        try:
            yield exiv_io.mmap()
        finally:
            exiv_io.munmap()
            exiv_io.close()

    # after setting some metadata
    image.writeMetadata()
    with get_file_data(image) as data:
        rsp = requests.post(url, files={'file': io.BytesIO(data)})

The ``exiv2.BasicIo`` Python type exposes a `buffer interface`_ which is a lot easier to use.
It allows the ``exiv2.BasicIo`` object to be used anywhere that a `bytes-like object`_ is expected:

.. code:: python

    # after setting some metadata
    image.writeMetadata()
    exiv_io = image.io()
    rsp = requests.post(url, files={'file': io.BytesIO(exiv_io)})

Since python-exiv2 v0.15.0 this buffer can be writeable:

.. code:: python

    exiv_io = image.io()
    with memoryview(exiv_io) as data:
        data[23] = 157      # modifies data buffer
    image.readMetadata()    # reads modified buffer data

The modified data is written back to the file (for ``Exiv2::FileIo``) or memory buffer (for `Exiv2::MemIo`_) when the memoryview_ is released.

.. _bytearray:
    https://docs.python.org/3/library/stdtypes.html#bytearray
.. _bytes:
    https://docs.python.org/3/library/stdtypes.html#bytes
.. _bytes-like object:
    https://docs.python.org/3/glossary.html#term-bytes-like-object
.. _buffer interface:
    https://docs.python.org/3/c-api/buffer.html
.. _context manager:
    https://docs.python.org/3/reference/datamodel.html#context-managers
.. _dict:
    https://docs.python.org/3/library/stdtypes.html#dict
.. _enum:
    https://docs.python.org/3/library/enum.html
.. _Exiv2::BasicIo:
    https://exiv2.org/doc/classExiv2_1_1BasicIo.html
.. _Exiv2::BasicIo::mmap:
    https://exiv2.org/doc/classExiv2_1_1BasicIo.html
.. _Exiv2::DataBuf::data:
    https://exiv2.org/doc/structExiv2_1_1DataBuf.html
.. _Exiv2::ExifThumb::setJpegThumbnail:
    https://exiv2.org/doc/classExiv2_1_1ExifThumb.html
.. _Exiv2::Image:
    https://exiv2.org/doc/classExiv2_1_1Image.html
.. _Exiv2::ImageFactory:
    https://exiv2.org/doc/classExiv2_1_1ImageFactory.html
.. _Exiv2::MemIo:
    https://exiv2.org/doc/classExiv2_1_1MemIo.html
.. _Exiv2::Metadatum:
    https://exiv2.org/doc/classExiv2_1_1Metadatum.html
.. _Exiv2::TypeId:
    https://exiv2.org/doc/namespaceExiv2.html#a5153319711f35fe81cbc13f4b852450c
.. _Exiv2::Value:
    https://exiv2.org/doc/classExiv2_1_1Value.html
.. _Exiv2::ValueType< T >:
    https://exiv2.org/doc/classExiv2_1_1ValueType.html
.. _libexiv2:
    https://www.exiv2.org/doc/index.html
.. _list:
    https://docs.python.org/3/library/stdtypes.html#list
.. _memoryview:
    https://docs.python.org/3/library/stdtypes.html#memoryview
