Hints and tips
==============

Here are some ideas on how to use python-exiv2.
In many cases there's more than one way to do it, but some ways are more "Pythonic" than others.
Some of this is only applicable to python-exiv2 v0.16.0 onwards.
You can find out what version of python-exiv2 you have with either ``pip3 show exiv2`` or ``python3 -m exiv2``.

.. contents::
    :backlinks: top

libexiv2 library version
------------------------

Python-exiv2 can be used with any version of libexiv2 from 0.27.0 onwards.
The "binary wheels" available from PyPI_ currently include a copy of libexiv2 v0.27.7, but if you install from source then python-exiv2 will use whichever version of libexiv2 is installed on your computer.

There are some differences in the API of libexiv2 v0.28.x and v0.27.y.
Some of these have been "backported" in the Python interface so you can start using the v0.28 methods, e.g. the ``exiv2.DataBuf.data()`` function replaces the ``exiv2.DataBuf.pData_`` attribute.

If you need to write software that works with both versions of libexiv2 then the ``exiv2.testVersion`` function can be used to test for version 0.28.0 onwards:

.. code:: python

    if exiv2.testVersion(0, 28, 0):
        int_val = datum.toInt64(0)
    else:
        int_val = datum.toLong(0)

Error handling
--------------

libexiv2_ has a multilevel warning system a bit like Python's standard logger.
The Python interface redirects all Exiv2 messages to Python logging with an appropriate log level.
The ``exiv2.LogMsg.setLevel()`` method can be used to control what severity of messages are logged.

Since python-exiv2 v0.16.2 the ``exiv2.LogMsg.setHandler()`` method can be used to set the handler.
The Python logging handler is ``exiv2.LogMsg.pythonHandler`` and the Exiv2 default handler is ``exiv2.LogMsg.defaultHandler``.

NULL values
-----------

Some libexiv2_ functions that expect a pointer to an object or data can have ``NULL`` (sometimes documented as ``0``) passed to them to represent "no value".
In Python ``None`` is used instead.

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

Data structures
---------------

Some parts of the Exiv2 API use structures to hold several related data items.
For example, the `Exiv2::ExifTags`_ class has a ``tagList()`` method that returns a list of `Exiv2::TagInfo`_ structs.
In python-exiv2 (since v0.16.2) these structs have dict_ like behaviour, so the members can be accessed more easily:

.. code:: python

    >>> import exiv2
    >>> info = exiv2.ExifTags.tagList('Image')[0]
    >>> print(info.title_)
    Processing Software
    >>> print(info['title'])
    Processing Software
    >>> print(info.keys())
    ['tag', 'title', 'sectionId', 'desc', 'typeId', 'ifdId', 'count', 'name']
    >>> from pprint import pprint
    >>> pprint(dict(info))
    {'count': 0,
     'desc': 'The name and version of the software used to post-process the '
             'picture.',
     'ifdId': <IfdId.ifd0Id: 1>,
     'name': 'ProcessingSoftware',
     'sectionId': <SectionId.otherTags: 4>,
     'tag': 11,
     'title': 'Processing Software',
     'typeId': <TypeId.asciiString: 2>}

Note that struct member names ending with an underscore have the underscore removed in the dict_ like interface.

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

In earlier versions of python-gphoto2 you could set the type of value returned by ``value()`` or ``getValue()`` by passing an ``exiv2.TypeId`` parameter:

.. code:: python

    datum = exifData['Exif.Photo.UserComment']
    value = datum.value(exiv2.TypeId.comment)
    result = value.comment()

Since version 0.16.0 the returned value is always of the correct type and this parameter is ignored.

Writing data values
-------------------

The simplest way to set metadata is by assigning a value to the metadatum:

.. code:: python

    exifData['Exif.Image.ImageDescription'] = 'Uncle Fred at the seaside'
    iptcData['Iptc.Application2.Caption'] = 'Uncle Fred at the seaside'
    xmpData['Xmp.dc.description'] = 'Uncle Fred at the seaside'

The datum is created if it doesn't already exist and its value is set to the text.

Setting the type
^^^^^^^^^^^^^^^^

Metadata values have a type, for example Exif values can be ``Ascii``, ``Short``, ``Rational`` etc.
When a datum is created its type is set to the default for the key, so ``exifData['Exif.Image.ImageDescription']`` is set to ``Ascii``.
If a datum already exists, its current type is not changed by assigning a string value.

If you need to force the type of a datum (e.g. because it currently has the wrong type) you can create a value of the correct type and assign it:

.. code:: python

    exifData['Exif.Image.ImageDescription'] = exiv2.AsciiValue('Uncle Fred at the seaside')

Numerical data
^^^^^^^^^^^^^^

Setting string values as above is OK for text data such as Exif's Ascii or XMP's XmpText, but less suitable for numeric data such as GPS coordinates.
These can be set from a string, but it is better to use numeric data:

.. code:: python

    exifData['Exif.GPSInfo.GPSLatitude'] = '51/1 30/1 4910/1000'
    exifData['Exif.GPSInfo.GPSLatitude'] = ((51, 1), (30, 1), (4910, 1000))

In the first line the exiv2 library converts the string ``'51/1 30/1 4910/1000'`` to three (numerator, denominator) pairs.
In the second line the three pairs are supplied as integer numbers and no conversion is needed.
This is potentially quicker and more accurate.
(The Python Fraction_ type is very useful for dealing with rational numbers like these.)

Structured data
^^^^^^^^^^^^^^^

Some XMP data is more complicated to deal with.
For example, the locations shown in a photograph can be stored as a group of structures, each containing location/city/country information.
Exiv2 gives these complex tag names like ``Xmp.iptcExt.LocationShown[1]/Iptc4xmpExt:City``.

Data like this is written in several stages.
First create the array ``Xmp.iptcExt.LocationShown``:

.. code:: python

    tmp = exiv2.XmpTextValue()
    tmp.setXmpArrayType(exiv2.XmpValue.XmpArrayType.xaBag)
    xmpData['Xmp.iptcExt.LocationShown'] = tmp

Then create a structured data container for the first element in the array: 

.. code:: python

    tmp = exiv2.XmpTextValue()
    tmp.setXmpStruct()
    xmpData['Xmp.iptcExt.LocationShown[1]'] = tmp

Then write individual items in the structure:

.. code:: python

    xmpData['Xmp.iptcExt.LocationShown[1]/Iptc4xmpExt:City'] = 'London'
    xmpData['Xmp.iptcExt.LocationShown[1]/Iptc4xmpExt:Sublocation'] = 'Buckingham Palace'

This can potentially be nested to any depth.

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

Buffer interface
----------------

The ``Exiv2::DataBuf``, ``Exiv2::PreviewImage``, and ``Exiv2::BasicIO`` classes are all wrappers around a potentially large block of memory.
They each have methods to access that memory without copying, such as ``Exiv2::DataBuf::data()`` and ``Exiv2::BasicIo::mmap()`` but in Python these classes also expose a `buffer interface`_. This allows them to be used almost anywhere that a `bytes-like object`_ is expected.

For example, you could save a photograph's thumbnail in a separate file like this:

.. code:: python

    thumb = exiv2.ExifThumb(image.exifData())
    with open('thumbnail.jpg', 'wb') as out_file:
        out_file.write(thumb.copy())

Image data in memory
--------------------

The `Exiv2::ImageFactory`_ class has a method ``open(const byte *data, size_t size)`` to create an `Exiv2::Image`_ from data stored in memory, rather than in a file.
In python-exiv2 the ``data`` and ``size`` parameters are replaced with a single `bytes-like object`_ such as bytes_ or bytearray_.
The buffered data isn't actually read until ``Image::readMetadata`` is called, so python-exiv2 stores a reference to the buffer to stop the user accidentally deleting it.

When ``Image::writeMetadata`` is called exiv2 allocates a new block of memory to store the modified data.
The ``Image::io`` method returns an `Exiv2::BasicIo`_ object that provides access to this data.

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

The modified data is written back to the file or memory buffer when the memoryview_ is released.

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
.. _Exiv2::ExifTags:
    https://exiv2.org/doc/classExiv2_1_1ExifTags.html
.. _Exiv2::ExifThumb::setJpegThumbnail:
    https://exiv2.org/doc/classExiv2_1_1ExifThumb.html
.. _Exiv2::Image:
    https://exiv2.org/doc/classExiv2_1_1Image.html
.. _Exiv2::ImageFactory:
    https://exiv2.org/doc/classExiv2_1_1ImageFactory.html
.. _Exiv2::Metadatum:
    https://exiv2.org/doc/classExiv2_1_1Metadatum.html
.. _Exiv2::TagInfo:
    https://exiv2.org/doc/structExiv2_1_1TagInfo.html
.. _Exiv2::TypeId:
    https://exiv2.org/doc/namespaceExiv2.html#a5153319711f35fe81cbc13f4b852450c
.. _Exiv2::Value:
    https://exiv2.org/doc/classExiv2_1_1Value.html
.. _Exiv2::ValueType< T >:
    https://exiv2.org/doc/classExiv2_1_1ValueType.html
.. _Fraction:
    https://docs.python.org/3/library/fractions.html
.. _libexiv2:
    https://www.exiv2.org/doc/index.html
.. _list:
    https://docs.python.org/3/library/stdtypes.html#list
.. _memoryview:
    https://docs.python.org/3/library/stdtypes.html#memoryview
.. _PyPI:
    https://pypi.org/project/exiv2/
