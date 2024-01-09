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
%fragment("import_py_enum", "init", fragment="_declare_py_enum") {
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

%define ENUM(name, doc, contents...)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="import_py_enum") Exiv2::name {
    $1 = PyObject_IsInstance($input, Py_IntEnum);
}

// typemap to convert results
%fragment("py_from_enum"{Exiv2::name}, "header") {
static PyObject* py_from_enum(Exiv2::name value) {
    PyObject* module = PyImport_ImportModule("exiv2");
    PyObject* result = PyObject_CallMethod(module, "name", "(i)", value);
    Py_DECREF(module);
    return result;
};
}
%typemap(out, fragment="py_from_enum"{Exiv2::name}) Exiv2::name {
    $result = py_from_enum($1);
    if (!$result)
        SWIG_fail;
}

// Add enum to module during init
%fragment("get_enum_list");
%fragment("get_enum_object");
%constant PyObject* name =  _get_enum_object(
    "name", doc, _get_enum_list(0, contents, NULL));
%ignore Exiv2::name;
%enddef // ENUM

%define DEPRECATED_ENUM(moved_to, enum_name, doc, contents...)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="import_py_enum") Exiv2::moved_to::enum_name {
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

// Function to generate Python enum
%fragment("get_enum_object", "header", fragment="import_py_enum") {
%#include <cstdarg>
static PyObject* _get_enum_object(const char* name, const char* doc,
                                  PyObject* enum_list) {
    if (!enum_list)
        return NULL;
    PyObject* result = PyObject_CallFunction(Py_IntEnum, "sN",
                                             name, enum_list);
    if (!result)
        return NULL;
    if (PyObject_SetAttrString(result, "__doc__", PyUnicode_FromString(doc)))
        return NULL;
    return result;
};
}

%define CLASS_ENUM(class, name, doc, contents...)
// typemap to disambiguate enum from int
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER,
         fragment="import_py_enum") Exiv2::class::name {
    $1 = PyObject_IsInstance($input, Py_IntEnum);
}

// typemap to convert results
%fragment("py_from_enum"{Exiv2::class::name}, "header") {
static PyObject* py_from_enum(Exiv2::class::name value) {
    swig_type_info* desc = $descriptor(Exiv2::class*);
    SwigPyClientData* cd = (SwigPyClientData*)desc->clientdata;
    return PyObject_CallFunction(
        PyDict_GetItemString(cd->pytype->tp_dict, "name"), "(i)", value);
};
}
%typemap(out, fragment="py_from_enum"{Exiv2::class::name})
        Exiv2::class::name {
    $result = py_from_enum($1);
    if (!$result)
        SWIG_fail;
}

// Add enum to type object during module init
%extend Exiv2::class {
%fragment("get_enum_list");
%fragment("get_enum_object");
%constant PyObject* name =  _get_enum_object(
    "name", doc, _get_enum_list(0, contents, NULL));
}
%ignore Exiv2::class::name;
%enddef // CLASS_ENUM
