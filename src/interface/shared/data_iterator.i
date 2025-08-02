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


%include "shared/keep_reference.i"


// Macros to wrap data iterators
%define DATA_ITERATOR_CLASSES(container_type, datum_type)
%feature("python:slot", "tp_str", functype="reprfunc")
    container_type##_iterator::__str__;
%feature("python:slot", "tp_iter", functype="getiterfunc")
    container_type##_iterator::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    container_type##_iterator::__next__;
%noexception container_type##_iterator::__iter__;
%noexception container_type##_iterator::operator==;
%noexception container_type##_iterator::operator!=;
%ignore container_type##_iterator::size;
%ignore container_type##_iterator::##container_type##_iterator;
%ignore container_type##_iterator::operator*;
%ignore container_type##_iterator::valid;
%feature("docstring") container_type##_iterator "
Python wrapper for an :class:`" #container_type "` iterator. It has most of
the methods of :class:`" #datum_type "` allowing easy access to the
data it points to."
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(container_type##_iterator*)
// Detect end of iteration
%exception container_type##_iterator::__next__ %{
    $action
    if (!result) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
%}
%inline %{
// Base class implements all methods except dereferencing
class container_type##_iterator {
protected:
    Exiv2::container_type::iterator ptr;
    Exiv2::container_type::iterator end;
public:
    container_type##_iterator(Exiv2::container_type::iterator ptr,
                              Exiv2::container_type::iterator end) {
        this->ptr = ptr;
        this->end = end;
    }
    container_type##_iterator* __iter__() { return this; }
    Exiv2::datum_type* __next__() {
        if (!valid())
            return NULL;
        Exiv2::datum_type* result = &(*ptr);
        ptr++;
        return result;
    }
    Exiv2::container_type::iterator operator*() const { return ptr; }
    bool operator==(const container_type##_iterator &other) const {
        return *other == ptr;
    }
    bool operator!=(const container_type##_iterator &other) const {
        return *other != ptr;
    }
    std::string __str__() {
        if (valid())
            return "iterator<" + ptr->key() + ": " + ptr->print() + ">";
        return "iterator<end>";
    }
    bool valid() { return ptr != end; }
    // Provide method to invalidate iterator
    void _invalidate() { ptr = end; }
    // Provide size() C++ method for buffer size check
    size_t size() {
        if (valid())
            return ptr->size();
        return 0;
    }
    // Dereference operator gives access to all datum methods
    Exiv2::datum_type* operator->() const { return &(*ptr); }
};
// Bypass validity check for some methods
#define NOCHECK_delete_##container_type##_iterator
#define NOCHECK_##container_type##_iterator___iter__
#define NOCHECK_##container_type##_iterator___next__
#define NOCHECK_##container_type##_iterator___eq__
#define NOCHECK_##container_type##_iterator___ne__
#define NOCHECK_##container_type##_iterator___str__
#define NOCHECK_##container_type##_iterator__invalidate
%}
%enddef // DATA_ITERATOR_CLASSES

// Declare typemaps for data iterators.
%define DATA_ITERATOR_TYPEMAPS(container_type)
%typemap(in) Exiv2::container_type::iterator
        (container_type##_iterator *argp=NULL) %{
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    $1 = **argp;
%}
#if SWIG_VERSION < 0x040400
// erase() invalidates the iterator
%typemap(in) (Exiv2::container_type::iterator pos)
        (container_type##_iterator *argp=NULL),
             (Exiv2::container_type::iterator beg)
        (container_type##_iterator *argp=NULL) {
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    $1 = **argp;
    argp->_invalidate();
}
#endif
// XmpData::eraseFamily takes an iterator reference (and invalidates it)
%typemap(in) Exiv2::container_type::iterator&
        (Exiv2::container_type::iterator it,
         container_type##_iterator* argp = NULL) {
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    it = **argp;
    $1 = &it;
#if SWIG_VERSION < 0x040400
    argp->_invalidate();
#endif
}
// Check validity of iterator before dereferencing
%typemap(check) container_type##_iterator* self {
%#ifndef NOCHECK_##$symname
    if (!$1->valid()) {
        SWIG_exception_fail(SWIG_ValueError, "in method '" "$symname"
            "', invalid iterator cannot be dereferenced");
    }
%#endif
}

// Functions to store weak references to iterators (swig >= v4.4)
%fragment("iterator_weakref_funcs", "header", fragment="private_data") {
static void _process_list(PyObject* list, bool invalidate) {
    PyObject* ref = NULL;
    PyObject* iterator = NULL;
    for (Py_ssize_t idx = PyList_Size(list); idx > 0; idx--) {
        ref = PyList_GetItem(list, idx - 1);
        iterator = PyWeakref_GetObject(ref);
        if (iterator == Py_None)
            PyList_SetSlice(list, idx - 1, idx, NULL);
        else if (invalidate)
            Py_XDECREF(PyObject_CallMethod(iterator, "_invalidate", NULL));
    }
};
static void purge_iterators(PyObject* list) {
    _process_list(list, false);
};
static void invalidate_iterators(PyObject* py_self) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list)
        _process_list(list, true);
};
static int store_iterator_weakref(PyObject* py_self, PyObject* iterator) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list)
        purge_iterators(list);
    else {
        list = PyList_New(0);
        if (!list)
            return -1;
        int error = private_store_set(py_self, "iterators", list);
        Py_DECREF(list);
        if (error)
            return -1;
    }
    PyObject* ref = PyWeakref_NewRef(iterator, NULL);
    if (!ref)
        return -1;
    int result = PyList_Append(list, ref);
    Py_DECREF(ref);
    return result;
};
}

#if SWIG_VERSION >= 0x040400
// clear() invalidates all iterators
%typemap(ret, typemap="iterator_weakref_funcs") void clear {
    invalidate_iterators(self);
}
// erase() and eraseFamily() may invalidate iterators
%typemap(check) (Exiv2::container_type::iterator pos),
                (Exiv2::container_type::iterator beg),
                (Exiv2::container_type::iterator&) {
    invalidate_iterators(self);
}
#endif // SWIG_VERSION

%newobject Exiv2::container_type::begin;
%newobject Exiv2::container_type::end;
%newobject Exiv2::container_type::erase;
%newobject Exiv2::container_type::findId;
%newobject Exiv2::container_type::findKey;
// Assumes arg1 is the base class parent
#if SWIG_VERSION >= 0x040400
%typemap(out, fragment="iterator_weakref_funcs") Exiv2::container_type::iterator {
#else
%typemap(out) Exiv2::container_type::iterator {
#endif
    Exiv2::container_type::iterator tmp = $1;
    container_type##_iterator* $1 = new container_type##_iterator(
        tmp, arg1->end());
    $typemap(out, container_type##_iterator*);
#if SWIG_VERSION >= 0x040400
    if ($1->valid()) {
        // Keep weak reference to the Python iterator
        if (store_iterator_weakref(self, $result)) {
            SWIG_fail;
        }
    }
#endif // SWIG_VERSION
}
// Keep a reference to the data being iterated
KEEP_REFERENCE(Exiv2::container_type::iterator)
%enddef // DATA_ITERATOR_TYPEMAPS
