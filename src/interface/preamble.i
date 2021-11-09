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

// Macro to provide __str__
%define STR(class, method)
%feature("python:slot", "tp_str", functype="reprfunc") class::__str__;
%extend class {
    std::string __str__() {
        return $self->method();
    }
}
%enddef

// Macro to wrap C++ iterator with a Python friendly class
%define DATA_ITERATOR(parent_class, item_type)
// Convert iterator parameters
%typemap(in) Exiv2::parent_class::iterator (int res = 0,
                                            parent_class##Iterator *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp,
                          $descriptor(parent_class##Iterator*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, parent_class##Iterator, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(parent_class##Iterator, $symname, $argnum);
    }
    $1 = **argp;
%};
// Convert iterator return values
%typemap(out) Exiv2::parent_class::iterator %{
    $result = SWIG_NewPointerObj(
        new parent_class##Iterator($1),
        $descriptor(parent_class##Iterator*), SWIG_POINTER_OWN);
%};
// Define a simple class to wrap parent_class::iterator
%ignore parent_class##Iterator::operator*;
%ignore parent_class##Iterator::parent_class##Iterator;
%feature("docstring") parent_class##Iterator
         "Python wrapper for Exiv2::parent_class::iterator"
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") parent_class##Iterator::__next__;
%inline %{
class parent_class##Iterator {
private:
    Exiv2::parent_class::iterator ptr;
public:
    parent_class##Iterator(Exiv2::parent_class::iterator ptr) : ptr(ptr) {}
    Exiv2::item_type* operator->() const {
        return &(*ptr);
    }
    Exiv2::parent_class::iterator operator*() const {
        return ptr;
    }
    Exiv2::item_type* __next__() {
        return &(*ptr++);
    }
    bool operator==(const parent_class##Iterator &other) const {
        return *other == ptr;
    }
    bool operator!=(const parent_class##Iterator &other) const {
        return *other != ptr;
    }
};
%}
%enddef

// Macro to provide Python list and dict methods for Exiv2 data
%define DATA_LISTMAP(base_class, datum_type, key_type, default_type_func)
// typemap for input parameters
%typemap(in) Exiv2::base_class& (int res = 0, base_class##Wrap *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp,
                          $descriptor(base_class##Wrap*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, base_class##Wrap, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(base_class##Wrap, $symname, $argnum);
    }
    $1 = **argp;
%};
// Python slots
%feature("python:slot", "tp_iter",
         functype="getiterfunc") base_class##Wrap::__iter__;
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") base_class##Wrap::__next__;
%feature("python:slot", "mp_length",
         functype="lenfunc") base_class##Wrap::__len__;
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") base_class##Wrap::__getitem__;
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") base_class##Wrap::__setitem__;
%feature("python:slot", "sq_contains",
         functype="objobjproc") base_class##Wrap::__contains__;
// wrapper class
%rename(base_class) base_class##Wrap;
%ignore Exiv2::base_class;
%ignore base_class##Wrap::base_class##Wrap(Exiv2::base_class&);
%ignore base_class##Wrap::operator*;
%ignore base_class##Wrap::_old_type;
%ignore base_class##Wrap::_warn_type_change;
%feature("docstring") base_class##Wrap
         "Python wrapper for Exiv2::parent_class"
%typemap(ret) Exiv2::datum_type* __next__ %{
    if (!$1) SWIG_fail;
%}
%inline %{
class base_class##Wrap {
private:
    Exiv2::base_class* base;
    Exiv2::base_class::iterator iter_pos;
public:
    base_class##Wrap(Exiv2::base_class& base) {
        this->base = &base;
    }
    base_class##Wrap() {
        this->base = new Exiv2::base_class();
    }
    Exiv2::base_class* operator->() {
        return base;
    }
    Exiv2::base_class* operator*() {
        return base;
    }
    base_class##Wrap* __iter__() {
        iter_pos = base->begin();
        return this;
    }
    Exiv2::datum_type* __next__() {
        if (iter_pos == base->end()) {
            PyErr_SetNone(PyExc_StopIteration);
            return NULL;
        }
        return &(*(iter_pos++));
    }
    long __len__() {
        return base->count();
    }
    Exiv2::datum_type* __getitem__(const std::string& key) {
        return &(*base)[key];
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        Exiv2::datum_type* datum = &(*base)[key];
        Exiv2::TypeId old_type = _old_type(key, datum);
        datum->setValue(value);
        _warn_type_change(old_type, datum);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        Exiv2::datum_type* datum = &(*base)[key];
        Exiv2::TypeId old_type = _old_type(key, datum);
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                key.c_str(), Exiv2::TypeInfo::typeName(old_type), value.c_str());
        _warn_type_change(old_type, datum);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        char* c_str = PyUnicode_AsUTF8(py_str);
        Py_DECREF(py_str);
        return __setitem__(key, c_str);
    }
    Exiv2::TypeId _old_type(const std::string& key, Exiv2::datum_type* datum) {
        using namespace Exiv2;
        TypeId old_type = datum->typeId();
        if (old_type == Exiv2::invalidTypeId)
            old_type = default_type_func;
        return old_type;
    }
    void _warn_type_change(Exiv2::TypeId old_type, Exiv2::datum_type* datum) {
        using namespace Exiv2;
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << datum->key() << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
    }
#if defined(SWIGPYTHON_BUILTIN)
    PyObject* __setitem__(const std::string& key) {
#else
    PyObject* __delitem__(const std::string& key) {
#endif
        Exiv2::base_class::iterator pos = base->findKey(Exiv2::key_type(key));
        if (pos == base->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        base->erase(pos);
        return SWIG_Py_Void();
    }
    int __contains__(const std::string& key) {
        Exiv2::base_class::iterator pos = base->findKey(Exiv2::key_type(key));
        return (pos == base->end()) ? 0 : 1;
    }
};
%}
%enddef

// Macro to make enums more Pythonic
%define ENUM(name, doc, contents...)
%feature("docstring") name doc
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
