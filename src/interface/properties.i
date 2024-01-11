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

%module(package="exiv2") properties

%include "shared/preamble.i"
%include "shared/exception.i"
%include "shared/enum.i"
%include "shared/static_list.i"
%include "shared/unique_ptr.i"

%import "datasets.i"
%import "metadatum.i"

// Catch all C++ exceptions...
EXCEPTION()

// ...except these
%noexception Exiv2::XmpKey::~XmpKey;
%noexception Exiv2::XmpKey::familyName;
%noexception Exiv2::XmpKey::groupName;
%noexception Exiv2::XmpKey::key;
%noexception Exiv2::XmpKey::tag;
%noexception Exiv2::XmpKey::tagLabel;
%noexception Exiv2::XmpKey::tagName;
%noexception Exiv2::XmpProperties::prefix;
%noexception Exiv2::XmpProperties::propertyDesc;
%noexception Exiv2::XmpProperties::propertyInfo;
%noexception Exiv2::XmpProperties::propertyTitle;
%noexception Exiv2::XmpProperties::propertyType;

UNIQUE_PTR(Exiv2::XmpKey);

// Make Xmp category more Pythonic
ENUM(XmpCategory, "Category of an XMP property.",
        "xmpInternal", Exiv2::xmpInternal,
        "xmpExternal", Exiv2::xmpExternal,
        "Internal", Exiv2::xmpInternal,
        "External", Exiv2::xmpExternal);

// Get registeredNamespaces to return a Python dict
%typemap(in, numinputs=0) Exiv2::Dictionary &nsDict (Exiv2::Dictionary temp) %{
    $1 = &temp;
%}
%typemap(argout) Exiv2::Dictionary &nsDict {
    PyObject* value = NULL;
    PyObject* dict = PyDict_New();
    Exiv2::Dictionary::iterator e = $1->end();
    for (Exiv2::Dictionary::iterator i = $1->begin(); i != e; ++i) {
        value = PyUnicode_FromString(i->second.c_str());
        PyDict_SetItemString(dict, i->first.c_str(), value);
        Py_DECREF(value);
    }
    $result = SWIG_Python_AppendOutput($result, dict);
}

%fragment("struct_to_dict"{Exiv2::XmpPropertyInfo}, "header",
          fragment="py_from_enum"{Exiv2::XmpCategory},
          fragment="py_from_enum"{Exiv2::TypeId}) {
static PyObject* struct_to_dict(const Exiv2::XmpPropertyInfo* info) {
    if (!info)
        return SWIG_Py_Void();
    return Py_BuildValue("{ss,ss,ss,sN,sN,ss}",
        "name",         info->name_,
        "title",        info->title_,
        "xmpValueType", info->xmpValueType_,
        "typeId",       py_from_enum(info->typeId_),
        "xmpCategory",  py_from_enum(info->xmpCategory_),
        "desc",         info->desc_);
};
}
// Convert XmpProperties.propertyInfo() result to a single Python dict
%typemap(doctype) Exiv2::XmpPropertyInfo* "dict"
%typemap(out, fragment="struct_to_dict"{Exiv2::XmpPropertyInfo})
        const Exiv2::XmpPropertyInfo* {
    $result = struct_to_dict($1);
}

// Convert XmpProperties.propertyList() result and XmpNsInfo.xmpPropertyInfo_
// to a Python list of dicts
LIST_POINTER(const Exiv2::XmpPropertyInfo* propertyList,
             Exiv2::XmpPropertyInfo, name_ != 0)
LIST_POINTER(const Exiv2::XmpPropertyInfo* xmpPropertyInfo_,
             Exiv2::XmpPropertyInfo, name_ != 0)

%fragment("struct_to_dict"{Exiv2::XmpNsInfo}, "header",
    fragment="pointer_to_list"{Exiv2::XmpPropertyInfo}) {
static PyObject* struct_to_dict(const Exiv2::XmpNsInfo* info) {
    return Py_BuildValue("{ss,ss,sN,ss}",
        "ns",              info->ns_,
        "prefix",          info->prefix_,
        "xmpPropertyInfo", pointer_to_list(info->xmpPropertyInfo_),
        "desc",            info->desc_);
};
}

// Convert XmpProperties.nsInfo() result to a single Python dict
%typemap(doctype) Exiv2::XmpNsInfo* "dict"
%typemap(out, fragment="struct_to_dict"{Exiv2::XmpNsInfo})
        const Exiv2::XmpNsInfo* {
    $result = struct_to_dict($1);
}

// Ignore "internal" stuff
%ignore Exiv2::XmpProperties::rwLock_;
%ignore Exiv2::XmpProperties::mutex_;
%ignore Exiv2::XmpProperties::nsRegistry_;

%ignore Exiv2::XmpPropertyInfo;
%ignore Exiv2::XmpNsInfo;
%ignore Exiv2::XmpNsInfo::Prefix;
%ignore Exiv2::XmpNsInfo::Ns;

// Ignore stuff Python can't use
%ignore Exiv2::XmpProperties::~XmpProperties;
%ignore Exiv2::XmpProperties::lookupNsRegistry;
%ignore Exiv2::XmpProperties::printProperties;
%ignore Exiv2::XmpProperties::printProperty;

%immutable;
%include "exiv2/properties.hpp"
%mutable;
