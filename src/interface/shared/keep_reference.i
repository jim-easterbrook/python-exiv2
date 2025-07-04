// python-exiv2 - Python interface to libexiv2
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


// Functions to store and retrieve "private" data attached to Pyhon object
%fragment("private_data", "header") {
static PyObject* _get_store(PyObject* py_self, bool create) {
    if (!PyObject_HasAttrString(py_self, "_private_data_")) {
        if (!create)
            return NULL;
        PyObject* dict = PyDict_New();
        if (!dict)
            return NULL;
        int error = PyObject_SetAttrString(py_self, "_private_data_", dict);
        Py_DECREF(dict);
        if (error)
            return NULL;
    }
    return PyObject_GetAttrString(py_self, "_private_data_");
};
static int store_private(PyObject* py_self, const char* name,
                         PyObject* val, bool take_ownership=false) {
    int result = 0;
    PyObject* dict = _get_store(py_self, true);
    if (dict) {
        if (val)
            result = PyDict_SetItemString(dict, name, val);
        else if (PyDict_GetItemString(dict, name))
            result = PyDict_DelItemString(dict, name);
        Py_DECREF(dict);
    }
    else
        result = -1;
    if (take_ownership && val)
        Py_DECREF(val);
    return result;
};
static PyObject* fetch_private(PyObject* py_self, const char* name) {
    PyObject* dict = _get_store(py_self, false);
    if (!dict)
        return NULL;
    PyObject* result = PyDict_GetItemString(dict, name);
    if (result) {
        Py_INCREF(result);
        PyDict_DelItemString(dict, name);
    }
    Py_DECREF(dict);
    return result;
};
}

// Macro to keep a reference to any object when returning a particular type.
%define KEEP_REFERENCE_EX(return_type, target)
%typemap(ret, fragment="private_data") return_type %{
    if ($result != Py_None)
        if (store_private($result, "_refers_to", target)) {
            SWIG_fail;
        }
%}
%enddef // KEEP_REFERENCE_EX

// Macro to keep a reference to "self" when returning a particular type.
%define KEEP_REFERENCE(return_type)
KEEP_REFERENCE_EX(return_type, self)
%enddef // KEEP_REFERENCE
