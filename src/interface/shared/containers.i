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


%include "shared/keep_reference.i"


// Macro to wrap data containers.
%define DATA_CONTAINER(base_class, datum_type, key_type, default_type_func)
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
%fragment("get_type_id"{datum_type}, "header") {
static Exiv2::TypeId get_type_id(datum_type* datum) {
    Exiv2::TypeId old_type = datum->typeId();
    if (old_type == Exiv2::invalidTypeId)
        return default_type_func;
    return old_type;
};
}
%fragment("warn_type_change"{datum_type}, "header") {
static void warn_type_change(Exiv2::TypeId old_type, datum_type* datum) {
    using namespace Exiv2;
    TypeId new_type = datum->typeId();
    if (new_type != old_type) {
        EXV_WARNING << datum->key() << ": changed type from '" <<
            TypeInfo::typeName(old_type) << "' to '" <<
            TypeInfo::typeName(new_type) << "'.\n";
    }
};
}
%extend base_class {
    %fragment("get_type_id"{datum_type});
    %fragment("warn_type_change"{datum_type});
    datum_type& __getitem__(const std::string& key) {
        return (*$self)[key];
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        datum_type* datum = &(*$self)[key];
        Exiv2::TypeId old_type = get_type_id(datum);
        datum->setValue(value);
        warn_type_change(old_type, datum);
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
        warn_type_change(old_type, datum);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use " #base_class "[key] = str(value) to set value", 1);
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        const char* c_str = PyUnicode_AsUTF8(py_str);
        Py_DECREF(py_str);
        datum_type* datum = &(*$self)[key];
        Exiv2::TypeId old_type = get_type_id(datum);
        if (datum->setValue(c_str) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), Exiv2::TypeInfo::typeName(old_type),
                c_str);
        warn_type_change(old_type, datum);
        return SWIG_Py_Void();
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
#if EXIV2_VERSION_HEX < 0x001c0000
%extend datum_type {
    Exiv2::Value::AutoPtr getValue(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Value should already have the correct type.", 1);
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Value should already have the correct type.", 1);
        return $self->value();
    }
}
#else   // EXIV2_VERSION_HEX
%extend datum_type {
    Exiv2::Value::UniquePtr getValue(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Value should already have the correct type.", 1);
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Value should already have the correct type.", 1);
        return $self->value();
    }
}
#endif  // EXIV2_VERSION_HEX
%enddef // EXTEND_METADATUM
