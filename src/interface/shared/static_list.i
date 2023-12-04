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
%define LIST_POINTER(pattern, item_type, valid_test, conv_func)
%fragment("pointer_to_list"{item_type}, "header") {
static PyObject* pointer_to_list(const item_type* ptr) {
    const item_type* item = ptr;
    PyObject* list = PyList_New(0);
    while (item->valid_test) {
        PyList_Append(list, SWIG_Python_NewPointerObj(
            NULL, SWIG_as_voidptr(item), $descriptor(item_type*), 0));
        ++item;
    }
    return PyList_AsTuple(list);
};
}
%typemap(out, fragment="pointer_to_list"{item_type}) pattern {
    $result = SWIG_Python_AppendOutput(
        $result, pointer_to_list($1 conv_func));
}
%enddef // LIST_POINTER
