// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2025  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") utilities

%include "shared/preamble.i"


// Class to store and release memoryviews
%typemap(in, numinputs=0) PyObject* py_self {$1 = self;}
%inline %{
class ViewManager {
private:
    PyObject* view_list;
public:
    ViewManager() {
        view_list = PyList_New(0);
    };
    PyObject* store_view(PyObject* py_self, PyObject* marker,
                         PyObject* view_ref) {
        release_views(NULL);
        int error = 0;
        PyObject* callback = PyObject_GetAttrString(
            py_self, "release_views");
        if (!callback)
            return NULL;
        PyObject* marker_ref = PyWeakref_NewRef(marker, callback);
        Py_DECREF(callback);
        PyObject* details = PyTuple_Pack(2, marker_ref, view_ref);
        Py_XDECREF(marker_ref);
        if (!details)
            return NULL;
        error = PyList_Append(view_list, details);
        Py_DECREF(details);
        if (error)
            return NULL;
        return SWIG_Py_Void();
    };
    void release_views(PyObject* marker) {
        // Release any views of object that owned marker
        PyObject* details = NULL;
        PyObject* view_ref = NULL;
        PyObject* marker_ref = NULL;
        PyObject* view = NULL;
        for (Py_ssize_t idx = PyList_Size(view_list); idx > 0; idx--) {
            details = PyList_GetItem(view_list, idx - 1);
            marker_ref = PyTuple_GET_ITEM(details, 0);
            view_ref = PyTuple_GET_ITEM(details, 1);
            view = PyWeakref_GetObject(view_ref);
            if (view != Py_None) {
                if (PyWeakref_GetObject(marker_ref) != Py_None)
                    continue;
                Py_XDECREF(PyObject_CallMethod(view, "release", NULL));
            }
            PyList_SetSlice(view_list, idx - 1, idx, NULL);
        }
    };
};
%}

// Create one ViewManager instance to be used in all modules
%constant PyObject* view_manager = PyObject_CallMethod(
    m, "ViewManager", NULL);
