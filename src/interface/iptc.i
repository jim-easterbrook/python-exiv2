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

%module(package="exiv2") iptc

#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=389     // operator[] ignored (consider using %extend)

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "datasets.i"
%import "metadatum.i"

GETITEM(Exiv2::IptcData, Exiv2::Iptcdatum)
SETITEM(Exiv2::IptcData, Exiv2::Iptcdatum, Exiv2::IptcKey,
        IptcDataSets::dataSetType(datum->tag(), datum->record()))
ITERATOR(Exiv2::IptcData, Exiv2::Iptcdatum, IptcDataIterator)
STR(Exiv2::Iptcdatum, toString)

%ignore Exiv2::IptcData::begin() const;
%ignore Exiv2::IptcData::end() const;
%ignore Exiv2::IptcData::findKey(IptcKey const &) const;
%ignore Exiv2::IptcData::findId(uint16_t) const;
%ignore Exiv2::IptcData::findId(uint16_t,uint16_t) const;
%ignore Exiv2::IptcData::printStructure;
%ignore Exiv2::IptcParser;

%include "exiv2/iptc.hpp"
