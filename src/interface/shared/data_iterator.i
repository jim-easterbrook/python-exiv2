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
%feature("python:slot", "tp_str", functype="reprfunc") name##_end::__str__;
%feature("python:slot", "tp_iter", functype="getiterfunc") name##_end::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    name##_end::__next__;
%feature("python:slot", "tp_iter", functype="getiterfunc") name::__iter__;
// Add slots to main class using base class methods
%feature("python:tp_str") name
    "_wrap_" #name "_end___str___reprfunc_closure";
%feature("python:tp_iternext") name
    "_wrap_" #name "_end___next___iternextfunc_closure";
%newobject name::__iter__;
%newobject name##_end::__iter__;
%noexception name##_end::operator==;
%noexception name##_end::operator!=;
%ignore name::name;
%ignore name::size;
%ignore name##_end::name##_end;
%ignore name##_end::operator*;
%feature("docstring") name "
Python wrapper for an " #iterator_type ". It has most of
the methods of " #datum_type " allowing easy access to the
data it points to.
"
%feature("docstring") name##_end "
Python wrapper for an " #iterator_type " that points to
the 'end' value and can not be dereferenced.
"
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(name*)
KEEP_REFERENCE(name##_end*)
// Detect end of iteration
%exception name##_end::__next__ %{
    $action
    if (!result) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
%}
%inline %{
// Base class supports a single fixed pointer that never gets dereferenced
class name##_end {
protected:
    iterator_type ptr;
    iterator_type end;
    iterator_type safe_ptr;
public:
    name##_end(iterator_type ptr, iterator_type end) {
        this->ptr = ptr;
        this->end = end;
        safe_ptr = ptr;
    }
    name##_end* __iter__() { return new name##_end(ptr, end); }
    datum_type* __next__() {
        if (ptr == end) {
            return NULL;
        }
        datum_type* result = &(*safe_ptr);
        ptr++;
        if (ptr != end) {
            safe_ptr = ptr;
        }
        return result;
    }
    iterator_type operator*() const { return ptr; }
    bool operator==(const name##_end &other) const { return *other == ptr; }
    bool operator!=(const name##_end &other) const { return *other != ptr; }
    std::string __str__() {
        if (ptr == end)
            return "iterator<end>";
        return "iterator<" + ptr->key() + ": " + ptr->print() + ">";
    }
};
// Main class always has a dereferencable pointer in safe_ptr, so no extra checks
// are needed.
class name : public name##_end {
public:
    name(iterator_type ptr, iterator_type end) : name##_end(ptr, end) {}
    datum_type* operator->() const { return &(*safe_ptr); }
    name* __iter__() { return new name(safe_ptr, end); }
    // Provide size() C++ method for buffer size check
    size_t size() { return safe_ptr->size(); }
};
%}
%enddef // DATA_ITERATOR_CLASSES

// Declare typemaps for data iterators.
%define DATA_ITERATOR_TYPEMAPS(name, iterator_type)
%typemap(in) iterator_type (int res, name##_end *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp, $descriptor(name##_end*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, name##_end, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(name##_end, $symname, $argnum);
    }
    $1 = **argp;
%};
// assumes arg1 is the base class parent
%typemap(out) iterator_type {
    iterator_type end = arg1->end();
    if ((iterator_type)$1 == end)
        $result = SWIG_NewPointerObj(
            new name##_end($1, end), $descriptor(name##_end*), SWIG_POINTER_OWN);
    else
        $result = SWIG_NewPointerObj(
            new name($1, end), $descriptor(name*), SWIG_POINTER_OWN);
};
// Keep a reference to the data being iterated
KEEP_REFERENCE(iterator_type)
%enddef // DATA_ITERATOR_TYPEMAPS