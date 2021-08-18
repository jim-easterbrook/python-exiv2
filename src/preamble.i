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
%import "exiv2/config.h"

// Macro to provide operator[] equivalent
%define GETITEM(class, ret_type)
%feature("python:slot", "mp_subscript", functype="binaryfunc") class::__getitem__;
%extend class {
    ret_type& __getitem__(const std::string& key) {
        return (*($self))[key];
    }
}
%enddef

// Macro to provide a Python iterator over a C++ class with begin/end methods
%define ITERATOR(parent_class, item_type, iter_class)
// Make parent class iterable
%feature("python:slot", "tp_iter", functype="getiterfunc") parent_class::begin;
// Define a simple iterator class
%feature("python:slot", "tp_iternext", functype="iternextfunc") iter_class::next;
%exception iter_class::next {
    try {$action}
    catch (iter_class ## Stop) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
}
%ignore iter_class ## Stop;
%ignore iter_class::ptr;
%inline %{
class iter_class ## Stop {};
class iter_class {
private:
    parent_class::iterator end;
public:
    parent_class::iterator ptr;
    iter_class(parent_class::iterator ptr, parent_class::iterator end) {
        this->ptr = ptr;
        this->end = end;
    }
    const item_type curr() {
        if (this->ptr == this->end)
            throw iter_class ## Stop();
        return *this->ptr;
    }
    const item_type next() {
        if (this->ptr == this->end)
            throw iter_class ## Stop();
        return *(this->ptr++);
    }
    bool operator==(const iter_class &other) const {
        return other.ptr == this->ptr;
    }
    bool operator!=(const iter_class &other) const {
        return other.ptr != this->ptr;
    }
};
%}
// Convert iterator parameters
%typemap(in) parent_class::iterator (int res = 0, void *argp) {
    res = SWIG_ConvertPtr($input, &argp, SWIGTYPE_p_ ## iter_class, 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, int, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref("$type", $symname, $argnum);
    }
    $1 = (reinterpret_cast<iter_class*>(argp))->ptr;
};
// Convert iterator return values (assumes arg1 is set to the parent object)
%typemap(out) parent_class::iterator {
    $result = SWIG_NewPointerObj(
        new iter_class(result, (arg1)->end()),
        SWIGTYPE_p_ ## iter_class, SWIG_POINTER_OWN);
};
%enddef
