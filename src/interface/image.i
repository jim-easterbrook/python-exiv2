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

// Make image types available
ENUM(ImageType,
        bmp =   Exiv2::ImageType::bmp,
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
