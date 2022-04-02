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

%module(package="exiv2") datasets

%include "preamble.i"

%import "metadatum.i"

wrap_auto_unique_ptr(Exiv2::IptcKey);

%ignore Exiv2::RecordInfo::RecordInfo;
%ignore Exiv2::DataSet::DataSet;
%ignore Exiv2::IptcDataSets::dataSetList;
%ignore Exiv2::IptcDataSets::IptcDataSets;
#if EXIV2_VERSION_HEX >= 0x01000000
  %ignore Exiv2::IptcDataSets::recordId;
#endif

%immutable;
%include "exiv2/datasets.hpp"
%mutable;
