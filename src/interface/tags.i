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

%module(package="exiv2") tags

%include "preamble.i"

%import "metadatum.i";

wrap_auto_unique_ptr(Exiv2::ExifKey);

// ExifTags::groupList returns a static list as a pointer
%typemap(out) const Exiv2::GroupInfo* {
    const Exiv2::GroupInfo* gi = $1;
    PyObject* list = PyList_New(0);
    while (gi->tagList_ != 0) {
        PyList_Append(list, SWIG_NewPointerObj(
            SWIG_as_voidptr(gi), $descriptor(Exiv2::GroupInfo*), 0));
        ++gi;
    }
    $result = SWIG_Python_AppendOutput($result, PyList_AsTuple(list));
}

// ExifTags::tagList returns a static list as a pointer
%typemap(out) const Exiv2::TagInfo* {
    const Exiv2::TagInfo* ti = $1;
    PyObject* list = PyList_New(0);
    while (ti->tag_ != 0xFFFF) {
        PyList_Append(list, SWIG_NewPointerObj(
            SWIG_as_voidptr(ti), $descriptor(Exiv2::TagInfo*), 0));
        ++ti;
    }
    $result = SWIG_Python_AppendOutput($result, PyList_AsTuple(list));
}

%ignore Exiv2::GroupInfo::GroupInfo;
%ignore Exiv2::GroupInfo::GroupName;
%ignore Exiv2::TagInfo::TagInfo;

%immutable;
%include "exiv2/tags.hpp"
%mutable;
