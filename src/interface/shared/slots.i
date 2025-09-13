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


// Macro to add sq_length slot and function
%define SQ_LENGTH(type, func)
%fragment("__len__"{type}, "header") {
static Py_ssize_t __len__%mangle(type)(PyObject* py_self) {
    type* self;
    SWIG_ConvertPtr(py_self, (void**)&self, $descriptor(type*), 0);
    return func;
};
}
%fragment("__len__"{type});
%feature("python:sq_length") type QUOTE(__len__%mangle(type));
%enddef // SQ_LENGTH


// Macro to add tp_str slot and function
%define TP_STR(type, func)
%fragment("__str__"{type}, "header") {
static PyObject* __str__%mangle(type)(PyObject* py_self) {
    type* self;
    SWIG_ConvertPtr(py_self, (void**)&self, $descriptor(type*), 0);
    std::string result = func;
    return SWIG_FromCharPtrAndSize(result.data(), result.size());
};
}
%fragment("__str__"{type});
%feature("python:tp_str") type QUOTE(__str__%mangle(type));
%enddef // TP_STR
