// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Macros to make enums more Pythonic

// Import exiv2 package
%fragment("_import_exiv2_decl", "header") {
static PyObject* exiv2_module = NULL;
}
%fragment("import_exiv2", "init", fragment="_import_exiv2_decl") {
{
    exiv2_module = PyImport_ImportModule("exiv2");
    if (!exiv2_module)
        return NULL;
}
}

%define _ENUM_COMMON(pattern)
// static variable to hold Python enum object
%fragment("_declare_enum_object"{pattern}, "header") {
static PyObject* PyEnum_%mangle(pattern) = NULL;
}

// Function to initialise Python enum
%fragment("_create_enum_object"{pattern}, "header",
          fragment="_import_py_enum",
          fragment="_declare_enum_object"{pattern}) {
static PyObject* _create_enum_%mangle(pattern)(
        const char* name, const char* doc, PyObject* enum_list) {
    if (!enum_list)
        return NULL;
    PyEnum_%mangle(pattern) = PyObject_CallFunction(
            Py_IntEnum, "sN", name, enum_list);
    if (!PyEnum_%mangle(pattern))
        return NULL;
    if (PyObject_SetAttrString(PyEnum_%mangle(pattern), "__doc__",
            PyUnicode_FromString(doc)))
        return NULL;
    std::string mod_name = "exiv2.";
    mod_name += SWIG_name + 1;
    if (PyObject_SetAttrString(PyEnum_%mangle(pattern), "__module__",
            PyUnicode_FromString(mod_name.c_str())))
        return NULL;
    // SWIG_Python_SetConstant will decref PyEnum object
    Py_INCREF(PyEnum_%mangle(pattern));
    return PyEnum_%mangle(pattern);
};
}

// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="_import_py_enum") pattern {
    $1 = PyObject_IsInstance($input, Py_IntEnum);
}

// deprecate passing integers where an enum is expected
%typemap(in, fragment="get_enum_typeobject"{pattern}) pattern {
    if (!PyObject_IsInstance($input,
                             get_enum_typeobject_%mangle(pattern)())) {
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

%fragment("py_from_enum_ex"{pattern}, "header",
          fragment="get_enum_typeobject"{pattern}) {
static PyObject* py_from_enum_%mangle(pattern)(long value) {
    PyObject* py_int = PyLong_FromLong(value);
    if (!py_int)
        return NULL;
    PyObject* result = PyObject_CallFunctionObjArgs(
        get_enum_typeobject_%mangle(pattern)(), py_int, NULL);
    if (!result) {
        // Assume value is not currently in enum, so return int
        PyErr_Clear();
        return py_int;
        }
    Py_DECREF(py_int);
    return result;
};
}
%fragment("py_from_enum"{pattern}, "header",
          fragment="py_from_enum_ex"{pattern}) {
static PyObject* py_from_enum(pattern value) {
    return py_from_enum_%mangle(pattern)(static_cast<long>(value));
};
}
%typemap(out, fragment="py_from_enum_ex"{pattern}) pattern {
    $result = py_from_enum_%mangle(pattern)(static_cast<long>($1));
    if (!$result)
        SWIG_fail;
}
%enddef // _ENUM_COMMON

// Function to return enum members as Python list
%fragment("get_enum_list", "header") {
#include <cstdarg>
static PyObject* _get_enum_list(int dummy, ...) {
    va_list args;
    va_start(args, dummy);
    char* label;
    PyObject* py_obj = NULL;
    PyObject* result = PyList_New(0);
    label = va_arg(args, char*);
    while (label) {
        py_obj = Py_BuildValue("(si)", label, va_arg(args, int));
        PyList_Append(result, py_obj);
        Py_DECREF(py_obj);
        label = va_arg(args, char*);
    }
    va_end(args);
    return result;
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
        return NULL;
    Py_IntEnum = PyObject_GetAttrString(module, "IntEnum");
    Py_DECREF(module);
    if (!Py_IntEnum)
        return NULL;
}
}

%define IMPORT_ENUM(name)
_ENUM_COMMON(Exiv2::name);
%typemap(doctype) Exiv2::name ":py:class:`" #name "`"
// fragment to get enum object
%fragment("get_enum_typeobject"{Exiv2::name}, "header",
          fragment="import_exiv2",
          fragment="_declare_enum_object"{Exiv2::name}) {
static PyObject* get_enum_typeobject_%mangle(Exiv2::name)() {
    if (!PyEnum_%mangle(Exiv2::name))
        PyEnum_%mangle(Exiv2::name) = PyObject_GetAttrString(
            exiv2_module, "name");
    return PyEnum_%mangle(Exiv2::name);
};
}
%enddef // IMPORT_ENUM

%define DEFINE_ENUM(name, doc, contents...)
IMPORT_ENUM(name)
// Add enum to module during init
%fragment("_create_enum_object"{Exiv2::name});
%fragment("get_enum_list");
%constant PyObject* name = _create_enum_%mangle(Exiv2::name)(
    "name", doc, _get_enum_list(0, contents, NULL));
%ignore Exiv2::name;
%enddef // DEFINE_ENUM

%define DEPRECATED_ENUM(moved_to, enum_name, doc, contents...)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="_import_py_enum") Exiv2::moved_to::enum_name {
    $1 = PyObject_IsInstance($input, Py_IntEnum);
}

%fragment("get_enum_list");
%noexception _enum_list_##enum_name;
%inline %{
PyObject* _enum_list_##enum_name() {
    return _get_enum_list(0, contents, NULL);
};
%}
%pythoncode %{
import enum

class enum_name##Meta(enum.EnumMeta):
    def __getattribute__(cls, name):
        obj = super().__getattribute__(name)
        if isinstance(obj, enum.Enum):
            import warnings
            warnings.warn(
                "Use 'moved_to.enum_name' instead of 'enum_name'",
                DeprecationWarning)
        return obj

class Deprecated##enum_name(enum.IntEnum, metaclass=enum_name##Meta):
    pass

enum_name = Deprecated##enum_name('enum_name', _enum_list_##enum_name())
enum_name.__doc__ = doc
%}
%ignore Exiv2::enum_name;
%enddef // DEPRECATED_ENUM

%define IMPORT_CLASS_ENUM(klass, name)
_ENUM_COMMON(Exiv2::klass::name);
%typemap(doctype) Exiv2::klass::name ":py:class:`" #klass "." #name "`"
// fragment to get enum object
%fragment("get_enum_typeobject"{Exiv2::klass::name}, "header",
          fragment="import_exiv2",
          fragment="_declare_enum_object"{Exiv2::klass::name}) {
static PyObject* get_enum_typeobject_%mangle(Exiv2::klass::name)() {
    if (!PyEnum_%mangle(Exiv2::klass::name)) {
        PyObject* parent_class = PyObject_GetAttrString(
            exiv2_module, "klass");
        if (parent_class) {
            PyEnum_%mangle(Exiv2::klass::name) = PyObject_GetAttrString(
                parent_class, "name");
            Py_DECREF(parent_class);
        }
    }
    return PyEnum_%mangle(Exiv2::klass::name);
};
}
%enddef // IMPORT_CLASS_ENUM

%define DEFINE_CLASS_ENUM(class, name, doc, contents...)
IMPORT_CLASS_ENUM(class, name)
// Add enum as static class member during module init
%extend Exiv2::class {
%fragment("_create_enum_object"{Exiv2::class::name});
%fragment("get_enum_list");
%constant PyObject* name = _create_enum_%mangle(Exiv2::class::name)(
    "name", doc, _get_enum_list(0, contents, NULL));
}
%ignore Exiv2::class::name;
%enddef // DEFINE_CLASS_ENUM
