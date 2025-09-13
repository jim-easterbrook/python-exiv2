// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


%include "shared/metadatum_wrappers.i"
%include "shared/slots.i"


// Macro to wrap data containers.
%define DATA_CONTAINER(base_class, datum_type, key_type)

METADATUM_WRAPPERS(base_class, datum_type)

// Turn off exception checking for methods that are guaranteed not to throw
%noexception Exiv2::base_class::begin;
%noexception Exiv2::base_class::end;
%noexception Exiv2::base_class::clear;
%noexception Exiv2::base_class::count;
%noexception Exiv2::base_class::empty;
// Add dict-like behaviour
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::base_class::begin;
%feature("python:slot", "mp_length", functype="lenfunc")
    Exiv2::base_class::count;
MP_SUBSCRIPT(Exiv2::base_class, Exiv2::datum_type&, (*self)[key])
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    Exiv2::base_class::__setitem__;
%feature("python:slot", "sq_contains", functype="objobjproc")
    Exiv2::base_class::__contains__;
%extend Exiv2::base_class {
    %fragment("get_type_id"{Exiv2::datum_type});
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        Exiv2::datum_type* datum = &(*$self)[key];
        datum->setValue(value);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        Exiv2::datum_type* datum = &(*$self)[key];
        Exiv2::TypeId old_type = get_type_id(datum);
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), Exiv2::TypeInfo::typeName(old_type),
                value.c_str());
        return SWIG_Py_Void();
    }
#if SWIG_VERSION >= 0x040400
    PyObject* __setitem__(PyObject* py_self, const std::string& key) {
#else
    PyObject* __setitem__(const std::string& key) {
#endif
        Exiv2::base_class::iterator pos = $self->findKey(
            Exiv2::key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
#if SWIG_VERSION >= 0x040400
        invalidate_pointers(py_self, pos);
#endif
        $self->erase(pos);
        return SWIG_Py_Void();
    }
    bool __contains__(const std::string& key) {
        return $self->findKey(Exiv2::key_type(key)) != $self->end();
    }
}

// Set the datum's value from a Python object. The datum's current or default
// type is used to create an Exiv2::Value object (via Python) from the Python
// object.
%fragment("set_value_from_py"{Exiv2::datum_type}, "header",
          fragment="get_type_object",
          fragment="get_type_id"{Exiv2::datum_type}) {
static PyObject* set_value_from_py(Exiv2::datum_type* datum,
                                   PyObject* py_value) {
    swig_type_info* ty_info = get_type_object.at(get_type_id(datum));
    SwigPyClientData *cl_data = (SwigPyClientData*)ty_info->clientdata;
    // Call type object to invoke constructor
    PyObject* swig_obj = PyObject_CallFunctionObjArgs(
        (PyObject*)cl_data->pytype, py_value, NULL);
    if (!swig_obj)
        return NULL;
    // Convert constructed object to Exiv2::Value
    Exiv2::Value* value = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(swig_obj, (void**)&value, ty_info, 0))) {
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
%extend Exiv2::datum_type {
    %fragment("set_value_from_py"{Exiv2::datum_type});
    PyObject* setValue(PyObject* py_value) {
        return set_value_from_py($self, py_value);
    }
}
%extend Exiv2::base_class {
    %fragment("set_value_from_py"{Exiv2::datum_type});
    PyObject* __setitem__(const std::string& key, PyObject* py_value) {
        Exiv2::datum_type* datum = &(*$self)[key];
        return set_value_from_py(datum, py_value);
    }
}
%enddef // DATA_CONTAINER
