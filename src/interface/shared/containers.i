// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
