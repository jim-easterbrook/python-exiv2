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
// Convert iterator parameters
%typemap(in) parent_class::iterator (int res = 0, iter_class *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp, $descriptor(iter_class*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, iter_class, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(iter_class, $symname, $argnum);
    }
    $1 = argp->ptr;
%};
// Convert iterator return values
%typemap(out) parent_class::iterator %{
    $result = SWIG_NewPointerObj(
        new iter_class($1), $descriptor(iter_class*), SWIG_POINTER_OWN);
%};
// Define a simple class to wrap parent_class::iterator
%ignore iter_class::ptr;
%ignore iter_class::iter_class;
%feature("docstring") iter_class "Python wrapper for parent_class::iterator"
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") iter_class::__next__;
%inline %{
class iter_class {
public:
    parent_class::iterator ptr;
    iter_class(parent_class::iterator ptr) : ptr(ptr) {}
    item_type* operator->() const {
        return &(*this->ptr);
    }
    parent_class::iterator __next__() {
        return this->ptr++;
    }
    bool operator==(const iter_class &other) const {
        return other.ptr == this->ptr;
    }
    bool operator!=(const iter_class &other) const {
        return other.ptr != this->ptr;
    }
};
%}
// Make parent class iterable
%feature("python:slot", "tp_iter", functype="getiterfunc") parent_class::__iter__;
%extend parent_class {
    PyObject* __iter__() {
        PyObject* iterator = SWIG_Python_NewPointerObj(
            NULL, new iter_class($self->begin()),
            $descriptor(iter_class*), SWIG_POINTER_OWN);
        PyObject* callable = PyObject_GetAttrString(iterator, "__next__");
        Py_DECREF(iterator);
        PyObject* sentinel = SWIG_Python_NewPointerObj(
            NULL, new iter_class($self->end()),
            $descriptor(iter_class*), SWIG_POINTER_OWN);
        iterator = PyCallIter_New(callable, sentinel);
        Py_DECREF(callable);
        Py_DECREF(sentinel);
        return iterator;
    }
}
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

// Stuff to handle auto_ptr or unique_ptr
#if EXIV2_VERSION_HEX < 0x01000000
%define wrap_auto_unique_ptr(pointed_type)
%include "std_auto_ptr.i"
%auto_ptr(pointed_type)
%enddef
#else
template <typename T>
struct std::unique_ptr {};
%define wrap_auto_unique_ptr(pointed_type)
%typemap(out) std::unique_ptr<pointed_type> %{
    $result = SWIG_NewPointerObj(
        (&$1)->release(), $descriptor(pointed_type *), SWIG_POINTER_OWN);
%}
%template() std::unique_ptr<pointed_type>;
%enddef
#endif
