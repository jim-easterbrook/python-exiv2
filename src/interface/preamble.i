// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
PyObject* PyExc_Exiv2Error = NULL;
PyObject* logger = NULL;
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("exiv2");
    if (module != NULL) {
        PyExc_Exiv2Error = PyObject_GetAttrString(module, "Exiv2Error");
        logger = PyObject_GetAttrString(module, "_logger");
        Py_DECREF(module);
    }
    if (PyExc_Exiv2Error == NULL || logger == NULL)
        return NULL;
}
%}

// Catch all C++ exceptions
%exception {
    try {
        $action
#if EXIV2_VERSION_HEX < 0x01000000
    } catch(Exiv2::AnyError const& e) {
#else
    } catch(Exiv2::Error const& e) {
#endif
        PyErr_SetString(PyExc_Exiv2Error, e.what());
        SWIG_fail;
    } catch(std::exception const& e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
        SWIG_fail;
    }
}

// Macros to wrap data iterators
%define _DATA_ITERATOR(wrap_class, iterator_type, datum_type, mode)
%feature("python:slot", "tp_iter",
         functype="getiterfunc") wrap_class##_iterator_end::__iter__;
%feature("python:slot", "tp_iternext",
         functype="iternextfunc") wrap_class##_iterator_end::__next__;
%feature("python:slot", "tp_str",
         functype="reprfunc") wrap_class##_iterator_end::__str__;
%feature("python:slot", "tp_iter",
         functype="getiterfunc") wrap_class##_iterator::__iter__;
%newobject wrap_class##_iterator::__iter__;
%newobject wrap_class##_iterator_end::__iter__;
%noexception wrap_class##_iterator_end::operator==;
%noexception wrap_class##_iterator_end::operator!=;
%ignore wrap_class##_iterator::wrap_class##_iterator;
%ignore wrap_class##_iterator_end::wrap_class##_iterator_end;
%ignore wrap_class##_iterator_end::operator*;
%feature("docstring") wrap_class##_iterator "
Python wrapper for an " #iterator_type ". It has most of
the methods of " #datum_type " allowing easy access to the
data it points to.
"
%feature("docstring") wrap_class##_iterator_end "
Python wrapper for an " #iterator_type " that points to
" #wrap_class "::end().
"
%exception wrap_class##_iterator_end::__next__ %{
    $action
    if (PyErr_Occurred())
        SWIG_fail;
%}
mode %{
// Base class supports a single fixed pointer that never gets dereferenced
class wrap_class##_iterator_end {
protected:
    iterator_type ptr;
    iterator_type end;
    iterator_type safe_ptr;
    PyObject* parent;
public:
    wrap_class##_iterator_end(iterator_type ptr, iterator_type end, PyObject* parent) {
        this->ptr = ptr;
        this->end = end;
        this->parent = parent;
        safe_ptr = ptr;
        Py_INCREF(parent);
    }
    ~wrap_class##_iterator_end() {
        Py_DECREF(parent);
    }
    wrap_class##_iterator_end* __iter__() {
        return new wrap_class##_iterator_end(ptr, end, parent);
    }
    datum_type* __next__() {
        datum_type* result = NULL;
        if (ptr == end) {
            PyErr_SetNone(PyExc_StopIteration);
            return NULL;
        }
        result = &(*safe_ptr);
        ptr++;
        if (ptr != end) {
            safe_ptr = ptr;
        }
        return result;
    }
    iterator_type operator*() const {
        return ptr;
    }
    bool operator==(const wrap_class##_iterator_end &other) const {
        return *other == ptr;
    }
    bool operator!=(const wrap_class##_iterator_end &other) const {
        return *other != ptr;
    }
    std::string __str__() {
        if (ptr == end)
            return "iterator<end>";
        return "iterator<" + ptr->key() + ": " + ptr->print() + ">";
    }
};
// Main class always has a dereferencable pointer in safe_ptr, so no extra checks
// are needed.
class wrap_class##_iterator : public wrap_class##_iterator_end {
public:
    wrap_class##_iterator(iterator_type ptr, iterator_type end, PyObject* parent)
                   : wrap_class##_iterator_end(ptr, end, parent) {}
    datum_type* operator->() const {
        return &(*safe_ptr);
    }
    wrap_class##_iterator* __iter__() {
        return new wrap_class##_iterator(safe_ptr, end, parent);
    }
};
%}
%enddef // _DATA_ITERATOR

// Macros to wrap data containers.
%define _USE_DATA_CONTAINER(wrap_class, base_class)
// wrapped class entirely replaces original class
%ignore base_class;
// typemaps for class conversions
%typemap(in) base_class& (int res, wrap_class* argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp, $descriptor(wrap_class*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, wrap_class, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(wrap_class, $symname, $argnum);
    }
    $1 = **argp;
%};
// assumes self is the Python image parent
%typemap(out) base_class& %{
    $result = SWIG_NewPointerObj(
        new wrap_class($1, self), $descriptor(wrap_class*), SWIG_POINTER_OWN);
%};
// typemaps for iterator conversions
%typemap(in) base_class::iterator (int res, wrap_class##_iterator_end *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp,
                          $descriptor(wrap_class##_iterator_end*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, wrap_class##_iterator_end, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(wrap_class##_iterator_end, $symname, $argnum);
    }
    $1 = **argp;
%};
// assumes arg1 is the wrap_class parent and self is the Python parent
%typemap(out) base_class::iterator {
    base_class::iterator end = (*arg1)->end();
    if ((base_class::iterator)$1 == end)
        $result = SWIG_NewPointerObj(
            new wrap_class##_iterator_end($1, end, self),
            $descriptor(wrap_class##_iterator_end*), SWIG_POINTER_OWN);
    else
        $result = SWIG_NewPointerObj(
            new wrap_class##_iterator($1, end, self),
            $descriptor(wrap_class##_iterator*), SWIG_POINTER_OWN);
};
// replace buf size check to dereference arg1/self
%typemap(check) (wrap_class##_iterator const* self, Exiv2::byte* buf) %{
    if (_global_len < (*$1)->size()) {
        PyErr_Format(PyExc_ValueError,
            "in method '$symname', '$2_name' value is a %d byte buffer,"
            " %d bytes needed",
            _global_len, (*$1)->size());
        SWIG_fail;
    }
%}
%enddef // _USE_DATA_CONTAINER

// Declare the above typemaps everywhere
_USE_DATA_CONTAINER(ExifData, Exiv2::ExifData)
_USE_DATA_CONTAINER(IptcData, Exiv2::IptcData)
_USE_DATA_CONTAINER(XmpData, Exiv2::XmpData)

// DATA_CONTAINER defines a class, so needs to be declared in every
// module that uses the class
%define DATA_CONTAINER(wrap_class, base_class, datum_type, key_type,
                       default_type_func, mode)
_DATA_ITERATOR(wrap_class, base_class::iterator, datum_type, mode)
%feature("python:slot", "tp_iter",
         functype="getiterfunc") wrap_class::__iter__;
%feature("python:slot", "mp_length",
         functype="lenfunc") wrap_class::__len__;
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") wrap_class::__getitem__;
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") wrap_class::__setitem__;
%feature("python:slot", "sq_contains",
         functype="objobjproc") wrap_class::__contains__;
%ignore wrap_class::wrap_class(base_class* base, PyObject* owner);
%ignore wrap_class::operator*;
%ignore wrap_class::_default_type;
%ignore wrap_class::_type_change_warn;
%ignore wrap_class::_set_value;
%noexception wrap_class::__iter__;
%noexception wrap_class::__len__;
mode %{
class wrap_class {
private:
    base_class* base;
    PyObject* owner;
public:
    wrap_class() {
        this->base = new base_class();
        this->owner = NULL;
    }
    wrap_class(base_class* base, PyObject* owner) {
        this->base = base;
        Py_INCREF(owner);
        this->owner = owner;
    }
    ~wrap_class() {
        Py_XDECREF(owner);
    }
    base_class::iterator __iter__() {
        return base->begin();
    }
    // Provide Python access to base_class members
    base_class* operator->() const {
        return base;
    }
    // Provide C++ access to base_class members
    base_class* operator*() const {
        return base;
    }
    // Methods to provide dict like behaviour
    long __len__() {
        return base->count();
    }
    datum_type* __getitem__(const std::string& key) {
        return &(*base)[key];
    }
    // __setitem__ helper methods
    Exiv2::TypeId _default_type(datum_type* datum) {
        Exiv2::TypeId old_type = datum->typeId();
        if (old_type == Exiv2::invalidTypeId)
            old_type = default_type_func;
        return old_type;
    }
    static void _type_change_warn(datum_type* datum, Exiv2::TypeId old_type) {
        using namespace Exiv2;
        TypeId new_type = datum->typeId();
        if (new_type == old_type)
            return;
        EXV_WARNING << datum->key() << ": changed type from '" <<
            TypeInfo::typeName(old_type) << "' to '" <<
            TypeInfo::typeName(new_type) << "'.\n";
    }
    PyObject* _set_value(datum_type* datum, const std::string& value) {
        Exiv2::TypeId old_type = _default_type(datum);
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), Exiv2::TypeInfo::typeName(old_type),
                value.c_str());
        _type_change_warn(datum, old_type);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        datum_type* datum = &(*base)[key];
        Exiv2::TypeId old_type = _default_type(datum);
        datum->setValue(value);
        _type_change_warn(datum, old_type);
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        datum_type* datum = &(*base)[key];
        return _set_value(datum, value);
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        const char* c_str = PyUnicode_AsUTF8(py_str);
        Py_DECREF(py_str);
        datum_type* datum = &(*base)[key];
        return _set_value(datum, c_str);
    }
#if defined(SWIGPYTHON_BUILTIN)
    PyObject* __setitem__(const std::string& key) {
#else
    PyObject* __delitem__(const std::string& key) {
#endif
        base_class::iterator pos = base->findKey(key_type(key));
        if (pos == base->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        base->erase(pos);
        return SWIG_Py_Void();
    }
    bool __contains__(const std::string& key) {
        return base->findKey(key_type(key)) != base->end();
    }
};
%}
%enddef // DATA_CONTAINER

// Macro to make enums more Pythonic
%define ENUM(name, doc, contents...)
%{
#ifndef ENUM_HELPER
#define ENUM_HELPER
#include <cstdarg>
static PyObject* _get_enum_list(int dummy, ...) {
    PyObject* result = PyList_New(0);
    va_list args;
    va_start(args, dummy);
    char* label = va_arg(args, char*);
    int value = va_arg(args, int);
    while (label) {
        PyList_Append(result, PyTuple_Pack(2,
            PyUnicode_FromString(label), PyLong_FromLong(value)));
        label = va_arg(args, char*);
        value = va_arg(args, int);
    }
    va_end(args);
    return result;
};
#endif // #ifndef ENUM_HELPER
%}
%inline %{
PyObject* _enum_list_##name() {
    return _get_enum_list(0, contents, NULL, 0);
};
%}
%pythoncode %{
import enum
name = enum.IntEnum('name', _enum_list_##name())
name.__doc__ = doc
%}
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
