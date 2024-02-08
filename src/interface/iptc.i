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

%module(package="exiv2") iptc

#ifndef SWIGIMPORTED
%constant char* __doc__ = "IPTC metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/containers.i"
%include "shared/data_iterator.i"
%include "shared/enum.i"
%include "shared/exception.i"

%include "stdint.i"
%include "std_string.i"

%import "datasets.i"

IMPORT_ENUM(ByteOrder)
IMPORT_ENUM(TypeId)

// Catch all C++ exceptions
EXCEPTION()

EXTEND_METADATUM(Exiv2::Iptcdatum)

DATA_ITERATOR_TYPEMAPS(IptcData)
#ifndef SWIGIMPORTED
DATA_ITERATOR_CLASSES(IptcData, Iptcdatum)
#endif

// Get the current (or default if not set) type id of a datum
%fragment("get_type_id"{Exiv2::Iptcdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Iptcdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::IptcDataSets::dataSetType(datum->tag(), datum->record());
};
}

DATA_CONTAINER(Exiv2::IptcData, Exiv2::Iptcdatum, Exiv2::IptcKey)

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
