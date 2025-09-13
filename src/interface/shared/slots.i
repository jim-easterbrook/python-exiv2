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


// Macro to add mp_subscript slot and functions
%define MP_SUBSCRIPT(type, item_type, func)
// Use %inline so SWIG generates a wrapper with type conversions.
// Name starts with '_' so it's invisible in normal use.
%noexception __getitem__%mangle(type);
%inline %{
static item_type __getitem__%mangle(type)(type* self, char* key) {
    return func;
};
%}
%fragment("__getitem__"{type}, "header") {
extern "C" {
static PyObject* _wrap___getitem__%mangle(type)(PyObject*, PyObject*);
}
static PyObject* __getitem__%mangle(type)(PyObject* self,
                                          PyObject* key) {
    PyObject* args = Py_BuildValue("(OO)", self, key);
    PyObject* result = _wrap___getitem__%mangle(type)(self, args);
    Py_DECREF(args);
    return result;
};
}
%fragment("__getitem__"{type});
%feature("python:mp_subscript") type QUOTE(__getitem__%mangle(type));
%enddef // SQ_ITEM


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


// Macro to add sq_item slot and functions
%define SQ_ITEM(type, item_type, func)
// Use %inline so SWIG generates a wrapper with type conversions.
// Name starts with '_' so it's invisible in normal use.
%noexception __getitem__%mangle(type);
%inline %{
static item_type __getitem__%mangle(type)(type* self, size_t idx) {
    return func;
};
%}
%fragment("__getitem__"{type}, "header") {
extern "C" {
static PyObject* _wrap___getitem__%mangle(type)(PyObject*, PyObject*);
}
static PyObject* __getitem__%mangle(type)(PyObject* self,
                                          Py_ssize_t idx) {
    PyObject* args = Py_BuildValue("(On)", self, idx);
    PyObject* result = _wrap___getitem__%mangle(type)(self, args);
    Py_DECREF(args);
    return result;
};
}
%fragment("__getitem__"{type});
%feature("python:sq_item") type QUOTE(__getitem__%mangle(type));
%enddef // SQ_ITEM


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
