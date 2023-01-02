// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

#pragma SWIG nowarn=321     // 'open' conflicts with a built-in name in python

%include "preamble.i"

%include "std_string.i"
#ifndef SWIGIMPORTED
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif
#endif

%import "basicio.i";
%import "exif.i";
%import "iptc.i";
%import "tags.i";
%import "xmp.i";

wrap_auto_unique_ptr(Exiv2::Image);

INPUT_BUFFER_RO(const Exiv2::byte* data, long size)

// Potentially blocking calls allow Python threads
%thread Exiv2::Image::readMetadata;
%thread Exiv2::Image::writeMetadata;
%thread Exiv2::ImageFactory::create;
%thread Exiv2::ImageFactory::open;

// exifData(), iptcData(), and xmpData() return values need to keep a
// reference to Image.
KEEP_REFERENCE(Exiv2::ExifData&)
KEEP_REFERENCE(Exiv2::IptcData&)
KEEP_REFERENCE(Exiv2::XmpData&)

// xmpPacket() returns a modifiable std::string, Python strings are immutable
// so treat it as a non-modifiable std::string
%apply const std::string& {std::string& xmpPacket};

// Make image types available
#ifdef EXV_ENABLE_BMFF
#define BMFF "bmff", int(Exiv2::ImageType::bmff),
#else
#define BMFF
#endif

ENUM(ImageType, "Supported image formats.",
        "bmp",  int(Exiv2::ImageType::bmp),
        BMFF
        "cr2",  int(Exiv2::ImageType::cr2),
        "crw",  int(Exiv2::ImageType::crw),
        "eps",  int(Exiv2::ImageType::eps),
        "exv",  int(Exiv2::ImageType::exv),
        "gif",  int(Exiv2::ImageType::gif),
        "jp2",  int(Exiv2::ImageType::jp2),
        "jpeg", int(Exiv2::ImageType::jpeg),
        "mrw",  int(Exiv2::ImageType::mrw),
        "none", int(Exiv2::ImageType::none),
        "orf",  int(Exiv2::ImageType::orf),
        "pgf",  int(Exiv2::ImageType::pgf),
        "png",  int(Exiv2::ImageType::png),
        "psd",  int(Exiv2::ImageType::psd),
        "raf",  int(Exiv2::ImageType::raf),
        "rw2",  int(Exiv2::ImageType::rw2),
        "tga",  int(Exiv2::ImageType::tga),
        "tiff", int(Exiv2::ImageType::tiff),
        "xmp",  int(Exiv2::ImageType::xmp));
%ignore Exiv2::ImageType::none;

// Ignore const versions of methods
%ignore Exiv2::Image::exifData() const;
%ignore Exiv2::Image::iptcData() const;
%ignore Exiv2::Image::xmpData() const;
%ignore Exiv2::Image::xmpPacket() const;

// Ignore stuff Python can't use
#if EXIV2_VERSION_HEX < 0x01000000
%ignore Exiv2::ImageFactory::create(int, BasicIo::AutoPtr);
%ignore Exiv2::ImageFactory::open(BasicIo::AutoPtr);
#else
%ignore Exiv2::ImageFactory::create(ImageType, BasicIo::UniquePtr);
%ignore Exiv2::ImageFactory::open(BasicIo::UniquePtr);
#endif  // EXIV2_VERSION_HEX
%ignore Exiv2::Image::printStructure;
%ignore Exiv2::Image::printTiffStructure;
%ignore Exiv2::Image::printIFDStructure;
%ignore Exiv2::PrintStructureOption;
%ignore Exiv2::append;

// Ignore low level stuff Python doesn't need access to
%ignore Exiv2::NativePreview;
%ignore Exiv2::NativePreviewList;
%ignore Exiv2::Image::nativePreviews;
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

#if EXIV2_VERSION_HEX >= 0x01000000
%include "exiv2/image_types.hpp"
#endif

%include "exiv2/image.hpp"

// Include enableBMFF function added in libexiv2 0.27.4
#if EXIV2_VERSION_HEX >= 0x001b0400
#undef EXV_ENABLE_BMFF // Don't need any of the other stuff in bmffimage.hpp
%include "exiv2/bmffimage.hpp"
#endif
