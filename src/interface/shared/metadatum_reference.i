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


// Macro to wrap metadatum references so they can be invalidated
%define METADATUM_REFERENCE(datum_type)
%feature("python:slot", "tp_str", functype="reprfunc")
    datum_type##_pointer::__str__;
%noexception datum_type##_pointer::operator==;
%noexception datum_type##_pointer::operator!=;
%noexception Exiv2::datum_type::operator==;
%noexception Exiv2::datum_type::operator!=;
%ignore datum_type##_pointer::##datum_type##_pointer;
%ignore datum_type##_pointer::size;
%ignore datum_type##_pointer::operator*;
%ignore datum_type##_pointer::_invalidate;
%feature("docstring") datum_type##_pointer "
Python wrapper for an :class:`" #datum_type "` reference. It has most of
the methods of :class:`" #datum_type "` allowing easy access to the
data it points to."
%inline %{
class datum_type##_pointer {
private:
    Exiv2::datum_type* ptr;
    bool invalidated;
public:
    datum_type##_pointer(Exiv2::datum_type* ptr) {
        this->ptr = ptr;
        invalidated = false;
    }
    // Dereference operator gives Python access to all datum methods
    Exiv2::datum_type* operator->() const {
        if (invalidated)
            throw std::runtime_error("datum_type pointer is invalid");
        return ptr;
    }
    Exiv2::datum_type* operator*() const { return ptr; }
    bool operator==(const Exiv2::datum_type &other) const {
        return &other == ptr;
    }
    bool operator!=(const Exiv2::datum_type &other) const {
        return &other != ptr;
    }
    std::string __str__() {
        if (invalidated)
            return "invalid pointer";
        return "pointer<" + ptr->key() + ": " + ptr->print() + ">";
    }
    // Invalidate pointer unilaterally
    void _invalidate() { invalidated = true; }
    // Invalidate pointer if what it points to has been deleted
    bool _invalidate(Exiv2::datum_type* deleted) {
        if (deleted == ptr)
            invalidated = true;
        return invalidated;
    }
    // Provide size() C++ method for buffer size check
    size_t size() {
        if (invalidated)
            return 0;
        return ptr->size();
    }
};
%}
%extend Exiv2::datum_type {
    bool operator==(const Exiv2::datum_type &other) const {
        return &other == self;
    }
    bool operator!=(const Exiv2::datum_type &other) const {
        return &other != self;
    }
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
%typemap(out) Exiv2::datum_type& {
    $result = SWIG_NewPointerObj(
        SWIG_as_voidptr(new datum_type##_pointer($1)),
        $descriptor(datum_type##_pointer*), SWIG_POINTER_OWN);
}
%enddef // METADATUM_REFERENCE
