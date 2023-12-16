// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/containers.i"
%include "shared/data_iterator.i"

%include "stdint.i"
%include "std_string.i"
#ifndef SWIGIMPORTED
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif
#endif

%import "metadatum.i"
%import "tags.i"

// ExifThumb keeps a reference to the ExifData it uses
%typemap(ret) Exiv2::ExifThumb* %{
    if ($result != Py_None) {
        if (PyObject_SetAttrString($result, "_refers_to", swig_obj[0])) {
            SWIG_fail;
        }
    }
%}

#if EXIV2_VERSION_HEX < 0x001c0000
INPUT_BUFFER_RO(const Exiv2::byte* buf, long size)
#else
INPUT_BUFFER_RO(const Exiv2::byte* buf, size_t size)
#endif

EXTEND_METADATUM(Exiv2::Exifdatum)

DATA_ITERATOR_TYPEMAPS(ExifData_iterator, Exiv2::ExifData::iterator)
#ifndef SWIGIMPORTED
DATA_ITERATOR_CLASSES(
    ExifData_iterator, Exiv2::ExifData::iterator, Exiv2::Exifdatum)
#endif

DATA_CONTAINER(Exiv2::ExifData, Exiv2::Exifdatum, Exiv2::ExifKey)

// Ignore const overloads of some methods
%ignore Exiv2::ExifData::operator[];
%ignore Exiv2::ExifData::begin() const;
%ignore Exiv2::ExifData::end() const;
%ignore Exiv2::ExifData::findKey(ExifKey const &) const;
%ignore Exiv2::ExifParser;

// Exifdatum::ifdId is documented as internal use only
%ignore Exiv2::Exifdatum::ifdId;

%include "exiv2/exif.hpp"
