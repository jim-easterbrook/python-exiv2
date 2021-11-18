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

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "metadatum.i"
%import "properties.i"

#ifndef SWIGIMPORTED
DATA_MAPPING_METHODS(XmpData, Exiv2::XmpData, Exiv2::Xmpdatum, Exiv2::XmpKey,
    Exiv2::XmpProperties::propertyType(Exiv2::XmpKey(datum->key())))
DATA_ITERATOR(XmpData, Exiv2::XmpData, Exiv2::XmpData::iterator, Exiv2::Xmpdatum)
#endif

%ignore Exiv2::XmpData::operator[];
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
