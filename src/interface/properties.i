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

%module(package="exiv2") properties

#ifndef SWIGIMPORTED
%constant char* __doc__ = "XMP key class and data attributes.";
#endif

%include "shared/preamble.i"
%include "shared/static_list.i"
%include "shared/struct_dict.i"

%import "metadatum.i"

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

    XmpCategory
'''
%}

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

EXTEND_KEY(Exiv2::XmpKey);

// Make Xmp category more Pythonic
#ifndef SWIGIMPORTED
DEFINE_ENUM(XmpCategory, 3)
#else
IMPORT_ENUM(_properties, XmpCategory)
#endif

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
    $result = SWIG_AppendOutput($result, dict);
}

// Convert XmpProperties.propertyList() result and XmpNsInfo.xmpPropertyInfo_
// to a Python list of XmpPropertyInfo objects
// XmpProperties.propertyInfo() returns a single XmpPropertyInfo object
LIST_POINTER(const Exiv2::XmpPropertyInfo* propertyList,
             Exiv2::XmpPropertyInfo, name_)
LIST_POINTER(const Exiv2::XmpPropertyInfo* xmpPropertyInfo_,
             Exiv2::XmpPropertyInfo, name_)

// Give Exiv2::XmpPropertyInfo dict-like behaviour
STRUCT_DICT(Exiv2::XmpPropertyInfo, false, true)

// Give Exiv2::XmpNsInfo dict-like behaviour
STRUCT_DICT(Exiv2::XmpNsInfo, false, true)

// Structs are all static data
%ignore Exiv2::XmpPropertyInfo::XmpPropertyInfo;
%ignore Exiv2::XmpPropertyInfo::~XmpPropertyInfo;
%ignore Exiv2::XmpProperties::XmpProperties;
%ignore Exiv2::XmpProperties::~XmpProperties;
%ignore Exiv2::XmpNsInfo::XmpNsInfo;
%ignore Exiv2::XmpNsInfo::~XmpNsInfo;

// Ignore "internal" stuff
%ignore Exiv2::XmpProperties::rwLock_;
%ignore Exiv2::XmpProperties::mutex_;
%ignore Exiv2::XmpProperties::nsRegistry_;
%ignore Exiv2::XmpPropertyInfo::operator==;
%ignore Exiv2::XmpNsInfo::operator==;
%ignore Exiv2::XmpNsInfo::Prefix;
%ignore Exiv2::XmpNsInfo::Ns;
%ignore NsRegistry;

// Ignore stuff Python can't use
%ignore Exiv2::XmpProperties::lookupNsRegistry;
%ignore Exiv2::XmpProperties::printProperties;
%ignore Exiv2::XmpProperties::printProperty;

%immutable;
%include "exiv2/properties.hpp"
%mutable;

INIT_STRUCT_DICT(Exiv2::XmpPropertyInfo)
INIT_STRUCT_DICT(Exiv2::XmpNsInfo)
