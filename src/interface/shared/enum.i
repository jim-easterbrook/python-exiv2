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


%fragment("py_from_enum", "header") {
static PyObject* py_from_enum(PyObject* enum_typeobject, long value) {
    PyObject* py_int = PyLong_FromLong(value);
    if (!py_int)
        return NULL;
    PyObject* result = PyObject_CallFunctionObjArgs(
        enum_typeobject, py_int, NULL);
    if (!result && PyErr_ExceptionMatches(PyExc_ValueError)) {
        // Assume value is not currently in enum, so return int
        PyErr_Clear();
        return py_int;
    }
    Py_DECREF(py_int);
    return result;
};
}

%define _ENUM_COMMON(pattern)
DECLARE_IMPORT(pattern)
IMPORT_PYTHON_OBJECT(enum, IntEnum, enum::IntEnum)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="import_python_object"{enum::IntEnum}) pattern {
    $1 = PyObject_IsInstance($input, Python_enum_IntEnum);
}

// deprecate passing integers where an enum is expected
%typemap(in, fragment="import_enum"{pattern}) pattern {
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

%typemap(out, fragment="py_from_enum",
         fragment="import_enum"{pattern}) pattern {
    $result = py_from_enum(Python_%mangle(pattern), static_cast<long>($1));
    if (!$result)
        SWIG_fail;
}
%enddef // _ENUM_COMMON

// Call Python function to get enum
IMPORT_PYTHON_OBJECT(exiv2.extras, _create_enum, Exiv2::extras::create_enum)
%fragment("_get_enum_data", "header",
          fragment="import_python_object"{Exiv2::extras::create_enum}) {
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
    return PyObject_CallFunction(
        Python_%mangle(Exiv2::extras::create_enum), "(sssN)",
        SWIG_name, name, alias_strip, members);
};
}

%define IMPORT_ENUM(module, name)
%typemap(doctype) Exiv2::name ":py:class:`" #name "`"
_ENUM_COMMON(Exiv2::name)
IMPORT_MODULE_OBJECT(module, name)
%fragment("import_enum"{Exiv2::name}, "init",
          fragment="import_module_object"{Exiv2::name}) {}
%enddef // IMPORT_ENUM

%define _GET_ENUM_FROM_DATA(full_name, alias_strip)
DECLARE_IMPORT(full_name)
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
_GET_ENUM_FROM_DATA(Exiv2::name, alias_strip)
// Add enum to module during init
%constant PyObject* name = Python_%mangle(Exiv2::name);
%ignore Exiv2::name;
%fragment("import_enum"{Exiv2::name}, "init") {}
%enddef // DEFINE_ENUM


%define DEPRECATED_ENUM(moved_to, name)
%pythoncode %{
from exiv2.extras import _deprecated_enum

name = _deprecated_enum(#moved_to, moved_to.name)
%}
%enddef // DEPRECATED_ENUM


%define IMPORT_CLASS_ENUM(module, class, name)
%typemap(doctype) Exiv2::class::name ":py:class:`" #class "." #name "`"
_ENUM_COMMON(Exiv2::class::name)
IMPORT_CLASS_OBJECT(module, class, name)
%fragment("import_enum"{Exiv2::class::name}, "init",
          fragment="import_class_object"{Exiv2::class::name}) {}
%enddef // IMPORT_CLASS_ENUM


%define DEFINE_CLASS_ENUM(class, name, alias_strip)
%typemap(doctype) Exiv2::class::name ":py:class:`" #class "." #name "`"
_ENUM_COMMON(Exiv2::class::name)
_GET_ENUM_FROM_DATA(Exiv2::class::name, alias_strip)
// Add enum as static class member during module init
%extend Exiv2::class {
%constant PyObject* name = Python_%mangle(Exiv2::class::name);
}
%ignore Exiv2::class::name;
%fragment("import_enum"{Exiv2::class::name}, "init") {}
%enddef // DEFINE_CLASS_ENUM
