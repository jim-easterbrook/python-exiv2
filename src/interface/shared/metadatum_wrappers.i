/* python-exiv2 - Python interface to libexiv2
 * http://github.com/jim-easterbrook/python-exiv2
 * Copyright (C) 2025  Jim Easterbrook  jim@jim-easterbrook.me.uk
 *
 * This file is part of python-exiv2.
 *
 * python-exiv2 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * python-exiv2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with python-exiv2.  If not, see <http://www.gnu.org/licenses/>.
 */


// Macro to wrap metadatum iterators and pointers
%define METADATUM_WRAPPERS(container_type, datum_type)

// Base class of pointer wrappers
%feature("python:slot", "tp_str", functype="reprfunc")
    datum_type##_pointer::__str__;
%ignore datum_type##_pointer::datum_type##_pointer;
%ignore datum_type##_pointer::~datum_type##_pointer;
%ignore datum_type##_pointer::operator*;
%ignore datum_type##_pointer::size;
%ignore datum_type##_pointer::_invalidate;
%inline %{
class datum_type##_pointer {
protected:
    bool invalidated;
    std::string name;
public:
    virtual ~datum_type##_pointer() {}
    virtual Exiv2::datum_type* operator*() const = 0;
    datum_type##_pointer(): invalidated(false) {}
    bool operator==(const datum_type##_pointer &other) const {
        return *other == **this;
    }
    bool operator!=(const datum_type##_pointer &other) const {
        return *other != **this;
    }
    std::string __str__() {
        if (invalidated)
            return "invalid " + name;
        Exiv2::datum_type* ptr = **this;
        if (!ptr)
            return name + "<end>";
        return name + "<" + ptr->key() + ": " + ptr->print() + ">";
    }
    // Provide size() C++ method for buffer size check
    size_t size() {
        if (invalidated)
            return 0;
        Exiv2::datum_type* ptr = **this;
        if (!ptr)
            return 0;
        return ptr->size();
    }
    // Invalidate iterator unilaterally
    void _invalidate() { invalidated = true; }
    // Dereference operator gives access to all datum methods
    Exiv2::datum_type* operator->() const {
        Exiv2::datum_type* ptr = **this;
        if (!ptr)
            throw std::runtime_error(
                "container_type iterator is at end of data");
        return ptr;
    }
};
%}

// Metadatum iterator wrapper
%feature("python:slot", "tp_iter", functype="getiterfunc")
    container_type##_iterator::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    container_type##_iterator::__next__;
%noexception container_type##_iterator::__iter__;
%ignore container_type##_iterator::##container_type##_iterator;
%ignore container_type##_iterator::operator*;
%ignore container_type##_iterator::_ptr;
%ignore container_type##_iterator::_invalidate;
%feature("docstring") container_type##_iterator "
Python wrapper for an :class:`" #container_type "` iterator. It has most of
the methods of :class:`" #datum_type "` allowing easy access to the
data it points to."
// Detect end of iteration
%typemap(out) Exiv2::datum_type* __next__ {
    if (!$1) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
    $typemap(out, Exiv2::datum_type*)
}
%inline %{
class container_type##_iterator: public datum_type##_pointer {
private:
    Exiv2::container_type::iterator ptr;
    Exiv2::container_type::iterator end;
public:
    container_type##_iterator(
            Exiv2::container_type::iterator ptr,
            Exiv2::container_type::iterator end): ptr(ptr), end(end) {
        name = "iterator";
    }
    container_type##_iterator* __iter__() { return this; }
    Exiv2::datum_type* __next__() {
        if (invalidated)
            throw std::runtime_error(
                "container_type changed size during iteration");
        if (ptr == end)
            return NULL;
        return &(*ptr++);
    }
    Exiv2::datum_type* operator*() const {
        if (invalidated)
            throw std::runtime_error("datum_type reference is invalid");
        if (ptr == end)
            return NULL;
        return &(*ptr);
    }
    using datum_type##_pointer::_invalidate;
    // Invalidate iterator if what it points to has been deleted
    bool _invalidate(Exiv2::container_type::iterator deleted) {
        if (deleted == ptr)
            invalidated = true;
        return invalidated;
    }
    // Access to ptr, for use in other methods
    Exiv2::container_type::iterator _ptr() const {
        if (invalidated)
            throw std::runtime_error("datum_type reference is invalid");
        return ptr;
    }
};
%}
%typemap(in) Exiv2::container_type::iterator
        (container_type##_iterator *argp=NULL) %{
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    $1 = argp->_ptr();
%}
%newobject Exiv2::container_type::begin;
%newobject Exiv2::container_type::end;
%newobject Exiv2::container_type::erase;
%newobject Exiv2::container_type::findId;
%newobject Exiv2::container_type::findKey;
// Assumes arg1 is the base class parent
#if SWIG_VERSION >= 0x040400
%typemap(out, fragment="iterator_store")
    Exiv2::container_type::iterator {
#else
%typemap(out) Exiv2::container_type::iterator {
#endif
    Exiv2::container_type::iterator tmp = $1;
    container_type##_iterator* $1 = new container_type##_iterator(
        tmp, arg1->end());
    $typemap(out, container_type##_iterator*);
#if SWIG_VERSION >= 0x040400
    // Keep weak reference to the Python iterator
    if (store_iterator(self, $result)) {
        SWIG_fail;
    }
#endif // SWIG_VERSION
}

// Metadata reference wrapper
%ignore datum_type##_reference::##datum_type##_reference;
%ignore datum_type##_reference::operator*;
%ignore datum_type##_reference::_invalidate;
%feature("docstring") datum_type##_reference "
Python wrapper for an :class:`" #datum_type "` reference. It has most of
the methods of :class:`" #datum_type "` allowing easy access to the
data it points to."
%inline %{
class datum_type##_reference: public datum_type##_pointer {
private:
    Exiv2::datum_type* ptr;
public:
    datum_type##_reference(Exiv2::datum_type* ptr): ptr(ptr) {
        name = "pointer";
    }
    Exiv2::datum_type* operator*() const {
        if (invalidated)
            throw std::runtime_error("datum_type reference is invalid");
        return ptr;
    }
    using datum_type##_pointer::_invalidate;
    // Invalidate pointer if what it points to has been deleted
    bool _invalidate(Exiv2::datum_type* deleted) {
        if (deleted == ptr)
            invalidated = true;
        return invalidated;
    }
};
%}
%typemap(in) const Exiv2::datum_type& {
    datum_type##_reference* tmp = NULL;
    if (SWIG_IsOK(SWIG_ConvertPtr(
            $input, (void**)&tmp, $descriptor(datum_type##_reference*), 0)))
        $1 = **tmp;
    else {
        $typemap(in, Exiv2::datum_type&)
    }
}
%typemap(out) Exiv2::datum_type& {
    $result = SWIG_NewPointerObj(
        SWIG_as_voidptr(new datum_type##_reference($1)),
        $descriptor(datum_type##_reference*), SWIG_POINTER_OWN);
}
%enddef // METADATUM_WRAPPERS
