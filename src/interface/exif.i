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

%module(package="exiv2") exif

%include "preamble.i"

%include "pybuffer.i"
%include "stdint.i"
%include "std_string.i"
#ifndef SWIGIMPORTED
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif
#endif

%import "metadatum.i"
%import "tags.i"

%pybuffer_binary(const Exiv2::byte* buf, long size)
%typecheck(SWIG_TYPECHECK_POINTER) const Exiv2::byte* {
    $1 = PyObject_CheckBuffer($input);
}

#ifndef SWIGIMPORTED
DATA_MAPPING_METHODS(ExifData, Exiv2::ExifData, Exiv2::Exifdatum, Exiv2::ExifKey,
                     Exiv2::ExifKey(datum->key()).defaultTypeId())
DATA_ITERATOR(ExifData, Exiv2::ExifData, Exiv2::ExifData::iterator,
              Exiv2::Exifdatum)
// Get definition of ExifDataWrap so ExifThumb constructor can be passed
// either ExifDataWrap or Exiv2::ExifData
DATA_WRAPPER_DEC(ExifData, Exiv2::ExifData, Exiv2::Exifdatum, Exiv2::ExifKey)
#endif

%ignore Exiv2::ExifData::operator[];
%ignore Exiv2::ExifData::begin() const;
%ignore Exiv2::ExifData::end() const;
%ignore Exiv2::ExifData::findKey(ExifKey const &) const;
%ignore Exiv2::ExifParser;

%include "exiv2/exif.hpp"
