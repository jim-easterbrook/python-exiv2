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
    Exiv2::parent_class::iterator __next__() {
        return ptr++;
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
%define DATA_LISTMAP(class, datum_type, key_type, default_type_func)
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") Exiv2::class::__getitem__;
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") Exiv2::class::__setitem__;
%feature("python:slot", "sq_length",
         functype="lenfunc") Exiv2::class::__len__;
%feature("python:slot", "sq_item",
         functype="ssizeargfunc") Exiv2::class::_sq_item;
%feature("python:slot", "sq_contains",
         functype="objobjproc") Exiv2::class::__contains__;
%{
static PyObject* class ## _getitem_idx(Exiv2::class* self, long idx,
                                       swig_type_info* datum_descriptor) {
    using namespace Exiv2;
    long len = self->count();
    if ((idx < -len) || (idx >= len))
        return PyErr_Format(PyExc_IndexError, "index %d out of range", idx);
    if (idx < 0)
        idx += len;
    class::iterator pos;
    if (idx > (len / 2)) {
        pos = self->end();
        idx = len - idx;
        while (idx > 0) {
            pos--;
            idx--;
        }
    }
    else {
        pos = self->begin();
        while (idx > 0) {
            pos++;
            idx--;
        }
    }
    return SWIG_Python_NewPointerObj(
        NULL, SWIG_as_voidptr(&(*pos)), datum_descriptor, 0);
}
%}
%extend Exiv2::class {
    PyObject* __getitem__(PyObject* key_idx) {
        using namespace Exiv2;
        if (PyLong_Check(key_idx))
            // Index by integer
            return class ## _getitem_idx(
                $self, PyLong_AsLong(key_idx), $descriptor(Exiv2::datum_type*));
        if (PyUnicode_Check(key_idx))
            // Lookup by key
            return SWIG_Python_NewPointerObj(
                NULL, SWIG_as_voidptr(&(*$self)[PyUnicode_AsUTF8(key_idx)]),
                $descriptor(Exiv2::datum_type*), 0);
        return PyErr_Format(PyExc_TypeError,
            "indices must be int or str, not %s", Py_TYPE(key_idx)->tp_name);
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type_func;
        Exiv2::Value* c_value = NULL;
        if (SWIG_IsOK(SWIG_ConvertPtr(value, (void**)(&c_value),
                                      $descriptor(Exiv2::Value*), 0)))
            // value is an Exiv2::Value
            datum->setValue(c_value);
        else {
            char* c_str = NULL;
            if (PyUnicode_Check(value)) {
                // value is already a string
                c_str = PyUnicode_AsUTF8(value);
            }
            else {
                // Get equivalent of Python "str(value)"
                PyObject* py_str = PyObject_Str(value);
                if (py_str == NULL)
                    return NULL;
                c_str = PyUnicode_AsUTF8(py_str);
                Py_DECREF(py_str);
            }
            if (datum->setValue(c_str) != 0)
                return PyErr_Format(PyExc_ValueError,
                    "%s: cannot set type '%s' to value '%s'",
                    key.c_str(), TypeInfo::typeName(old_type), c_str);
        }
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << key << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
        return SWIG_Py_Void();
    }
#if defined(SWIGPYTHON_BUILTIN)
    PyObject* __setitem__(const std::string& key) {
#else
    PyObject* __delitem__(const std::string& key) {
#endif
        using namespace Exiv2;
        class::iterator pos = $self->findKey(key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->erase(pos);
        return SWIG_Py_Void();
    }
    long __len__() {
        return $self->count();
    }
    PyObject* _sq_item(long i) {
        return class ## _getitem_idx($self, i, $descriptor(Exiv2::datum_type*));
    }
    int __contains__(const std::string& key) {
        using namespace Exiv2;
        class::iterator pos = $self->findKey(key_type(key));
        return (pos == $self->end()) ? 0 : 1;
    }
    PyObject* keys() {
        using namespace Exiv2;
        long len = $self->count();
        PyObject* result = PyList_New(len);
        class::iterator datum = $self->begin();
        for (long i = 0; i < len; i++)
            PyList_SET_ITEM(result, i, PyUnicode_FromString(
                (datum++)->key().c_str()));
        return result;
    }
    PyObject* values() {
        using namespace Exiv2;
        long len = $self->count();
        PyObject* result = PyList_New(len);
        class::iterator datum = $self->begin();
        for (long i = 0; i < len; i++)
            PyList_SET_ITEM(result, i, SWIG_Python_NewPointerObj(
                NULL, ((datum++)->getValue()).release(),
                $descriptor(Exiv2::Value*), SWIG_POINTER_OWN));
        return result;
    }
    PyObject* items() {
        using namespace Exiv2;
        long len = $self->count();
        PyObject* result = PyList_New(len);
        class::iterator datum = $self->begin();
        for (long i = 0; i < len; i++) {
            PyList_SET_ITEM(result, i, PyTuple_Pack(
                2, PyUnicode_FromString(datum->key().c_str()),
                SWIG_Python_NewPointerObj(
                    NULL, (datum->getValue()).release(),
                    $descriptor(Exiv2::Value*), SWIG_POINTER_OWN)));
            datum++;
        }
        return result;
    }
}
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
