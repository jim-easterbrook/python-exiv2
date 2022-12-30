// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "datasets.i"
%import "metadatum.i"

EXTEND_METADATUM(Exiv2::Iptcdatum)

DATA_ITERATOR_TYPEMAPS(IptcData_iterator, Exiv2::IptcData::iterator)
#ifndef SWIGIMPORTED
DATA_ITERATOR_CLASSES(
    IptcData_iterator, Exiv2::IptcData::iterator, Exiv2::Iptcdatum)
#endif

DATA_CONTAINER(Exiv2::IptcData, Exiv2::Iptcdatum, Exiv2::IptcKey,
    Exiv2::IptcDataSets::dataSetType(datum->tag(), datum->record()))

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
