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


// Macros to make enums more Pythonic
// Function to return enum members as Python list
%fragment("enum_helper", "header") {
#include <cstdarg>
static PyObject* _get_enum_list(int dummy, ...) {
    va_list args;
    va_start(args, dummy);
    char* label;
    int value;
    PyObject* result = PyList_New(0);
    label = va_arg(args, char*);
    while (label) {
        value = va_arg(args, int);
        PyList_Append(result, PyTuple_Pack(2,
            PyUnicode_FromString(label), PyLong_FromLong(value)));
        label = va_arg(args, char*);
    }
    va_end(args);
    return result;
};
}
%define ENUM(name, doc, contents...)
%fragment("enum_helper");
%noexception _enum_list_##name;
%inline %{
PyObject* _enum_list_##name() {
    return _get_enum_list(0, contents, NULL);
};
%}
%pythoncode %{
import enum
name = enum.IntEnum('name', _enum_list_##name())
name.__doc__ = doc
%}
%ignore Exiv2::name;
%enddef // ENUM

%define DEPRECATED_ENUM(moved_to, enum_name, doc, contents...)
%fragment("enum_helper");
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
%fragment("class_enum_helper", "header") {
#include <cstdarg>
static PyObject* _get_enum_object(const char* name, ...) {
    va_list args;
    va_start(args, name);
    char* label;
    int value;
    PyObject* module = NULL;
    PyObject* IntEnum = NULL;
    PyObject* result = NULL;
    PyObject* data = PyList_New(0);
    label = va_arg(args, char*);
    while (label) {
        value = va_arg(args, int);
        if (PyList_Append(data, PyTuple_Pack(2,
                PyUnicode_FromString(label), PyLong_FromLong(value))))
            goto fail;
        label = va_arg(args, char*);
    }
    va_end(args);
    module = PyImport_ImportModule("enum");
    if (!module)
        goto fail;
    IntEnum = PyObject_GetAttrString(module, "IntEnum");
    if (!IntEnum)
        goto fail;
    result = PyObject_CallFunction(IntEnum, "sO", name, data);
fail:
    Py_XDECREF(module);
    Py_XDECREF(IntEnum);
    Py_XDECREF(data);
    return result;
};
}
%define CLASS_ENUM(class, name, doc, contents...)
%fragment("class_enum_helper");
// Add enum to type object during module init
%init %{
{
    PyObject* enum_obj = _get_enum_object("name", contents, NULL);
    if (!enum_obj)
        return NULL;
    if (PyObject_SetAttrString(
            enum_obj, "__doc__", PyUnicode_FromString(doc)))
        return NULL;
    PyTypeObject* type =
        (PyTypeObject *)&SwigPyBuiltin__Exiv2__##class##_type;
    SWIG_Python_SetConstant(type->tp_dict, NULL, "name", enum_obj);
    PyType_Modified(type);
}
%}
%enddef // CLASS_ENUM
