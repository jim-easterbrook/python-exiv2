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

%module(package="exiv2") properties

%include "preamble.i"

%import "datasets.i"
%import "metadatum.i"

wrap_auto_unique_ptr(Exiv2::XmpKey);

// Make Xmp category more Pythonic
ENUM(XmpCategory, "Category of an XMP property.",
        Internal = Exiv2::xmpInternal,
        External = Exiv2::xmpExternal);

// Get registeredNamespaces to return a Python dict
%typemap(in, numinputs=0) Exiv2::Dictionary &nsDict (Exiv2::Dictionary temp) %{
    $1 = &temp;
%}
%typemap(argout) Exiv2::Dictionary &nsDict {
    PyObject* dict = PyDict_New();
    Exiv2::Dictionary::iterator e = $1->end();
    for (Exiv2::Dictionary::iterator i = $1->begin(); i != e; ++i) {
        PyDict_SetItem(dict,
            PyUnicode_FromString(i->first.c_str()),
            PyUnicode_FromString(i->second.c_str()));
    }
    $result = SWIG_Python_AppendOutput($result, dict);
}

// Ignore "internal" stuff
%ignore Exiv2::XmpProperties::rwLock_;
%ignore Exiv2::XmpProperties::mutex_;
%ignore Exiv2::XmpProperties::nsRegistry_;

%ignore Exiv2::XmpPropertyInfo::XmpPropertyInfo;
%ignore Exiv2::XmpNsInfo::XmpNsInfo;
%ignore Exiv2::XmpNsInfo::Prefix;
%ignore Exiv2::XmpNsInfo::Ns;

%immutable;
%include "exiv2/properties.hpp"
%mutable;
