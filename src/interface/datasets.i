// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
%include "shared/static_list.i"
%include "shared/unique_ptr.i"

%import "metadatum.i"

UNIQUE_PTR(Exiv2::IptcKey);

// IptcDataSets::application2RecordList and IptcDataSets::envelopeRecordList
// return a static list as a pointer
%fragment("struct_to_dict"{Exiv2::DataSet}, "header") {
static PyObject* struct_to_dict(const Exiv2::DataSet* info) {
    return Py_BuildValue("{si,ss,ss,ss,sN,sN,si,si,si,si,ss}",
        "number",     info->number_,
        "name",       info->name_,
        "title",      info->title_,
        "desc",       info->desc_,
        "mandatory",  PyBool_FromLong(info->mandatory_),
        "repeatable", PyBool_FromLong(info->repeatable_),
        "minbytes",   info->minbytes_,
        "maxbytes",   info->maxbytes_,
        "type",       info->type_,
        "recordId",   info->recordId_,
        "photoshop",  info->photoshop_);

};
}
LIST_POINTER(const Exiv2::DataSet*, Exiv2::DataSet, number_ != 0xffff)

%ignore Exiv2::DataSet;
%ignore Exiv2::IptcDataSets::dataSetList;
%ignore Exiv2::IptcDataSets::IptcDataSets;
%ignore Exiv2::RecordInfo;

%immutable;
%include "exiv2/datasets.hpp"
%mutable;
