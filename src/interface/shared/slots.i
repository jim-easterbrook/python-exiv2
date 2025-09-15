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


// Macro to add mp_ass_subscript slot and functions
%define MP_ASS_SUBSCRIPT(type, item_type, setfunc, delfunc)
// Use %inline so SWIG generates wrappers with type conversions.
// Names start with '_' so it's invisible in normal use.
%noexception __setitem__%mangle(type);
%noexception __delitem__%mangle(type);
%inline %{
static PyObject* __setitem__%mangle(type)(
        type* self, char* key, item_type value, PyObject* py_self) {
    setfunc;
    return SWIG_Py_Void();
};
static PyObject* __delitem__%mangle(type)(
        type* self, char* key, PyObject* py_self) {
    delfunc;
    return SWIG_Py_Void();
};
%}
%fragment("__setitem__"{type}, "header") {
extern "C" {
static PyObject* _wrap___setitem__%mangle(type)(PyObject*, PyObject*);
static PyObject* _wrap___delitem__%mangle(type)(PyObject*, PyObject*);
}
static int __setitem__%mangle(type)_closure(
        PyObject* self, PyObject* key, PyObject* value) {
    PyObject* args;
    PyObject* result;
    if (value) {
        args = Py_BuildValue("(OOO)", self, key, value);
        result = _wrap___setitem__%mangle(type)(self, args);
    } else {
        args = Py_BuildValue("(OO)", self, key);
        result = _wrap___delitem__%mangle(type)(self, args);
    }
    Py_DECREF(args);
    if (!result)
        return -1;
    Py_DECREF(result);
    return 0;
};
}
%fragment("__setitem__"{type});
%feature("python:mp_ass_subscript") type QUOTE(__setitem__%mangle(type)_closure);
%enddef // MP_ASS_SUBSCRIPT


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
static PyObject* __getitem__%mangle(type)_closure(
        PyObject* self, PyObject* key) {
    PyObject* args = Py_BuildValue("(OO)", self, key);
    PyObject* result = _wrap___getitem__%mangle(type)(self, args);
    Py_DECREF(args);
    return result;
};
}
%fragment("__getitem__"{type});
%feature("python:mp_subscript") type QUOTE(__getitem__%mangle(type)_closure);
%enddef // SQ_ITEM


// Macro to add sq_ass_item slot and functions
%define SQ_ASS_ITEM(type, item_type, setfunc, delfunc)
// Use %inline so SWIG generates wrappers with type conversions.
// Names start with '_' so it's invisible in normal use.
%noexception __setitem__%mangle(type);
%noexception __delitem__%mangle(type);
%inline %{
static PyObject* __setitem__%mangle(type)(
        type* self, size_t idx, item_type value, PyObject* py_self) {
    setfunc;
    return SWIG_Py_Void();
};
static PyObject* __delitem__%mangle(type)(
        type* self, size_t idx, PyObject* py_self) {
    delfunc;
    return SWIG_Py_Void();
};
%}
%fragment("__setitem__"{type}, "header") {
extern "C" {
static PyObject* _wrap___setitem__%mangle(type)(PyObject*, PyObject*);
static PyObject* _wrap___delitem__%mangle(type)(PyObject*, PyObject*);
}
static int __setitem__%mangle(type)_closure(
        PyObject* self, Py_ssize_t idx, PyObject* value) {
    PyObject* args;
    PyObject* result;
    if (value) {
        args = Py_BuildValue("(OnO)", self, idx, value);
        result = _wrap___setitem__%mangle(type)(self, args);
    } else {
        args = Py_BuildValue("(On)", self, idx);
        result = _wrap___delitem__%mangle(type)(self, args);
    }
    Py_DECREF(args);
    if (!result)
        return -1;
    Py_DECREF(result);
    return 0;
};
}
%fragment("__setitem__"{type});
%feature("python:sq_ass_item") type QUOTE(__setitem__%mangle(type)_closure);
%enddef // SQ_ASS_ITEM


// Macro to add sq_contains slot and function
%define SQ_CONTAINS(type, func)
%fragment("__contains__"{type}, "header") {
static int __contains__%mangle(type)(PyObject* py_self, PyObject* py_key) {
    type* self = NULL;
    SWIG_ConvertPtr(py_self, (void**)&self, $descriptor(type*), 0);
    const char* key = PyUnicode_AsUTF8(py_key);
    if (!key)
        return -1;
    return func ? 1 : 0;
};
}
%fragment("__contains__"{type});
%feature("python:sq_contains") type QUOTE(__contains__%mangle(type));
%enddef // SQ_CONTAINS


// Macro to add sq_length slot and function
%define SQ_LENGTH(type, func)
%fragment("__len__"{type}, "header") {
static Py_ssize_t __len__%mangle(type)(PyObject* py_self) {
    type* self = NULL;
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
static PyObject* __getitem__%mangle(type)_closure(
        PyObject* self, Py_ssize_t idx) {
    PyObject* args = Py_BuildValue("(On)", self, idx);
    PyObject* result = _wrap___getitem__%mangle(type)(self, args);
    Py_DECREF(args);
    return result;
};
}
%fragment("__getitem__"{type});
%feature("python:sq_item") type QUOTE(__getitem__%mangle(type)_closure);
%enddef // SQ_ITEM


// Macro to add tp_str slot and function
%define TP_STR(type, func)
%fragment("__str__"{type}, "header") {
static PyObject* __str__%mangle(type)(PyObject* py_self) {
    type* self = NULL;
    SWIG_ConvertPtr(py_self, (void**)&self, $descriptor(type*), 0);
    std::string result = func;
    return SWIG_FromCharPtrAndSize(result.data(), result.size());
};
}
%fragment("__str__"{type});
%feature("python:tp_str") type QUOTE(__str__%mangle(type));
%enddef // TP_STR
