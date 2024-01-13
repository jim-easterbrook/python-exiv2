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

%module(package="exiv2") metadatum

#pragma SWIG nowarn=314 // 'print' is a python keyword, renaming to '_print'

%include "shared/preamble.i"
%include "shared/containers.i"
%include "shared/keep_reference.i"
%include "shared/unique_ptr.i"

%import "types.i"
%import "value.i"

%define EXTEND_KEY(key_type)
UNIQUE_PTR(key_type);
%feature("python:slot", "tp_str", functype="reprfunc") key_type::key;
%enddef // EXTEND_KEY

// Macro for Metadatum subclasses
%define EXTEND_METADATUM(datum_type)
// Turn off exception checking for methods that are guaranteed not to throw
%noexception datum_type::count;
%noexception datum_type::size;
// Keep a reference to Metadatum when calling value()
KEEP_REFERENCE(const Exiv2::Value&)
// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(datum_type&)
%feature("python:slot", "tp_str", functype="reprfunc") datum_type::__str__;
%extend datum_type {
    std::string __str__() {
        return $self->key() + ": " + $self->print();
    }
    // Extend Metadatum to allow getting value as a specific type.
    Exiv2::Value::SMART_PTR getValue(Exiv2::TypeId as_type) {
        // deprecated since 2023-12-07
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        // deprecated since 2023-12-07
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->value();
    }
    // Set the value from a Python object. The datum's current or default
    // type is used to create an Exiv2::Value object (via Python) from the
    // Python object.
    %fragment("set_value_from_py"{datum_type});
    PyObject* setValue(PyObject* py_value) {
        return set_value_from_py($self, py_value);
    }
}
%enddef // EXTEND_METADATUM

%ignore Exiv2::Key;
%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum;
%ignore Exiv2::Metadatum::operator=;
%ignore Exiv2::Metadatum::write;
%ignore Exiv2::cmpMetadataByKey;
%ignore Exiv2::cmpMetadataByTag;

%include "exiv2/metadatum.hpp"
