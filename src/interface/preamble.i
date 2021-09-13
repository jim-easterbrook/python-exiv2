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

%{
#include "exiv2/exiv2.hpp"
%}

// EXIV2API prepends every function declaration
#define EXIV2API
// Older versions of libexiv2 define these as well
#define EXV_DLLLOCAL
#define EXV_DLLPUBLIC

#ifndef SWIG_DOXYGEN
%feature("autodoc", "2");
#endif

// Get exception and logger defined in __init__.py
%{
PyObject* PyExc_AnyError = NULL;
PyObject* logger = NULL;
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("exiv2");
    if (module != NULL) {
        PyExc_AnyError = PyObject_GetAttrString(module, "AnyError");
        logger = PyObject_GetAttrString(module, "_logger");
        Py_DECREF(module);
    }
    if (PyExc_AnyError == NULL || logger == NULL)
        return NULL;
}
%}

// Catch all C++ exceptions
%exception {
    try {
        $action
    } catch(Exiv2::AnyError &e) {
        PyErr_SetString(PyExc_AnyError, e.what());
        SWIG_fail;
    } catch(std::exception &e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
        SWIG_fail;
    }
}

// Macro to provide operator[] equivalent
%define GETITEM(class, ret_type)
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") class::__getitem__;
%extend class {
    ret_type& __getitem__(const std::string& key) {
        return (*($self))[key];
    }
}
%enddef

// Macro to provide __str__
%define STR(class, method)
%feature("python:slot", "tp_str", functype="reprfunc") class::__str__;
%extend class {
    std::string __str__() {
        return $self->method();
    }
}
%enddef

// Macro to provide a Python iterator over a C++ class with begin/end methods
%define ITERATOR(parent_class, item_type, iter_class)
// Define a simple class to wrap parent_class::iterator
%ignore iter_class ## Ptr::ptr;
%ignore iter_class ## Ptr::iter_class ## Ptr;
%feature("docstring") iter_class ## Ptr
    "Python wrapper for parent_class::iterator"
%feature("docstring") iter_class ## Ptr::curr "returns the current 'this' object"
%inline %{
class iter_class ## Ptr {
public:
    parent_class::iterator ptr;
    iter_class ## Ptr(parent_class::iterator ptr) : ptr(ptr) {}
    const item_type* curr() {
        return &(*this->ptr);
    }
    const item_type* next() {
        return &(*(this->ptr++));
    }
    bool operator==(const iter_class ## Ptr &other) const {
        return other.ptr == this->ptr;
    }
    bool operator!=(const iter_class ## Ptr &other) const {
        return other.ptr != this->ptr;
    }
};
%}
// Convert iterator parameters
%typemap(in) parent_class::iterator (int res = 0, void *argp) {
    res = SWIG_ConvertPtr($input, &argp, SWIGTYPE_p_ ## iter_class ## Ptr, 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, iter_class ## Ptr, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(iter_class ## Ptr, $symname, $argnum);
    }
    $1 = (reinterpret_cast<iter_class ## Ptr*>(argp))->ptr;
};
// Convert iterator return values
%typemap(out) parent_class::iterator {
    $result = SWIG_NewPointerObj(
        new iter_class ## Ptr(result),
        SWIGTYPE_p_ ## iter_class ## Ptr, SWIG_POINTER_OWN);
};

// Make parent class iterable
%feature("python:slot", "tp_iter", functype="getiterfunc") parent_class::__iter__;
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") iter_class::__next__;
%ignore iter_class ## Stop;
%ignore iter_class::ptr;
%feature("docstring") iter_class "Python iterator over parent_class"
%extend parent_class {
    iter_class __iter__() {
        return iter_class($self);
    }
}
%typemap(throws) iter_class ## Stop {
    PyErr_SetNone(PyExc_StopIteration);
    SWIG_fail;
}
%inline %{
class iter_class ## Stop {};
class iter_class {
private:
    iter_class ## Ptr* ptr;
    iter_class ## Ptr* end;
public:
    iter_class(parent_class* parent) {
        this->ptr = new iter_class ## Ptr(parent->begin());
        this->end = new iter_class ## Ptr(parent->end());
    }
    const item_type* __next__() throw (iter_class ## Stop) {
        if (*this->ptr == *this->end)
            throw iter_class ## Stop();
        return this->ptr->next();
    }
};
%}
%enddef

// Macro for use in SETITEM
%define NEW_TYPE_WARN()
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << key << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
%enddef

// Macro to provide operator= equivalent
%define SETITEM(class, datum_type, key_type, default_type)
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") class::__setitem__;

%extend class {
    PyObject* __setitem__(const std::string& key, const Exiv2::Value &value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type;
        datum->setValue(&value);
        NEW_TYPE_WARN()
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string &value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type;
        if (datum->setValue(value) != 0) {
            EXV_ERROR << key << ": cannot set type '" <<
                TypeInfo::typeName(old_type) << "' from '" << value << "'.\n";
        }
        NEW_TYPE_WARN()
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type;
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        char* c_str = SWIG_Python_str_AsChar(py_str);
        Py_DECREF(py_str);
        if (datum->setValue(c_str) != 0) {
            EXV_ERROR << key << ": cannot set type '" <<
                TypeInfo::typeName(old_type) << "' from '" << c_str << "'.\n";
        }
        NEW_TYPE_WARN()
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key) {
        using namespace Exiv2;
        class::iterator pos = $self->findKey(key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->erase(pos);
        return SWIG_Py_Void();
    }
}
%enddef

// Macro to make enums more Pythonic
%define ENUM(name, contents...)
%inline %{
struct name {
    enum {contents};
};
%}
%immutable name;
%ignore name::name;
%ignore name::~name;
%ignore Exiv2::name;
%enddef
