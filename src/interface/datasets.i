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
LIST_POINTER(const Exiv2::DataSet*, Exiv2::DataSet, number_ != 0xffff,)

// Make Exiv2::DataSet struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::DataSet::__iter__;
%noexception Exiv2::DataSet::__iter__;
%extend Exiv2::DataSet {
    PyObject* __iter__() {
        return PySeqIter_New(Py_BuildValue(
            "((si)(ss)(ss)(ss)(sN)(sN)(si)(si)(si)(si)(ss))",
            "number",     $self->number_,
            "name",       $self->name_,
            "title",      $self->title_,
            "desc",       $self->desc_,
            "mandatory",  PyBool_FromLong($self->mandatory_),
            "repeatable", PyBool_FromLong($self->repeatable_),
            "minbytes",   $self->minbytes_,
            "maxbytes",   $self->maxbytes_,
            "type",       $self->type_,
            "recordId",   $self->recordId_,
            "photoshop",  $self->photoshop_));
    }
}

%ignore Exiv2::DataSet::DataSet;
%ignore Exiv2::IptcDataSets::dataSetList;
%ignore Exiv2::IptcDataSets::IptcDataSets;
%ignore Exiv2::RecordInfo;

%immutable;
%include "exiv2/datasets.hpp"
%mutable;
