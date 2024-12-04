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


// Macro to convert pointer to static list to a Python list of objects
%define LIST_POINTER(pattern, item_type, valid_test)
%fragment("pointer_to_list"{item_type}, "header") {
static PyObject* pointer_to_list(item_type* ptr) {
    PyObject* list = PyList_New(0);
    if (!ptr)
        return list;
    PyObject* py_tmp = NULL;
    while (ptr->valid_test) {
        py_tmp = SWIG_Python_NewPointerObj(
            NULL, ptr, $descriptor(item_type*), 0);
        PyList_Append(list, py_tmp);
        Py_DECREF(py_tmp);
        ++ptr;
    }
    return list;
};
}
%typemap(out, fragment="pointer_to_list"{item_type}) pattern {
    PyObject* list = pointer_to_list($1);
    if (!list)
        SWIG_fail;
    $result = SWIG_AppendOutput($result, list);
}
%enddef // LIST_POINTER
