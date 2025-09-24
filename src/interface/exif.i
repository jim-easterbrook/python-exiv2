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

%module(package="exiv2") exif

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exif metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/containers.i"
%include "shared/keep_reference.i"
%include "shared/windows.i"

%include "stdint.i"
%include "std_string.i"

%import "tags.i"

// Add inheritance diagrams to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Metadatum
    :top-classes: exiv2.metadatum.Metadatum
    :parts: 1
    :include-subclasses:

.. inheritance-diagram:: exiv2.exif.Exifdatum_pointer
    :top-classes: exiv2.exif.Exifdatum_pointer
    :parts: 1
    :include-subclasses:
'''
%}

// Catch all C++ exceptions
EXCEPTION()

EXV_ENABLE_FILESYSTEM_FUNCTION(Exiv2::ExifThumb::setJpegThumbnail(
    const std::string&))
EXV_ENABLE_FILESYSTEM_FUNCTION(Exiv2::ExifThumb::setJpegThumbnail(
    const std::string&, URational, URational, uint16_t))
EXV_ENABLE_FILESYSTEM_FUNCTION(Exiv2::ExifThumbC::writeFile)

// ExifThumb keeps a reference to the ExifData it uses
KEEP_REFERENCE_EX(Exiv2::ExifThumb*, args)

INPUT_BUFFER_RO(const Exiv2::byte* buf, BUFLEN_T size)

DATA_CONTAINER(ExifData, Exifdatum, ExifKey,
    Exiv2::ExifKey(datum->key()).defaultTypeId())

// Convert path encoding on Windows
WINDOWS_PATH(const std::string& path)

// Ignore const overloads of some methods
%ignore Exiv2::ExifData::operator[];
%ignore Exiv2::ExifData::begin() const;
%ignore Exiv2::ExifData::end() const;
%ignore Exiv2::ExifData::findKey(ExifKey const &) const;
%ignore Exiv2::ExifParser;

// Exifdatum::ifdId is documented as internal use only
%ignore Exiv2::Exifdatum::ifdId;

#define EXV_ENABLE_FILESYSTEM
%include "exiv2/exif.hpp"
#undef EXV_ENABLE_FILESYSTEM
