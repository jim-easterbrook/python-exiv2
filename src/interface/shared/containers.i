// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


%include "shared/fragments.i"
%include "shared/keep_reference.i"


// Macro to wrap data containers.
%define DATA_CONTAINER(base_class, datum_type, key_type)
// Turn off exception checking for methods that are guaranteed not to throw
%noexception base_class::begin;
%noexception base_class::end;
%noexception base_class::clear;
%noexception base_class::count;
%noexception base_class::empty;
// Add dict-like behaviour
%feature("python:slot", "tp_iter", functype="getiterfunc")
    base_class::begin;
%feature("python:slot", "mp_length", functype="lenfunc")
    base_class::count;
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    base_class::__getitem__;
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    base_class::__setitem__;
%feature("python:slot", "sq_contains", functype="objobjproc")
    base_class::__contains__;
%fragment("set_value_from_py"{datum_type}, "header",
          fragment="get_type_object", fragment="get_type_id"{datum_type}) {
static PyObject* set_value_from_py(datum_type* datum, PyObject* py_value) {
    // Set the value from a Python object. The datum's current or default
    // type is used to create an Exiv2::Value object (via Python) from
    // the Python object.
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
%extend base_class {
    %fragment("get_type_id"{datum_type});
    %fragment("set_value_from_py"{datum_type});
    datum_type& __getitem__(const std::string& key) {
        return (*$self)[key];
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        datum_type* datum = &(*$self)[key];
        datum->setValue(value);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        datum_type* datum = &(*$self)[key];
        Exiv2::TypeId old_type = get_type_id(datum);
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), Exiv2::TypeInfo::typeName(old_type),
                value.c_str());
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, PyObject* py_value) {
        datum_type* datum = &(*$self)[key];
        return set_value_from_py(datum, py_value);
    }
    PyObject* __setitem__(const std::string& key) {
        base_class::iterator pos = $self->findKey(key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->erase(pos);
        return SWIG_Py_Void();
    }
    bool __contains__(const std::string& key) {
        return $self->findKey(key_type(key)) != $self->end();
    }
}
%enddef // DATA_CONTAINER


// Macro for Metadatum subclasses
%define EXTEND_METADATUM(datum_type)
// Turn off exception checking for methods that are guaranteed not to throw
%noexception datum_type::count;
%noexception datum_type::size;
// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(datum_type&)
// Extend Metadatum to allow getting value as a specific type.
%extend datum_type {
    Exiv2::Value::SMART_PTR getValue(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->value();
    }
}

%extend datum_type {
    // Set the value from a Python object. The datum's current or default
    // type is used to create an Exiv2::Value object (via Python) from the
    // Python object.
    %fragment("set_value_from_py"{datum_type});
    PyObject* setValue(PyObject* py_value) {
        return set_value_from_py($self, py_value);
    }
}
%enddef // EXTEND_METADATUM
