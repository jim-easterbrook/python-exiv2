// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "pybuffer.i"
%include "std_string.i"
#ifndef SWIGIMPORTED
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif
#endif

%import "exif.i";
%import "iptc.i";
%import "tags.i";
%import "xmp.i";

wrap_auto_unique_ptr(Exiv2::Image);

%pybuffer_binary(const Exiv2::byte* data, long size)
%typecheck(SWIG_TYPECHECK_POINTER) const Exiv2::byte* {
    $1 = PyObject_CheckBuffer($input);
}

// Potentially blocking calls allow Python threads
%thread Exiv2::Image::readMetadata;
%thread Exiv2::Image::writeMetadata;
%thread Exiv2::ImageFactory::create;
%thread Exiv2::ImageFactory::open;

// Wrap data classes, duplicate of definitions in exif.i etc.
#ifndef SWIGIMPORTED
DATA_ITERATOR(ExifData, Exifdatum)
DATA_LISTMAP(ExifData, Exifdatum, ExifKey, ExifKey(key).defaultTypeId())

DATA_ITERATOR(IptcData, Iptcdatum)
DATA_LISTMAP(IptcData, Iptcdatum, IptcKey,
             IptcDataSets::dataSetType(datum->tag(), datum->record()))

DATA_ITERATOR(XmpData, Xmpdatum)
DATA_LISTMAP(XmpData, Xmpdatum, XmpKey,
             XmpProperties::propertyType(XmpKey(key)))

%rename(exifData) Exiv2::Image::exifDataEx;
%rename(iptcData) Exiv2::Image::iptcDataEx;
%rename(xmpData) Exiv2::Image::xmpDataEx;

%ignore Exiv2::Image::exifData;
%ignore Exiv2::Image::iptcData;
%ignore Exiv2::Image::xmpData;

%newobject Exiv2::Image::exifDataEx;
%newobject Exiv2::Image::iptcDataEx;
%newobject Exiv2::Image::xmpDataEx;

%typemap(in, numinputs=0) PyObject* image %{
    $1 = self;
%}

%extend Exiv2::Image {
    ExifDataWrap* exifDataEx(PyObject* image) {
        return new ExifDataWrap($self->exifData(), image);
    }
    IptcDataWrap* iptcDataEx(PyObject* image) {
        return new IptcDataWrap($self->iptcData(), image);
    }
    XmpDataWrap* xmpDataEx(PyObject* image) {
        return new XmpDataWrap($self->xmpData(), image);
    }
}

#endif


// Make image types available
#ifdef EXV_ENABLE_BMFF
#define BMFF bmff = Exiv2::ImageType::bmff,
#else
#define BMFF
#endif

ENUM(ImageType, "Supported image formats.",
        bmp =   Exiv2::ImageType::bmp,
        BMFF
        cr2 =   Exiv2::ImageType::cr2,
        crw =   Exiv2::ImageType::crw,
        eps =   Exiv2::ImageType::eps,
        exv =   Exiv2::ImageType::exv,
        gif =   Exiv2::ImageType::gif,
        jp2 =   Exiv2::ImageType::jp2,
        jpeg =  Exiv2::ImageType::jpeg,
        mrw =   Exiv2::ImageType::mrw,
        none =  Exiv2::ImageType::none,
        orf =   Exiv2::ImageType::orf,
        pgf =   Exiv2::ImageType::pgf,
        png =   Exiv2::ImageType::png,
        psd =   Exiv2::ImageType::psd,
        raf =   Exiv2::ImageType::raf,
        rw2 =   Exiv2::ImageType::rw2,
        tga =   Exiv2::ImageType::tga,
        tiff =  Exiv2::ImageType::tiff,
        xmp =   Exiv2::ImageType::xmp);
%ignore Exiv2::ImageType::none;

// Ignore const versions of methods
%ignore Exiv2::Image::exifData() const;
%ignore Exiv2::Image::iptcData() const;
%ignore Exiv2::Image::xmpData() const;
%ignore Exiv2::Image::xmpPacket() const;

// Ignore stuff Python can't use
%ignore Exiv2::Image::printStructure;
%ignore Exiv2::Image::printTiffStructure;
%ignore Exiv2::Image::printIFDStructure;
%ignore Exiv2::PrintStructureOption;
%ignore Exiv2::append;

// Ignore anything using BasicIo - we only need higher level stuff
%ignore Exiv2::Image::io;
%ignore Exiv2::ImageFactory::createIo;
%ignore Exiv2::ImageFactory::open(BasicIo::AutoPtr);
%ignore Exiv2::ImageFactory::open(BasicIo::UniquePtr);
%ignore Exiv2::ImageFactory::create(int, BasicIo::AutoPtr);
%ignore Exiv2::ImageFactory::create(int, BasicIo::UniquePtr);
%ignore Exiv2::ImageFactory::getType(BasicIo&);
%ignore Exiv2::ImageFactory::checkType;

%include "exiv2/image.hpp"

// Include enableBMFF function added in libexiv2 0.27.4
#if EXIV2_VERSION_HEX >= 0x001b0400
#undef EXV_ENABLE_BMFF // Don't need any of the other stuff in bmffimage.hpp
%include "exiv2/bmffimage.hpp"
#endif
