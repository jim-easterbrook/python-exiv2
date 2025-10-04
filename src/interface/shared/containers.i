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
%define DATA_CONTAINER(base_class, datum_type, key_type, default_type_func)

METADATUM_WRAPPERS(base_class, datum_type)

/* Set a datum's value from a Python object. String or Exiv2::Value objects
 * are used directly. Other objects are used in the constructor of a Python
 * Exiv2::Value using the datum's current or default type.
 */
%ignore Exiv2::datum_type::setValue(const Value*);
%ignore Exiv2::datum_type::setValue(const std::string&);
%fragment("set_value_from_py"{Exiv2::datum_type}, "header",
          fragment="get_type_object") {
static PyObject* set_value_from_py(Exiv2::datum_type* datum,
                                   PyObject* py_value) {
    // Get the current (or default if not set) type id of the datum
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id == Exiv2::invalidTypeId)
        type_id = default_type_func;
    // Try std::string value
    if (PyUnicode_Check(py_value)) {
        std::string value = PyUnicode_AsUTF8(py_value);
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), Exiv2::TypeInfo::typeName(type_id),
                value.c_str());
        return SWIG_Py_Void();
    }
    // Try Exiv2::Value value
    Exiv2::Value* value = NULL;
    if (SWIG_IsOK(SWIG_ConvertPtr(
            py_value, (void**)&value, $descriptor(Exiv2::Value*), 0))) {
        datum->setValue(value);
        return SWIG_Py_Void();
    }
    // Try converting Python object to a value
    swig_type_info* ty_info = get_type_object(type_id);
    SwigPyClientData *cl_data = (SwigPyClientData*)ty_info->clientdata;
    // Call type object to invoke constructor
    PyObject* swig_obj = PyObject_CallFunctionObjArgs(
        (PyObject*)cl_data->pytype, py_value, NULL);
    if (!swig_obj)
        return NULL;
    // Convert constructed object to Exiv2::Value
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
%fragment("set_value_from_py"{Exiv2::datum_type});
#if SWIG_VERSION >= 0x040400
%fragment("pointer_store");
#endif
MP_ASS_SUBSCRIPT(Exiv2::base_class, PyObject*,
// setfunc
    return set_value_from_py(&(*self)[key], value),
// delfunc
    auto pos = self->findKey(Exiv2::key_type(key));
    if (pos == self->end())
        return PyErr_Format(PyExc_KeyError, "'%s'", key);
#if SWIG_VERSION >= 0x040400
    invalidate_pointers(py_self, pos);
#endif
    self->erase(pos), false)
SQ_CONTAINS(
    Exiv2::base_class, self->findKey(Exiv2::key_type(key)) != self->end())

%extend Exiv2::datum_type {
    %fragment("set_value_from_py"{Exiv2::datum_type});
    PyObject* setValue(PyObject* py_value) {
        return set_value_from_py($self, py_value);
    }
}
%enddef // DATA_CONTAINER
