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

%module(package="exiv2") tags

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exif key class and data attributes.";
#endif

%include "shared/preamble.i"
%include "shared/static_list.i"
%include "shared/struct_dict.i"

%import "metadatum.i";

// Add inheritance diagram and enum table to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Key
    :top-classes: exiv2.metadatum.Key
    :parts: 1
    :include-subclasses:

.. rubric:: Enums

.. autosummary::

    IfdId
    SectionId
'''
%}

IMPORT_ENUM(types, TypeId)

// Catch some C++ exceptions
%exception;
EXCEPTION(Exiv2::ExifKey::ExifKey)
EXCEPTION(Exiv2::ExifKey::clone)

EXTEND_KEY(Exiv2::ExifKey);

// Add Exif specific enums
#if EXIV2_VERSION_HEX >= 0x001c0000
DEFINE_ENUM(IfdId,)
DEFINE_ENUM(SectionId,)
#endif // EXIV2_VERSION_HEX

// Convert ExifTags::groupList() result to a Python list of GroupInfo objects
LIST_POINTER(const Exiv2::GroupInfo*, Exiv2::GroupInfo, tagList_)
// Convert ExifTags::tagList() result to a Python list of TagInfo objects
LIST_POINTER(const Exiv2::TagInfo*, Exiv2::TagInfo, tag_ != 0xFFFF)

// Give Exiv2::GroupInfo dict-like behaviour
STRUCT_DICT(Exiv2::GroupInfo, false, true)

// Give Exiv2::TagInfo dict-like behaviour
STRUCT_DICT(Exiv2::TagInfo, false, true)

// Wrapper class for TagListFct function pointer
#ifndef SWIGIMPORTED
%ignore _TagListFct::_TagListFct;
%feature("python:slot", "tp_call", functype="ternarycallfunc")
    _TagListFct::__call__;
%noexception _TagListFct::~_TagListFct;
%noexception _TagListFct::__call__;
%inline %{
class _TagListFct {
private:
    Exiv2::TagListFct func;
public:
    _TagListFct(Exiv2::TagListFct func) : func(func) {}
    const Exiv2::TagInfo* __call__() {
        return (*func)();
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

// Structs are all static data
%ignore Exiv2::GroupInfo::GroupInfo;
%ignore Exiv2::GroupInfo::~GroupInfo;
%ignore Exiv2::TagInfo::TagInfo;
%ignore Exiv2::TagInfo::~TagInfo;
%ignore Exiv2::ExifTags::~ExifTags;

// Ignore stuff that Python can't use or doesn't need
%ignore Exiv2::GroupInfo::operator==;
%ignore Exiv2::GroupInfo::GroupName;
%ignore Exiv2::ExifTags::taglist;
%ignore Exiv2::TagInfo::printFct_;

// Ignore unneeded key constructor
%ignore Exiv2::ExifKey::ExifKey(const TagInfo&);

// ExifKey::ifdId is documented as internal use only
%ignore Exiv2::ExifKey::ifdId;

%immutable;
%include "exiv2/tags.hpp"
%mutable;
