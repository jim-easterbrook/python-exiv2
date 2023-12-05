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


// Macro to convert pointer to start of static list to a Python tuple
%define LIST_POINTER(pattern, item_type, valid_test)
%typemap(out) pattern {
    const item_type* item = $1;
    PyObject* py_item = NULL;
    PyObject* list = PyList_New(0);
    while (item->valid_test) {
        py_item = SWIG_NewPointerObj(
            SWIG_as_voidptr(item), $descriptor(item_type*), 0);
        PyList_Append(list, py_item);
        Py_DECREF(py_item);
        ++item;
    }
    $result = SWIG_Python_AppendOutput($result, PyList_AsTuple(list));
    Py_DECREF(list);
}
%enddef // LIST_POINTER
