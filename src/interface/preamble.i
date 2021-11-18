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

// Macro to make an Exiv2 data container more like a Python dict
%define DATA_MAPPING_METHODS(name, base_class, datum_type, key_type,
                             default_type_func)
%feature("python:slot", "mp_length",
         functype="lenfunc") base_class::__len__;
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") base_class::__getitem__;
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") base_class::__setitem__;
%feature("python:slot", "sq_contains",
         functype="objobjproc") base_class::__contains__;
// Helper functions
%{
static Exiv2::TypeId name##_default_type(datum_type* datum) {
    Exiv2::TypeId old_type = datum->typeId();
    if (old_type == Exiv2::invalidTypeId)
        old_type = default_type_func;
    return old_type;
};
static void name##_type_change_warn(datum_type* datum, Exiv2::TypeId old_type) {
    using namespace Exiv2;
    TypeId new_type = datum->typeId();
    if (new_type == old_type)
        return;
    EXV_WARNING << datum->key() << ": changed type from '" <<
        TypeInfo::typeName(old_type) << "' to '" <<
        TypeInfo::typeName(new_type) << "'.\n";
};
static PyObject* name##_set_value(datum_type* datum, const std::string& value) {
    Exiv2::TypeId old_type = name##_default_type(datum);
    if (datum->setValue(value) != 0)
        return PyErr_Format(PyExc_ValueError,
            "%s: cannot set type '%s' to value '%s'",
            datum->key().c_str(), Exiv2::TypeInfo::typeName(old_type),
            value.c_str());
    name##_type_change_warn(datum, old_type);
    return SWIG_Py_Void();
};
%}
// Add methods to base class
%extend base_class {
    long __len__() {
        return $self->count();
    }
    datum_type* __getitem__(const std::string& key) {
        return &(*$self)[key];
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        datum_type* datum = &(*$self)[key];
        Exiv2::TypeId old_type = name##_default_type(datum);
        datum->setValue(value);
        name##_type_change_warn(datum, old_type);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        datum_type* datum = &(*$self)[key];
        return name##_set_value(datum, value);
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        const char* c_str = PyUnicode_AsUTF8(py_str);
        Py_DECREF(py_str);
        datum_type* datum = &(*$self)[key];
        return name##_set_value(datum, c_str);
    }
#if defined(SWIGPYTHON_BUILTIN)
    PyObject* __setitem__(const std::string& key) {
#else
    PyObject* __delitem__(const std::string& key) {
#endif
        base_class::iterator pos = $self->findKey(key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->erase(pos);
        return SWIG_Py_Void();
    }
    int __contains__(const std::string& key) {
        base_class::iterator pos = $self->findKey(key_type(key));
        return (pos == $self->end()) ? 0 : 1;
    }
}
%enddef // DATA_MAPPING_METHODS

// Macro to wrap data iterators
%define DATA_ITERATOR(name, base_class, iterator_type, datum_type)
%feature("python:slot", "tp_iter",
         functype="getiterfunc") base_class::__iter__;
%feature("python:slot", "tp_iter",
         functype="getiterfunc") name##Iterator::__iter__;
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") name##Iterator::__next__;
%feature("python:slot", "tp_str",
         functype="reprfunc") name##Iterator::__str__;
// typemaps
%typemap(in) iterator_type (int res, name##Iterator *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp,
                          $descriptor(name##Iterator*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, name##Iterator, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(name##Iterator, $symname, $argnum);
    }
    $1 = argp->_unwrap();
%};
// "out" typemap assumes arg1 is always the base_class parent and
// self is always the Python parent
%typemap(out) iterator_type %{
    $result = SWIG_NewPointerObj(
        new name##Iterator($1, arg1->end(), self),
        $descriptor(name##Iterator*), SWIG_POINTER_OWN);
%};
// Check iterator before dereferencing it
%typemap(check) name##Iterator* self %{
    if (strcmp("$symname", "delete_"#name"Iterator") &&
        strcmp("$symname", #name"Iterator___iter__") &&
        strcmp("$symname", #name"Iterator___str__") &&
        strcmp("$symname", #name"Iterator___eq__") &&
        strcmp("$symname", #name"Iterator___ne__"))
        if ($1->_ptr_invalid())
            SWIG_fail;
%};
%newobject name##Iterator::__iter__;
%ignore name##Iterator::name##Iterator;
%ignore name##Iterator::_unwrap;
%ignore name##Iterator::_ptr_invalid;
%feature("docstring") name##Iterator "Python wrapper for "#iterator_type"."
%extend base_class {
    iterator_type __iter__() {
        return $self->begin();
    }
}
%inline %{
class name##Iterator {
private:
    iterator_type ptr;
    iterator_type end;
    PyObject* parent;
public:
    name##Iterator(
            iterator_type ptr, iterator_type end, PyObject* parent) {
        this->ptr = ptr;
        this->end = end;
        this->parent = parent;
        Py_INCREF(parent);
    }
    ~name##Iterator() {
        Py_DECREF(parent);
    }
    datum_type* operator->() const {
        return &(*ptr);
    }
    name##Iterator* __iter__() {
        return new name##Iterator(ptr, end, parent);
    }
    iterator_type _unwrap() const {
        return ptr;
    }
    datum_type* __next__() {
        return &(*ptr++);
    }
    bool operator==(const name##Iterator &other) const {
        return other._unwrap() == ptr;
    }
    bool operator!=(const name##Iterator &other) const {
        return other._unwrap() != ptr;
    }
    bool _ptr_invalid() {
        if (ptr == end) {
            PyErr_SetString(PyExc_StopIteration, "iterator at end of data");
            return true;
        }
        return false;
    }
    std::string __str__() {
        std::string result;
        if (ptr == end)
            result = "end of data";
        else
            result = ptr->key() + ": " + ptr->print();
        result = "iterator<" + result + ">";
        return result;
    }
};
%}
%enddef // DATA_ITERATOR

// Macros to wrap data while keeping a reference to its image
// Macro that actually does everything, either declaration only or implemented
%define _DATA_WRAPPER(name, base_class, datum_type, key_type, mode)
// Allow name##Wrap to be passed where base_class is expected
%typemap(in) base_class& (int res, name##Wrap* arg_wrap, base_class* arg_base) %{
    res = SWIG_ConvertPtr($input, (void**)&arg_wrap, $descriptor(name##Wrap*), 0);
    if (SWIG_IsOK(res)) {
        // Input is wrapped name
        if (!arg_wrap) {
            %argument_nullref(name##Wrap, $symname, $argnum);
        }
        $1 = arg_wrap->_unwrap();
    }
    else {
        // Input should be of type base_class
        res = SWIG_ConvertPtr($input, (void**)&arg_base,
                              $descriptor(base_class*), 0);
        if (!SWIG_IsOK(res)) {
            %argument_fail(res, base_class, $symname, $argnum);
        }
        if (!arg_base) {
            %argument_nullref(base_class, $symname, $argnum);
        }
        $1 = arg_base;
    }
%};
%ignore name##Wrap::name##Wrap;
%ignore name##Wrap::_unwrap;
%ignore name##Wrap::operator[];
%ignore name##Wrap::count;
%ignore name##Wrap::begin;
%ignore name##Wrap::end;
%ignore name##Wrap::erase;
%ignore name##Wrap::findKey;
%feature("docstring") name##Wrap
    "Python wrapper for "#base_class
    ".\nSee that class's documentation for full details."
mode %{
class name##Wrap {
private:
    base_class* base;
    PyObject* image;
public:
    typedef base_class::iterator iterator;
    name##Wrap(base_class* base, PyObject* image) {
        this->base = base;
        Py_INCREF(image);
        this->image = image;
    }
    ~name##Wrap() {
        Py_XDECREF(image);
    }
    base_class* operator->() {
        return base;
    }
    base_class* _unwrap() {
        return base;
    }
    // make some base class methods available to C++ (operator-> makes them
    // all available to Python)
    datum_type& operator[](const std::string &key) {
        return (*base)[key];
    }
    long count() const {
        return base->count();
    }
    base_class::iterator begin() {
        return base->begin();
    }
    base_class::iterator end() {
        return base->end();
    }
    base_class::iterator erase(base_class::iterator pos) {
        return base->erase(pos);
    }
    base_class::iterator findKey(const key_type &key) {
        return base->findKey(key);
    }
};
%}
%enddef // _DATA_WRAPPER

// Macro to declare wrapped class for C++ use but not for Python
%define DATA_WRAPPER_DEC(name, base_class, datum_type, key_type)
_DATA_WRAPPER(name, base_class, datum_type, key_type, )
%enddef // DATA_WRAPPER_DEC

// Macro to declare wrapped class for Python and C++
%define DATA_WRAPPER(name, base_class, datum_type, key_type)
_DATA_WRAPPER(name, base_class, datum_type, key_type, %inline)
%enddef // DATA_WRAPPER

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
%enddef // ENUM

// Stuff to handle auto_ptr or unique_ptr
#if EXIV2_VERSION_HEX < 0x01000000
%define wrap_auto_unique_ptr(pointed_type)
%include "std_auto_ptr.i"
%auto_ptr(pointed_type)
%enddef // wrap_auto_unique_ptr
#else
template <typename T>
struct std::unique_ptr {};
%define wrap_auto_unique_ptr(pointed_type)
%typemap(out) std::unique_ptr<pointed_type> %{
    $result = SWIG_NewPointerObj(
        (&$1)->release(), $descriptor(pointed_type *), SWIG_POINTER_OWN);
%}
%template() std::unique_ptr<pointed_type>;
%enddef // wrap_auto_unique_ptr
#endif
