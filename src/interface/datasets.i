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

%module(package="exiv2") datasets

#ifndef SWIGIMPORTED
%constant char* __doc__ = "IPTC key class and data attributes.";
#endif

%include "shared/preamble.i"
%include "shared/enum.i"
%include "shared/exception.i"
%include "shared/static_list.i"
%include "shared/struct_dict.i"
%include "shared/unique_ptr.i"

%import "metadatum.i"

IMPORT_ENUM(TypeId)

// Catch some C++ exceptions
%exception;
EXCEPTION(Exiv2::IptcDataSets::dataSet)
EXCEPTION(Exiv2::IptcDataSets::recordId)
EXCEPTION(Exiv2::IptcKey::IptcKey(std::string))
EXCEPTION(Exiv2::IptcKey::IptcKey(std::string const &))

EXTEND_KEY(Exiv2::IptcKey);

// IptcDataSets::application2RecordList and IptcDataSets::envelopeRecordList
// return a static list as a pointer
LIST_POINTER(const Exiv2::DataSet*, Exiv2::DataSet, number_ != 0xffff)

// Give Exiv2::DataSet dict-like behaviour
STRUCT_DICT(Exiv2::DataSet)

// Structs are all static data
%ignore Exiv2::IptcDataSets::IptcDataSets;
%ignore Exiv2::IptcDataSets::~IptcDataSets;
%ignore Exiv2::DataSet::DataSet;
%ignore Exiv2::DataSet::~DataSet;

// Ignore stuff that Python can't use or doesn't need
%ignore Exiv2::Dictionary;
%ignore Exiv2::Dictionary_i;
%ignore Exiv2::IptcDataSets::dataSetList;
%ignore Exiv2::RecordInfo;
%ignore Exiv2::StringSet;
%ignore Exiv2::StringSet_i;
%ignore Exiv2::StringVector;
%ignore Exiv2::StringVector_i;
%ignore Exiv2::Uint32Vector;
%ignore Exiv2::Uint32Vector_i;

%immutable;
%include "exiv2/datasets.hpp"
%mutable;
