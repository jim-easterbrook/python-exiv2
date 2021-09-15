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

%module(package="exiv2") xmp

#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=389     // operator[] ignored (consider using %extend)

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "metadatum.i"
%import "properties.i"

GETITEM(Exiv2::XmpData, Exiv2::Xmpdatum)
SETITEM(Exiv2::XmpData, Exiv2::Xmpdatum,
        Exiv2::XmpKey, XmpProperties::propertyType(XmpKey(key)))
ITERATOR(Exiv2::XmpData, Exiv2::Xmpdatum, XmpDataIterator)
STR(Exiv2::Xmpdatum, toString)

%ignore Exiv2::XmpData::begin() const;
%ignore Exiv2::XmpData::end() const;
%ignore Exiv2::XmpData::findKey(XmpKey const &) const;
%ignore Exiv2::XmpParser::decode;
%ignore Exiv2::XmpParser::encode;

#if EXIV2_VERSION_HEX >= 0x001b0000
%include "exiv2/xmp_exiv2.hpp"
#else
%include "exiv2/xmp.hpp"
#endif
