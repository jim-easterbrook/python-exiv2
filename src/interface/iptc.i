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

%module(package="exiv2") iptc

#ifndef SWIGIMPORTED
%constant char* __doc__ = "IPTC metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/containers.i"

%include "stdint.i"
%include "std_string.i"

%import "datasets.i"

// Add inheritance diagrams to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Metadatum
    :top-classes: exiv2.metadatum.Metadatum
    :parts: 1
    :include-subclasses:

.. inheritance-diagram:: exiv2.iptc.Iptcdatum_pointer
    :top-classes: exiv2.iptc.Iptcdatum_pointer
    :parts: 1
    :include-subclasses:
'''
%}

IMPORT_ENUM(types, ByteOrder)
IMPORT_ENUM(types, TypeId)

// Catch all C++ exceptions
EXCEPTION()

// Get the current (or default if not set) type id of a datum
%fragment("get_type_id"{Exiv2::Iptcdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Iptcdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::IptcDataSets::dataSetType(datum->tag(), datum->record());
};
}

DATA_CONTAINER(IptcData, Iptcdatum, IptcKey)

// Exiv2 have deprecated recordName()
// deprecated in python-exiv2 2025-09-17
EXIV2_DEPRECATED(Exiv2::Iptcdatum::recordName)

// Ignore const overloads of some methods
%ignore Exiv2::IptcData::operator[];
%ignore Exiv2::IptcData::begin() const;
%ignore Exiv2::IptcData::end() const;
%ignore Exiv2::IptcData::findKey(IptcKey const &) const;
%ignore Exiv2::IptcData::findId(uint16_t) const;
%ignore Exiv2::IptcData::findId(uint16_t,uint16_t) const;
%ignore Exiv2::IptcData::printStructure;
%ignore Exiv2::IptcParser;

%include "exiv2/iptc.hpp"
