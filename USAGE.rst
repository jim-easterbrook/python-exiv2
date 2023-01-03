Hints and tips
==============

Here are some ideas on how to use with python-exiv2.
In many cases there's more than one way to do it, but some ways are more "Pythonic" than others.
Some of this is only applicable to python-exiv2 v0.13.0 onwards.
You can find out what version of python-exiv2 you have with either ``pip3 show exiv2`` or ``python3 -m exiv2``.

.. contents::
    :backlinks: top

Segmentation faults
-------------------

There are many places in the C++ API where objects hold references to data in other objects.
This is more efficient than copying the data, but can cause segmentation faults if an object is deleted while another objects refers to its data.

The Python interface tries to protect the user from this but in some cases this is not possible.
For example, an `Exiv2::Metadatum`_ object holds a reference to data that can easily be invalidated:

.. code:: python

    exifData = image.exifData()
    datum = exifData['Exif.GPSInfo.GPSLatitude']
    print(str(datum.value()))                       # no problem
    del exifData['Exif.GPSInfo.GPSLatitude']
    print(str(datum.value()))                       # segfault!

Segmentation faults are also easily caused by careless use of iterators, as discussed below.
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
The Python interface uses the value's ``typeId()`` method to determine its type and casts the return value to the appropriate type.

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

Binary data buffers
-------------------

Some libexiv2 functions, e.g. `Exiv2::ExifThumb::setJpegThumbnail`_, have an ``Exiv2::byte*`` parameter and a length parameter.
In python-exiv2 these are replaced by a single parameter that can be any Python object that exposes a simple `buffer interface`_, e.g. bytes_, bytearray_, memoryview_:

.. code:: python

    pil_im = PIL.Image.open('IMG_9999.JPG')
    pil_im.thumbnail((160, 120), PIL.Image.ANTIALIAS)
    data = io.BytesIO()
    pil_im.save(data, 'JPEG')
    thumb = exiv2.ExifThumb(image.exifData())
    thumb.setJpegThumbnail(data.getbuffer())

Some libexiv2 functions, e.g. `Exiv2::DataBuf::data`_, return ``Exiv2::byte*``, a pointer to a block of memory.
In python-exiv2 this is converted to an object with a buffer interface, which allows the data to be accessed without unnecessary copying:

.. code:: python

    thumb = exiv2.ExifThumb(image.exifData())
    buf = thumb.copy()
    thumb_im = PIL.Image.open(io.BytesIO(buf.data()))

A Python memoryview_ can be used to access the data without copying.

Exiv2::BasicIo::mmap
--------------------

The `Exiv2::BasicIo::mmap`_ method allows access to the image file data without unnecessary copying.
However it is rather error prone, crashing your Python program with a segmentation fault if anything goes wrong.
It should only be used with exiv2 images created from a data buffer.

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
    image.writedata()
    with get_file_data(image) as data:
        rsp = requests.post(url, files={'file': io.BytesIO(data)})




.. _bytearray:         https://docs.python.org/3/library/stdtypes.html#bytearray
.. _bytes:             https://docs.python.org/3/library/stdtypes.html#bytes
.. _buffer interface:  https://docs.python.org/3/c-api/buffer.html
.. _context manager:
    https://docs.python.org/3/reference/datamodel.html#context-managers
.. _dict:              https://docs.python.org/3/library/stdtypes.html#dict
.. _Exiv2::BasicIo::mmap: https://exiv2.org/doc/classExiv2_1_1BasicIo.html
.. _Exiv2::DataBuf::data: https://exiv2.org/doc/classExiv2_1_1DataBuf.html
.. _Exiv2::ExifThumb::setJpegThumbnail:
    https://exiv2.org/doc/classExiv2_1_1ExifThumb.html
.. _Exiv2::Metadatum: https://exiv2.org/doc/classExiv2_1_1Metadatum.html
.. _Exiv2::Value: https://exiv2.org/doc/classExiv2_1_1Value.html
.. _Exiv2::ValueType< T >: https://exiv2.org/doc/classExiv2_1_1ValueType.html
.. _list:              https://docs.python.org/3/library/stdtypes.html#list
.. _memoryview:        https://docs.python.org/3/library/stdtypes.html#memoryview
