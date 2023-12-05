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

%module(package="exiv2") tags

%include "preamble.i"
%include "shared/static_list.i"
%include "shared/unique_ptr.i"

%import "metadatum.i";

UNIQUE_PTR(Exiv2::ExifKey);

// ExifTags::groupList returns a static list as a pointer
LIST_POINTER(const Exiv2::GroupInfo*, Exiv2::GroupInfo, tagList_ != 0)

// ExifTags::tagList returns a static list as a pointer
LIST_POINTER(const Exiv2::TagInfo*, Exiv2::TagInfo, tag_ != 0xFFFF)

// Make Exiv2::TagInfo struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::TagInfo::__iter__;
%noexception Exiv2::TagInfo::__iter__;
%extend Exiv2::TagInfo {
    PyObject* __iter__() {
        return PySeqIter_New(Py_BuildValue(
            "((si)(ss)(ss)(ss)(si)(si)(si)(si))",
            "tag",       $self->tag_,
            "name",      $self->name_,
            "title",     $self->title_,
            "desc",      $self->desc_,
            "ifdId",     $self->ifdId_,
            "sectionId", $self->sectionId_,
            "typeId",    $self->typeId_,
            "count",     $self->count_));
    }
}

// Wrapper class for TagListFct function pointer
#ifndef SWIGIMPORTED
%ignore _TagListFct::_TagListFct;
%feature("python:slot", "tp_call", functype="ternarycallfunc")
    _TagListFct::__call__;
%noexception _TagListFct::~_TagListFct;
%noexception _TagListFct::__call__;
%noexception _TagListFct::operator==;
%noexception _TagListFct::operator!=;
%inline %{
class _TagListFct {
private:
    Exiv2::TagListFct func;
public:
    _TagListFct(Exiv2::TagListFct func) : func(func) {}
    const Exiv2::TagInfo* __call__() {
        return (*func)();
    }
    bool operator==(const _TagListFct &other) const {
        return other.func == func;
    }
    bool operator!=(const _TagListFct &other) const {
        return other.func != func;
    }
};
%}
%fragment("new_TagListFct", "header") {
    static PyObject* new_TagListFct(Exiv2::TagListFct func) {
        return SWIG_Python_NewPointerObj(NULL, new _TagListFct(func),
            $descriptor(_TagListFct*), SWIG_POINTER_OWN);
    }
}
#endif // SWIGIMPORTED

// Wrap TagListFct return values
%typemap(out, fragment="new_TagListFct") Exiv2::TagListFct {
    $result = new_TagListFct($1);
}

// Make Exiv2::GroupInfo struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::GroupInfo::__iter__;
%noexception Exiv2::GroupInfo::__iter__;
%extend Exiv2::GroupInfo {
    %fragment("new_TagListFct");
    PyObject* __iter__() {
        printf("taglist pointer %p\n", $self->tagList_);
        return PySeqIter_New(Py_BuildValue(
            "((si)(ss)(ss)(sN))",
            "ifdId",     $self->ifdId_,
            "ifdName",   $self->ifdName_,
            "groupName", $self->groupName_,
            "tagList",   new_TagListFct($self->tagList_)));
    }
}

%ignore Exiv2::GroupInfo::GroupInfo;
%ignore Exiv2::GroupInfo::GroupName;
%ignore Exiv2::TagInfo::TagInfo;

// Ignore stuff that Python can't use
%ignore Exiv2::TagInfo::printFct_;
%ignore Exiv2::ExifTags::taglist;

// ExifKey::ifdId is documented as internal use only
%ignore Exiv2::ExifKey::ifdId;

%immutable;
%include "exiv2/tags.hpp"
%mutable;
