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


%include "shared/keep_reference.i"


// Macros to wrap data iterators
%define DATA_ITERATOR_CLASSES(container_type, datum_type)
%feature("python:slot", "tp_str", functype="reprfunc")
    container_type##_iterator_base::__str__;
%feature("python:slot", "tp_iter", functype="getiterfunc")
    container_type##_iterator_base::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    container_type##_iterator_base::__next__;
%noexception container_type##_iterator_base::__iter__;
%noexception container_type##_iterator_base::operator==;
%noexception container_type##_iterator_base::operator!=;
%ignore container_type##_iterator_base::size;
%ignore container_type##_iterator_base::##container_type##_iterator_base;
%ignore container_type##_iterator_base::operator*;
%ignore container_type##_iterator_base::valid;
%feature("docstring") container_type##_iterator "
Python wrapper for an :class:`" #container_type "` iterator. It has most of
the methods of :class:`" #datum_type "` allowing easy access to the
data it points to."
%feature("docstring") container_type##_iterator_base "
Python wrapper for an :class:`" #container_type "` iterator that points to
the 'end' value and can not be dereferenced."
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(container_type##_iterator*)
KEEP_REFERENCE(container_type##_iterator_base*)
// Detect end of iteration
%exception container_type##_iterator_base::__next__ %{
    $action
    if (!result) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
%}
%inline %{
// Base class implements all methods except dereferencing
class container_type##_iterator_base {
protected:
    Exiv2::container_type::iterator ptr;
    Exiv2::container_type::iterator end;
    Exiv2::container_type::iterator safe_ptr;
public:
    container_type##_iterator_base(Exiv2::container_type::iterator ptr,
                                   Exiv2::container_type::iterator end) {
        this->ptr = ptr;
        this->end = end;
        safe_ptr = ptr;
    }
    container_type##_iterator_base* __iter__() { return this; }
    Exiv2::datum_type* __next__() {
        if (!valid())
            return NULL;
        Exiv2::datum_type* result = &(*safe_ptr);
        ptr++;
        if (valid())
            safe_ptr = ptr;
        return result;
    }
    Exiv2::container_type::iterator operator*() const { return ptr; }
    bool operator==(const container_type##_iterator_base &other) const {
        return *other == ptr;
    }
    bool operator!=(const container_type##_iterator_base &other) const {
        return *other != ptr;
    }
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
class container_type##_iterator : public container_type##_iterator_base {
public:
    Exiv2::datum_type* operator->() const { return &(*safe_ptr); }
};
%}
%enddef // DATA_ITERATOR_CLASSES

// Declare typemaps for data iterators.
%define DATA_ITERATOR_TYPEMAPS(container_type)
%typemap(in) Exiv2::container_type::iterator {
    container_type##_iterator_base *argp = NULL;
    int res = SWIG_ConvertPtr($input, (void**)&argp,
            $descriptor(container_type##_iterator_base*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res,
            container_type##_iterator_base, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(container_type##_iterator_base, $symname, $argnum);
    }
    $1 = **argp;
}
// XmpData::eraseFamily takes an iterator reference (and invalidates it)
%typemap(in) Exiv2::container_type::iterator&
        (Exiv2::container_type::iterator it) {
    container_type##_iterator_base* argp = NULL;
    int res = SWIG_ConvertPtr($input, (void**)&argp,
            $descriptor(container_type##_iterator_base*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res,
            container_type##_iterator_base, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(container_type##_iterator_base, $symname, $argnum);
    }
    it = **argp;
    $1 = &it;
}
// Return types depend on validity of iterator
%typemap(out) container_type##_iterator_base* {
    $result = SWIG_NewPointerObj((void*)$1,
        $1->valid() ? $descriptor(container_type##_iterator*) :
                      $descriptor(container_type##_iterator_base*), 0);
}
// Assumes arg1 is the base class parent
%typemap(out) Exiv2::container_type::iterator {
    container_type##_iterator_base* tmp = new container_type##_iterator_base($1, arg1->end());
    $result = SWIG_NewPointerObj((void*)tmp,
        tmp->valid() ? $descriptor(container_type##_iterator*) :
                       $descriptor(container_type##_iterator_base*),
        SWIG_POINTER_OWN);
}
// Keep a reference to the data being iterated
KEEP_REFERENCE(Exiv2::container_type::iterator)
%enddef // DATA_ITERATOR_TYPEMAPS
