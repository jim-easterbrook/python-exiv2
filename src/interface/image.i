// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

%module(package="exiv2", threads="1") image
%nothread;

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Image & ImageFactory classes.";
#endif

#pragma SWIG nowarn=321 // 'open' conflicts with a built-in name in python

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/keep_reference.i"
%include "shared/private_data.i"
%include "shared/windows.i"

%include "std_string.i"

%import "basicio.i";
%import "exif.i";
%import "iptc.i";
%import "xmp.i";

// Add enum table to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. rubric:: Enums

.. autosummary::

    ImageType
'''
%}

// Catch all C++ exceptions
EXCEPTION()

EXV_ENABLE_FILESYSTEM_FUNCTION(Exiv2::ImageFactory::create(
    ImageType, const std::string&))

UNIQUE_PTR(Exiv2::Image);

// Potentially blocking calls allow Python threads
%thread Exiv2::Image::readMetadata;
%thread Exiv2::Image::writeMetadata;
%thread Exiv2::ImageFactory::create;
%thread Exiv2::ImageFactory::open;

// ImageFactory can open image or get type from a buffer
INPUT_BUFFER_RO(const Exiv2::byte* data, BUFLEN_T size,
                ImageFactory_open, ImageFactory_createIo)

// Release memory buffer after writeMetadata, as it creates its own copy
RELEASE_BUFFER(void writeMetadata)

// Add Image::data() method for easy data access to image data
%feature("docstring") Exiv2::Image::data
"Easy access to the image data.

Calls io().open() & io().mmap() and returns a Python memoryview of the
data. io().munmap() & io().close() are called when the memoryview object
is deleted.

This is intended to replace using Image.io() to get a BasicIo object,
then accessing its data. BasicIo will eventually be removed from the
Python interface.

:rtype: memoryview"
%extend Exiv2::Image {
    %fragment("memoryview_funcs");
    PyObject* data(PyObject* py_self) {
        Exiv2::BasicIo& io = self->io();
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        io.open();
        Exiv2::byte* ptr = io.mmap(false);
        SWIG_PYTHON_THREAD_END_ALLOW;
        PyObject* result = PyMemoryView_FromMemory(
            (char*)ptr, io.size(), PyBUF_READ);
        if (store_view(py_self, result))
            return NULL;
        return result;
    }
}
%fragment("release_ptr"{Exiv2::BasicIo});
DEFINE_VIEW_CALLBACK(Exiv2::Image, release_ptr(&self->io());)
%{
#define RELEASE_VIEWS_Image_readMetadata
#define RELEASE_VIEWS_Image_writeMetadata
%}
%typemap(check, fragment="memoryview_funcs") Exiv2::Image* self {
%#ifdef RELEASE_VIEWS_$symname
    release_views(self);
%#endif
}

// Convert path encoding on Windows
WINDOWS_PATH(const std::string& path)

// Simplify handling of default parameters
%typemap(default) bool useCurl {$1 = true;}
%ignore Exiv2::ImageFactory::createIo(std::string const &);
%ignore Exiv2::ImageFactory::createIo(std::wstring const &);
%ignore Exiv2::ImageFactory::open(std::string const &);
%ignore Exiv2::ImageFactory::open(std::wstring const &);

%typemap(default) bool bTestValid {$1 = true;}
%ignore Exiv2::Image::setIccProfile(DataBuf &);
%ignore Exiv2::Image::setIccProfile(DataBuf &&);

%typemap(default) bool enable {$1 = true;}
%ignore Exiv2::enableBMFF();

// Extend ImageFactory to allow creation of a MemIo from a buffer
%feature("docstring") Exiv2::ImageFactory::createIo "
*Overload 1:*

Create the appropriate class type implemented BasicIo based on the
protocol of the input.

\"-\" path implies the data from stdin and it is handled by StdinIo.
Http path can be handled by either HttpIo or CurlIo. Https, ftp paths
are handled by CurlIo. Ssh, sftp paths are handled by SshIo. Others are
handled by FileIo.

:type path: str
:param path: Image file.
:type useCurl: bool, optional
:param useCurl: Indicate whether the libcurl is used or not.
          If it's true, http is handled by CurlIo. Otherwise it is
          handled by HttpIo.
:rtype: :py:class:`BasicIo`
:return: A BasicIo object.
:raises: Error If the file is not found or it is unable to connect to
          the server to read the remote file.

|

*Overload 2:*

Create a MemIo subclass of BasicIo using the provided memory.

:type data: :py:term:`bytes-like object`
:param data: A data buffer.
:rtype: :py:class:`BasicIo`
:return: A BasicIo object.
"
%extend Exiv2::ImageFactory {
    static Exiv2::BasicIo::SMART_PTR createIo(
        const Exiv2::byte* data, BUFLEN_T size) {
#if EXIV2_VERSION_HEX < 0x001c0000
        return Exiv2::BasicIo::AutoPtr(new Exiv2::MemIo(data, size));
#else
        return std::make_unique<Exiv2::MemIo>(data, size);
#endif
    }
}

// Enable BMFF if libexiv2 was compiled with BMFF support
%init %{
#if defined EXV_ENABLE_BMFF && !EXIV2_TEST_VERSION(0, 28, 3)
Exiv2::enableBMFF(true);
#endif
%}

// Make enableBMFF() function available regardless of exiv2 version
%feature("docstring") enableBMFF "Enable BMFF support.

If libexiv2 has been built with BMFF support it is already enabled
and this function does nothing.
:type enable: bool, optional
:param enable: Set to True to enable BMFF file access.
:rtype: bool
:return: True if libexiv2 has been built with BMFF support.";
%inline %{
static bool enableBMFF(bool enable) {
    // deprecated since 2024-08-01
    PyErr_WarnEx(PyExc_DeprecationWarning,
        "BMFF is already enabled if libexiv2 was built with BMFF support",
        1);
#ifdef EXV_ENABLE_BMFF
    return true;
#else
    return false;
#endif // EXV_ENABLE_BMFF
}
%}

// In v0.28.x Image::setIccProfile takes ownership of its DataBuf input
// so we make a copy for it to own.
%typemap(in) Exiv2::DataBuf&& {
    $typemap(in, Exiv2::DataBuf*)
    $1 = new Exiv2::DataBuf($1->c_data(), $1->size());
}

// exifData(), iptcData(), xmpData(), and iccProfile() return values need to
// keep a reference to Image.
KEEP_REFERENCE(Exiv2::ExifData&)
KEEP_REFERENCE(Exiv2::IptcData&)
KEEP_REFERENCE(Exiv2::XmpData&)
KEEP_REFERENCE(Exiv2::DataBuf*)
KEEP_REFERENCE(Exiv2::DataBuf&)

// xmpPacket() returns a modifiable std::string, Python strings are immutable
// so treat it as a non-modifiable std::string
%apply const std::string& {std::string& xmpPacket};

#if EXIV2_VERSION_HEX < 0x001c0000
// Extend ImageType namespace with ones that don't get picked up by swig
%{
namespace Exiv2::ImageType {
    const int asf = 24;
#if !EXIV2_TEST_VERSION(0,27,4)
    const int bmff = 19;
#endif
    const int mkv = 21;
    const int qtime = 22;
    const int riff = 20;
    const int webp = 23;
}
%}
#endif

#ifndef SWIGIMPORTED
DEFINE_ENUM(ImageType,)
#else
IMPORT_ENUM(_image, ImageType)
#endif

#if EXIV2_VERSION_HEX < 0x001c0000
// Convert ImageType results and parameters from int
%apply Exiv2::ImageType {int type};
%apply Exiv2::ImageType {int getType};
%apply Exiv2::ImageType {int imageType};
#endif  // EXIV2_VERSION_HEX

// Exiv2 have deprecated supportsMetadata()
// deprecated in python-exiv2 2025-09-17
EXIV2_DEPRECATED(Exiv2::Image::supportsMetadata)

// Ignore const versions of methods
%ignore Exiv2::Image::exifData() const;
%ignore Exiv2::Image::iptcData() const;
%ignore Exiv2::Image::xmpData() const;
%ignore Exiv2::Image::xmpPacket() const;

// Python uses BasicIo's buffer interface so these methods aren't needed
%ignore Exiv2::ImageFactory::create(int, BasicIo::SMART_PTR);
%ignore Exiv2::ImageFactory::create(ImageType, BasicIo::SMART_PTR);
%ignore Exiv2::ImageFactory::open(BasicIo::SMART_PTR);

// Ignore stuff Python can't use
%ignore Exiv2::Image::printStructure;
%ignore Exiv2::Image::printTiffStructure;
%ignore Exiv2::Image::printIFDStructure;
%ignore Exiv2::PrintStructureOption;
%ignore Exiv2::append;

// Ignore low level stuff Python doesn't need access to
%ignore Exiv2::Image::appendIccProfile;
%ignore Exiv2::Image::checkIccProfile;
%ignore Exiv2::NativePreview;
%ignore Exiv2::NativePreviewList;
%ignore Exiv2::Image::nativePreviews;
%ignore Exiv2::ImageFactory::ImageFactory;
%ignore Exiv2::ImageFactory::~ImageFactory;
%ignore isBigEndianPlatform;
%ignore isLittleEndianPlatform;
%ignore isStringType;
%ignore isShortType;
%ignore isLongType;
%ignore isLongLongType;
%ignore isRationalType;
%ignore is2ByteType;
%ignore is4ByteType;
%ignore is8ByteType;
%ignore isPrintXMP;
%ignore isPrintICC;
%ignore byteSwap;
%ignore byteSwap2;
%ignore byteSwap4;
%ignore byteSwap8;

#if EXIV2_VERSION_HEX >= 0x001c0000
%include "exiv2/image_types.hpp"
#endif

%include "exiv2/image.hpp"
