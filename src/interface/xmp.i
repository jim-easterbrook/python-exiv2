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

%module(package="exiv2") xmp

#ifndef SWIGIMPORTED
%constant char* __doc__ = "XMP metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/containers.i"

%include "stdint.i"
%include "std_string.i"

%import "properties.i"

// Add inheritance diagrams to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Metadatum
    :top-classes: exiv2.metadatum.Metadatum
    :parts: 1
    :include-subclasses:

.. inheritance-diagram:: exiv2.xmp.Xmpdatum_pointer
    :top-classes: exiv2.xmp.Xmpdatum_pointer
    :parts: 1
    :include-subclasses:
'''
%}

IMPORT_ENUM(types, ByteOrder)
IMPORT_ENUM(types, TypeId)

// Catch all C++ exceptions
EXCEPTION()

DATA_CONTAINER(XmpData, Xmpdatum, XmpKey,
    Exiv2::XmpProperties::propertyType(Exiv2::XmpKey(datum->key())))

// Ignore const overloads of some methods
%ignore Exiv2::XmpData::begin() const;
%ignore Exiv2::XmpData::end() const;
%ignore Exiv2::XmpData::findKey(XmpKey const &) const;

// Ignore other stuff Python doesn't need or can't use
%ignore Exiv2::operatorHelper;
%ignore Exiv2::XmpData::operator[];
%ignore Exiv2::XmpParser::decode;
%ignore Exiv2::XmpParser::encode;

%include "exiv2/xmp_exiv2.hpp"
