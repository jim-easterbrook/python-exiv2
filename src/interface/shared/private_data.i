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


// Functions to store and retrieve "private" data attached to Pyhon object
%fragment("private_data", "header") {
static PyObject* _get_store(PyObject* py_self, bool create) {
    // Return a borrowed reference
    PyObject* dict = NULL;
    if (!PyObject_HasAttrString(py_self, "_private_data_")) {
        if (!create)
            return NULL;
        dict = PyDict_New();
        if (!dict)
            return NULL;
        int error = PyObject_SetAttrString(py_self, "_private_data_", dict);
        Py_DECREF(dict);
        if (error)
            return NULL;
    }
    dict = PyObject_GetAttrString(py_self, "_private_data_");
    Py_DECREF(dict);
    return dict;
};
static int private_store_set(PyObject* py_self, const char* name,
                             PyObject* val) {
    PyObject* dict = _get_store(py_self, true);
    if (!dict)
        return -1;
    return PyDict_SetItemString(dict, name, val);
};
static PyObject* private_store_get(PyObject* py_self, const char* name) {
    // Return a borrowed reference
    PyObject* dict = _get_store(py_self, false);
    if (!dict)
        return NULL;
    return PyDict_GetItemString(dict, name);
};
static int private_store_del(PyObject* py_self, const char* name) {
    PyObject* dict = _get_store(py_self, false);
    if (!dict)
        return 0;
    if (PyDict_GetItemString(dict, name))
        return PyDict_DelItemString(dict, name);
    return 0;
};
}

// Functions to store references to memoryview objects and release them
%fragment("memoryview_funcs", "header", fragment="private_data") {
static int store_view(PyObject* py_self, PyObject* view) {
    PyObject* view_list = private_store_get(py_self, "view_list");
    if (!view_list) {
        view_list = PyList_New(0);
        if (!view_list)
            return -1;
        int error = private_store_set(py_self, "view_list", view_list);
        Py_DECREF(view_list);
        if (error)
            return -1;
    }
    PyObject* callback = PyObject_GetAttrString(py_self, "_view_deleted_cb");
    if (!callback)
        return -1;
    PyObject* view_ref = PyWeakref_NewRef(view, callback);
    Py_DECREF(callback);
    if (!view_ref)
        return -1;
    int result = PyList_Append(view_list, view_ref);
    Py_DECREF(view_ref);
    return result;
};
static int release_views(PyObject* py_self) {
    PyObject* view_list = private_store_get(py_self, "view_list");
    if (!view_list)
        return 0;
    PyObject* view_ref = NULL;
    PyObject* view = NULL;
    for (Py_ssize_t idx = PyList_Size(view_list); idx > 0; idx--) {
        view_ref = PyList_GetItem(view_list, idx - 1);
        view = PyWeakref_GetObject(view_ref);
        if (view != Py_None)
            Py_XDECREF(PyObject_CallMethod(view, "release", NULL));
        PyList_SetSlice(view_list, idx - 1, idx, NULL);
    }
    return 0;
};
}

/* Macro to convert byte* (or similar) return value to memoryview
 *
 * We can't store a reference to the data owner in the memoryview result
 * so we store a weak reference to the memoryview in the data owner. To
 * prevent the data owner being deleted while the memoryview exists we
 * use a method of the Python data owner as the weakref callback. This
 * increments the data owner's ref count, preventing it from being deleted,
 * then decrements it when the memoryview is deleted (and the callback is
 * called). The callback doesn't have to do anything, but it can be used
 * for cleanup (e.g. calling BasicIo::munmap).
 */
%define RETURN_VIEW(signature, size_func, flags, doc_method)
%typemap(doctype) signature "memoryview";
%typemap(out, fragment="memoryview_funcs") (signature) {
    $result = PyMemoryView_FromMemory((char*)$1, size_func, flags);
    if (!$result)
        SWIG_fail;
    // Store a weak ref to the new memoryview
    if (store_view(self, $result))
        SWIG_fail;
}
#if #doc_method != ""
%feature("docstring") doc_method
"Returns a temporary Python memoryview of the object's data.

:rtype: memoryview"
#endif
%enddef // RETURN_VIEW

%define DEFINE_VIEW_CALLBACK(data_owner, contents)
#if #contents == ""
%noexception data_owner::_view_deleted_cb;
#endif
%extend data_owner {
    void _view_deleted_cb(PyObject* ref) {contents};
}
%enddef // DEFINE_VIEW_CALLBACK
