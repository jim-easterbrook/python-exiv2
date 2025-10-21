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
%include "shared/slots.i"


// Macro to wrap metadatum iterators and pointers
%define METADATUM_WRAPPERS(container_type, datum_type)

// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(Exiv2::datum_type&)
// Keep a reference to data being iterated
KEEP_REFERENCE(Exiv2::container_type::iterator)
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(container_type##_iterator*)

// Invalidate pointers when data is deleted
POINTER_STORE(container_type, datum_type)

%feature("docstring") MetadatumPointer<Exiv2::datum_type>
"Base class for pointers to :class:`"#datum_type"` objects.

:class:`"#container_type"_iterator` objects and :class:`"#datum_type"_reference`
objects both store references to an :class:`"#datum_type"`. This base class
gives them access to most of the ``"#datum_type"`` methods.
``"#datum_type"_pointer`` objects can be used anywhere an ``"#datum_type"`` object
is expected."

%feature("docstring") MetadatumPointer<Exiv2::datum_type>::operator-> "
Return the :class:`"#datum_type"` object being pointed to."

%feature("docstring") MetadataIterator<
    Exiv2::container_type::iterator, Exiv2::datum_type>
"Python wrapper for an :class:`" #container_type "` iterator."

%feature("docstring") MetadatumReference<Exiv2::datum_type>
"Python wrapper for an :class:`" #datum_type "` reference."

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
// Detect end of iteration
%typemap(out) Exiv2::datum_type* __next__ {
    if (!$1) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
    $typemap(out, Exiv2::datum_type*)
}

%template(datum_type ## _pointer) MetadatumPointer<Exiv2::datum_type>;
%template(container_type ## _iterator) MetadataIterator<
    Exiv2::container_type::iterator, Exiv2::datum_type>;
%template(datum_type ## _reference) MetadatumReference<Exiv2::datum_type>;

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
