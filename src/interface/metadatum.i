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

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 metadatum base class.";
#endif

%namewarn("") "print"; // don't rename print methods

%include "shared/preamble.i"
%include "shared/containers.i"
%include "shared/exception.i"
%include "shared/keep_reference.i"
%include "shared/unique_ptr.i"

%import "value.i"

// Catch all C++ exceptions
EXCEPTION()

// Use default parameter for toFloat etc.
%typemap(default) long n, size_t n {$1 = 0;}
%ignore Exiv2::Metadatum::toFloat() const;
%ignore Exiv2::Metadatum::toInt64() const;
%ignore Exiv2::Metadatum::toLong() const;
%ignore Exiv2::Metadatum::toRational() const;
%ignore Exiv2::Metadatum::toUint32() const;

// Use default parameter in print() and write()
%typemap(default) const Exiv2::ExifData* pMetadata {$1 = NULL;}
%ignore Exiv2::Metadatum::print() const;
%ignore Exiv2::Metadatum::write(std::ostream &) const;

%define EXTEND_KEY(key_type)
UNIQUE_PTR(key_type);
%feature("python:slot", "tp_str", functype="reprfunc") key_type::key;
%enddef // EXTEND_KEY

EXTEND_KEY(Exiv2::Key);

// Macro for Metadatum subclasses
%define EXTEND_METADATUM(datum_type)
// Ignore overloaded default parameter version
%ignore datum_type::write(std::ostream &) const;
// Turn off exception checking for methods that are guaranteed not to throw
%noexception datum_type::count;
%noexception datum_type::size;
// Keep a reference to Metadatum when calling value()
KEEP_REFERENCE(const Exiv2::Value&)
// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(datum_type&)
// Set the datum's value from a Python object. The datum's current or default
// type is used to create an Exiv2::Value object (via Python) from the Python
// object.
%fragment("set_value_from_py"{datum_type}, "header",
          fragment="get_type_object", fragment="get_type_id"{datum_type}) {
static PyObject* set_value_from_py(datum_type* datum, PyObject* py_value) {
    swig_type_info* ty_info = get_type_object(get_type_id(datum));
    SwigPyClientData *cl_data = (SwigPyClientData*)ty_info->clientdata;
    // Call type object to invoke constructor
    PyObject* args = PyTuple_Pack(1, py_value);
    PyObject* swig_obj = PyObject_CallObject(
        (PyObject*)cl_data->pytype, args);
    Py_DECREF(args);
    if (!swig_obj)
        return NULL;
    // Convert constructed object to Exiv2::Value
    Exiv2::Value* value = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            swig_obj, (void**)&value, $descriptor(Exiv2::Value*), 0))) {
        PyErr_SetString(
            PyExc_RuntimeError, "set_value_from_py: invalid conversion");
        Py_DECREF(swig_obj);
        return NULL;
    }
    // Set value
    datum->setValue(value);
    Py_DECREF(swig_obj);
    return SWIG_Py_Void();
};
}
%extend datum_type {
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
    // Old _print method for compatibility
    std::string _print(const Exiv2::ExifData* pMetadata) const {
        // deprecated since 2024-01-29
        PyErr_WarnEx(PyExc_DeprecationWarning,
                     "'_print' has been replaced by 'print'", 1);
        return $self->print(pMetadata);
    }
}
%enddef // EXTEND_METADATUM

// Extend base type
%feature("python:slot", "tp_str", functype="reprfunc")
    Exiv2::Metadatum::__str__;
%extend Exiv2::Metadatum {
    std::string __str__() {
        return $self->key() + ": " + $self->print();
    }
}

%ignore Exiv2::Key::~Key;
%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum::~Metadatum;
%ignore Exiv2::Metadatum::operator=;
%ignore Exiv2::cmpMetadataByKey;
%ignore Exiv2::cmpMetadataByTag;

%include "exiv2/metadatum.hpp"
