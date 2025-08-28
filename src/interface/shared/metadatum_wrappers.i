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


%include "shared/keep_reference.i"
%include "shared/pointer_store.i"


// Macro to declare metadatum iterators and pointer wrappers
%define DECLARE_METADATUM_WRAPPERS(container_type, datum_type)
%{
class datum_type##_pointer;
class container_type##_iterator;
class datum_type##_reference;
%}
%enddef // DECLARE_METADATUM_WRAPPERS

// Macro to wrap metadatum iterators and pointers
%define METADATUM_WRAPPERS(container_type, datum_type)

// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(Exiv2::datum_type&)

// Invalidate pointers when data is deleted
POINTER_STORE(container_type, datum_type)

// Base class of pointer wrappers
%feature("python:slot", "tp_str", functype="reprfunc")
    datum_type##_pointer::__str__;
%ignore datum_type##_pointer::datum_type##_pointer;
%ignore datum_type##_pointer::~datum_type##_pointer;
%ignore datum_type##_pointer::operator*;
%ignore datum_type##_pointer::size;
%ignore datum_type##_pointer::_invalidate;
%fragment("metadatum_str");
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
            return name + "<deleted data>";
        Exiv2::datum_type* ptr = **this;
        if (!ptr)
            return name + "<data end>";
        return name + "<" + metadatum_str(ptr) + ">";
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
    // Invalidate iterator if what it points to has been deleted
    bool _invalidate(Exiv2::datum_type& deleted) {
        if (&deleted == **this)
            invalidated = true;
        return invalidated;
    }
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
%ignore container_type##_iterator::_invalidated;
%ignore container_type##_iterator::_ptr;
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
// Keep a reference to the data being iterated
KEEP_REFERENCE(Exiv2::container_type::iterator)
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(container_type##_iterator*)
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
    // Direct access to ptr and invalidated, for use in input typemaps
    bool _invalidated() const { return invalidated; }
    Exiv2::container_type::iterator _ptr() const { return ptr; }
};
%}

// Metadata reference wrapper
%ignore datum_type##_reference::##datum_type##_reference;
%ignore datum_type##_reference::operator*;
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
};
%}

// typemaps
%typemap(in) Exiv2::container_type::iterator
        (container_type##_iterator *argp=NULL) %{
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    if (argp->_invalidated()) {
        SWIG_exception_fail(SWIG_ValueError,
            "in method '$symname', argument $argnum points to deleted data");
    }
    $1 = argp->_ptr();
%}
%typemap(in) Exiv2::container_type::iterator&
        (Exiv2::container_type::iterator it,
         container_type##_iterator* argp = NULL) {
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    if (argp->_invalidated()) {
        SWIG_exception_fail(SWIG_ValueError,
            "in method '$symname', argument $argnum points to deleted data");
    }
    it = argp->_ptr();
    $1 = &it;
}
%typemap(in) const Exiv2::datum_type& {
    datum_type##_pointer* tmp = NULL;
    if (SWIG_IsOK(SWIG_ConvertPtr(
            $input, (void**)&tmp, $descriptor(datum_type##_pointer*), 0)))
        $1 = **tmp;
    else {
        $typemap(in, Exiv2::datum_type&)
    }
}
%typemap(out) Exiv2::container_type::iterator {
    $result = SWIG_NewPointerObj(
        SWIG_as_voidptr(new container_type##_iterator($1, arg1->end())),
        $descriptor(container_type##_iterator*), SWIG_POINTER_OWN);
#if SWIG_VERSION >= 0x040400
    // Keep weak reference to the Python iterator
    if (store_pointer(self, $result)) {
        SWIG_fail;
    }
#endif // SWIG_VERSION
}
%typemap(out) Exiv2::datum_type& {
    $result = SWIG_NewPointerObj(
        SWIG_as_voidptr(new datum_type##_reference($1)),
        $descriptor(datum_type##_reference*), SWIG_POINTER_OWN);
#if SWIG_VERSION >= 0x040400
    // Keep weak reference to the Python result
    if (store_pointer(self, $result)) {
        SWIG_fail;
    }
#endif // SWIG_VERSION
}

// Deprecate some methods since 2025-08-25
DEPRECATE_FUNCTION(Exiv2::datum_type::copy, true)
DEPRECATE_FUNCTION(Exiv2::datum_type::write, true)
// Ignore overloaded default parameter version
%ignore Exiv2::datum_type::write(std::ostream &) const;

// Extend datum type
%extend Exiv2::datum_type {
    bool operator==(const Exiv2::datum_type &other) const {
        return &other == self;
    }
    bool operator!=(const Exiv2::datum_type &other) const {
        return &other != self;
    }
    // Extend Metadatum to allow getting value as a specific type.
    Exiv2::Value::SMART_PTR getValue(Exiv2::TypeId as_type) {
        // deprecated since 2023-12-07
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        // deprecated since 2023-12-07
        PyErr_WarnEx(PyExc_DeprecationWarning, "Requested type ignored.", 1);
        return $self->value();
    }
    // Old _print method for compatibility
    std::string _print(const Exiv2::ExifData* pMetadata) const {
        // deprecated since 2024-01-29
        PyErr_WarnEx(PyExc_DeprecationWarning,
                     "'_print' has been replaced by 'print'", 1);
        return $self->print(pMetadata);
    }
    // toString parameter does not default to 0, so bypass default typemap
    std::string toString() const { return self->toString(); }
    std::string toString(BUFLEN_T i) const { return self->toString(i); }
}

%enddef // METADATUM_WRAPPERS
