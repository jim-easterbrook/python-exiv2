// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") xmp

#ifndef SWIGIMPORTED
%constant char* __doc__ = "XMP metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/containers.i"
%include "shared/data_iterator.i"
%include "shared/enum.i"
%include "shared/exception.i"

%include "stdint.i"
%include "std_string.i"

%import "properties.i"

IMPORT_ENUM(ByteOrder)
IMPORT_ENUM(TypeId)

// Catch all C++ exceptions
EXCEPTION()

EXTEND_METADATUM(Exiv2::Xmpdatum)

DATA_ITERATOR_TYPEMAPS(XmpData)
#ifndef SWIGIMPORTED
DATA_ITERATOR_CLASSES(XmpData, Xmpdatum)
#endif

// Get the current (or default if not set) type id of a datum
%fragment("get_type_id"{Exiv2::Xmpdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Xmpdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::XmpProperties::propertyType(Exiv2::XmpKey(datum->key()));
};
}

DATA_CONTAINER(Exiv2::XmpData, Exiv2::Xmpdatum, Exiv2::XmpKey)

// Ignore const overloads of some methods
%ignore Exiv2::XmpData::operator[];
%ignore Exiv2::XmpData::begin() const;
%ignore Exiv2::XmpData::end() const;
%ignore Exiv2::XmpData::findKey(XmpKey const &) const;
%ignore Exiv2::XmpParser::decode;
%ignore Exiv2::XmpParser::encode;

%include "exiv2/xmp_exiv2.hpp"
