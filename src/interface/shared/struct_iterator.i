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


// Macro to make an Exiv2 struct iterable so it can be used in a dict ctor
%define STRUCT_ITERATOR(type, format, contents...)
%feature("python:slot", "tp_iter", functype="getiterfunc") type::__iter__;
%noexception type::__iter__;
%extend type {
    PyObject* __iter__() {
        PyObject* seq = Py_BuildValue(format, contents);
        PyObject* result = PySeqIter_New(seq);
        Py_DECREF(seq);
        return result;
    }
}
%enddef // STRUCT_ITERATOR
