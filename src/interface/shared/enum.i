// // python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Import directory depends on exiv2 version being swigged
%include "enum_members.i"

%include "shared/python_import.i"


// Macros to make enums more Pythonic

// Import exiv2 package
%fragment("_import_exiv2_decl", "header") {
static PyObject* exiv2_module = NULL;
}
%fragment("import_exiv2", "init", fragment="_import_exiv2_decl") {
{
    exiv2_module = PyImport_ImportModule("exiv2");
    if (!exiv2_module)
        return INIT_ERROR_RETURN;
}
}

%define _ENUM_COMMON(pattern)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="_import_py_enum") pattern {
    $1 = PyObject_IsInstance($input, Py_IntEnum);
}

// deprecate passing integers where an enum is expected
%typemap(in, fragment="declare_import"{pattern}) pattern {
    if (!PyObject_IsInstance($input, Python_%mangle(pattern))) {
        // deprecated since 2024-01-09
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "$symname argument $argnum type should be 'pattern'.", 1);
    }
    if (!PyLong_Check($input)) {
        %argument_fail(
            SWIG_TypeError, "pattern", $symname, $argnum);
    }
    $1 = static_cast< $1_type >(PyLong_AsLong($input));
}

%fragment("py_from_enum", "header") {
static PyObject* py_from_enum(PyObject* enum_typeobject, long value) {
    PyObject* py_int = PyLong_FromLong(value);
    if (!py_int)
        return NULL;
    PyObject* result = PyObject_CallFunctionObjArgs(
        enum_typeobject, py_int, NULL);
    if (!result) {
        // Assume value is not currently in enum, so return int
        PyErr_Clear();
        return py_int;
        }
    Py_DECREF(py_int);
    return result;
};
}
%typemap(out, fragment="py_from_enum",
         fragment="declare_import"{pattern}) pattern {
    $result = py_from_enum(Python_%mangle(pattern), static_cast<long>($1));
    if (!$result)
        SWIG_fail;
}
%enddef // _ENUM_COMMON

// Import exiv2.extras module
%fragment("_extras_decl", "header") {
static PyObject* exiv2_extras = NULL;
}
%fragment("import_extras", "init", fragment="_extras_decl") {
exiv2_extras = PyImport_ImportModule("exiv2.extras");
if (!exiv2_extras)
    return INIT_ERROR_RETURN;
}

// Call Python function to get enum
%fragment("_get_enum_data", "header", fragment="import_extras") {
#include <cstdarg>

// Convert enum names & values to a Python list
static PyObject* _get_enum_data(const char* name, ...) {
    PyObject* py_obj = NULL;
    PyObject* members = PyList_New(0);
    va_list args;
    va_start(args, name);
    char* label = va_arg(args, char*);
    while (label) {
        py_obj = Py_BuildValue("(si)", label, va_arg(args, int));
        PyList_Append(members, py_obj);
        Py_DECREF(py_obj);
        label = va_arg(args, char*);
    }
    va_end(args);
    return members;
};
// Call Python to create an enum from list of names & values
static PyObject* _create_enum(const char* name, const char* alias_strip,
                              PyObject* members) {
    return PyObject_CallMethod(exiv2_extras, "_create_enum", "(sssN)",
                               SWIG_name, name, alias_strip, members);
};
}

// Import Python enum.IntEnum
%fragment("_declare_py_enum", "header") {
static PyObject* Py_IntEnum = NULL;
}
%fragment("_import_py_enum", "init", fragment="_declare_py_enum") {
{
    PyObject* module = PyImport_ImportModule("enum");
    if (!module)
        return INIT_ERROR_RETURN;
    Py_IntEnum = PyObject_GetAttrString(module, "IntEnum");
    Py_DECREF(module);
    if (!Py_IntEnum) {
        PyErr_SetString(PyExc_RuntimeError, "Import error: enum.IntEnum.");
        return INIT_ERROR_RETURN;
    }
}
}

%define IMPORT_ENUM(module, name)
%typemap(doctype) Exiv2::name ":py:class:`" #name "`"
_ENUM_COMMON(Exiv2::name)
IMPORT_MODULE_OBJECT(module, name)
%enddef // IMPORT_ENUM

%define _GET_ENUM_FROM_DATA(full_name, alias_strip)
%fragment("_store_enum_object"{full_name}, "init",
          fragment="declare_import"{full_name},
          fragment="_get_enum_data"{full_name}) {
Python_%mangle(full_name) = _create_enum(
    #full_name, #alias_strip, _get_enum_data_%mangle(full_name)());
if (!Python_%mangle(full_name))
    return INIT_ERROR_RETURN;
// SWIG_Python_SetConstant will decref PyEnum object
Py_INCREF(Python_%mangle(full_name));
}
%fragment("_store_enum_object"{full_name});
%enddef // _GET_ENUM_FROM_DATA

%define DEFINE_ENUM(name, alias_strip)
%typemap(doctype) Exiv2::name ":py:class:`" #name "`"
_ENUM_COMMON(Exiv2::name)
DECLARE_IMPORT(Exiv2::name)
_GET_ENUM_FROM_DATA(Exiv2::name, alias_strip)
// Add enum to module during init
%constant PyObject* name = Python_%mangle(Exiv2::name);
%ignore Exiv2::name;
%enddef // DEFINE_ENUM


%define DEPRECATED_ENUM(moved_to, name)
%pythoncode %{
from exiv2.extras import _deprecated_enum

name = _deprecated_enum(#moved_to, moved_to.name)
%}
%enddef // DEPRECATED_ENUM


%define DEFINE_CLASS_ENUM(class, name, alias_strip)
%typemap(doctype) Exiv2::class::name ":py:class:`" #class "." #name "`"
_ENUM_COMMON(Exiv2::class::name)
DECLARE_IMPORT(Exiv2::class::name)
_GET_ENUM_FROM_DATA(Exiv2::class::name, alias_strip)
// Add enum as static class member during module init
%extend Exiv2::class {
%constant PyObject* name = Python_%mangle(Exiv2::class::name);
}
%ignore Exiv2::class::name;
%enddef // DEFINE_CLASS_ENUM
