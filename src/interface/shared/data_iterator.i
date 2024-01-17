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


// Macros to wrap data iterators
%define DATA_ITERATOR_CLASSES(name, iterator_type, datum_type)
%feature("python:slot", "tp_str", functype="reprfunc")
    name##_base::__str__;
%feature("python:slot", "tp_iter", functype="getiterfunc")
    name##_base::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    name##_base::__next__;
%noexception name##_base::__iter__;
%noexception name##_base::operator==;
%noexception name##_base::operator!=;
%ignore name##_base::size;
%ignore name##_base::name##_base;
%ignore name##_base::operator*;
%ignore name##_base::valid;
%feature("docstring") name "
Python wrapper for an " #iterator_type ". It has most of
the methods of " #datum_type " allowing easy access to the
data it points to.
"
%feature("docstring") name##_base "
Python wrapper for an " #iterator_type " that points to
the 'end' value and can not be dereferenced.
"
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(name*)
KEEP_REFERENCE(name##_base*)
// Detect end of iteration
%exception name##_base::__next__ %{
    $action
    if (!result) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
%}
%inline %{
// Base class implements all methods except dereferencing
class name##_base {
protected:
    iterator_type ptr;
    iterator_type end;
    iterator_type safe_ptr;
public:
    name##_base(iterator_type ptr, iterator_type end) {
        this->ptr = ptr;
        this->end = end;
        safe_ptr = ptr;
    }
    name##_base* __iter__() { return this; }
    datum_type* __next__() {
        if (!valid())
            return NULL;
        datum_type* result = &(*safe_ptr);
        ptr++;
        if (valid())
            safe_ptr = ptr;
        return result;
    }
    iterator_type operator*() const { return ptr; }
    bool operator==(const name##_base &other) const { return *other == ptr; }
    bool operator!=(const name##_base &other) const { return *other != ptr; }
    std::string __str__() {
        if (valid())
            return "iterator<" + ptr->key() + ": " + ptr->print() + ">";
        return "iterator<end>";
    }
    bool valid() { return ptr != end; }
    // Provide size() C++ method for buffer size check
    size_t size() {
        if (valid())
            return safe_ptr->size();
        return 0;
    }
};
// Derived class can be dereferenced, giving Python access to all datum
// methods.
class name : public name##_base {
public:
    datum_type* operator->() const { return &(*safe_ptr); }
};
%}
%enddef // DATA_ITERATOR_CLASSES

// Declare typemaps for data iterators.
%define DATA_ITERATOR_TYPEMAPS(name, iterator_type)
%typemap(in) iterator_type (int res, name##_base *argp) %{
    res = SWIG_ConvertPtr(
        $input, (void**)&argp, $descriptor(name##_base*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, name##_base, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(name##_base, $symname, $argnum);
    }
    $1 = **argp;
%};
// Return types depend on validity of iterator
%typemap(out) name##_base* {
    $result = SWIG_NewPointerObj((void*)$1,
        $1->valid() ? $descriptor(name*) : $descriptor(name##_base*), 0);
}
// Assumes arg1 is the base class parent
%typemap(out) iterator_type {
    name##_base* tmp = new name##_base($1, arg1->end());
    $result = SWIG_NewPointerObj((void*)tmp,
        tmp->valid() ? $descriptor(name*) : $descriptor(name##_base*),
        SWIG_POINTER_OWN);
};
// Keep a reference to the data being iterated
KEEP_REFERENCE(iterator_type)
%enddef // DATA_ITERATOR_TYPEMAPS
