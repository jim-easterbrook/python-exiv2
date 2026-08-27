// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2025-26  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Implementation of functions added in Python 3.13
%fragment("Python_313_functions", "header") {
%#if PY_VERSION_HEX < 0x030d0000
static int PyDict_ContainsString(PyObject *p, const char *key) {
    return (PyDict_GetItemString(p, key)) ? 1 : 0;
};
static int PyDict_GetItemStringRef(
        PyObject *p, const char *key, PyObject **result) {
    *result = PyDict_GetItemString(p, key);
    if (*result) {
        Py_INCREF(*result);
        return 1;
    }
    return 0;
};
static PyObject* PyList_GetItemRef(PyObject *list, Py_ssize_t index) {
    PyObject* result = PyList_GetItem(list, index);
    if (result) {
        Py_INCREF(result);
    }
    return result;
};
static int PyObject_GetOptionalAttrString(
        PyObject *obj, const char *attr_name, PyObject **result) {
    if (PyObject_HasAttrString(obj, attr_name) == 0) {
        *result = NULL;
        return 0;
    }
    *result = PyObject_GetAttrString(obj, attr_name);
    if (*result)
        return 1;
    return -1;
};
static int PyWeakref_GetRef(PyObject *ref, PyObject **pobj) {
    *pobj = PyWeakref_GetObject(ref);
    if (*pobj == Py_None) {
        *pobj = NULL;
        return 0;
    }
    Py_INCREF(*pobj);
    return 1;
};
%#endif
}

// Functions to store and retrieve "private" data attached to Pyhon object
%fragment("private_data", "header", fragment="Python_313_functions") {
static int _get_store(PyObject* py_self, bool create, PyObject** dict) {
    int result = PyObject_GetOptionalAttrString(
        py_self, "_private_data_", dict);
    if ((result > 0) || !create)
        return result;
    *dict = PyDict_New();
    if (*dict) {
        result = PyObject_SetAttrString(py_self, "_private_data_", *dict);
        if (result < 0) {
            Py_DECREF(*dict);
            *dict = NULL;
        }
    }
    return result;
};
static int private_store_set(PyObject* py_self, const char* name,
                             PyObject* value) {
    PyObject* dict = NULL;
    int result = _get_store(py_self, true, &dict);
    if (dict) {
        result = PyDict_SetItemString(dict, name, value);
        Py_DECREF(dict);
    }
    return result;
};
static int private_store_get(
        PyObject* py_self, const char* name, PyObject** value) {
    *value = NULL;
    PyObject* dict = NULL;
    int result = _get_store(py_self, false, &dict);
    if (dict) {
        result = PyDict_GetItemStringRef(dict, name, value);
        Py_DECREF(dict);
    }
    return result;
};
static int private_store_del(PyObject* py_self, const char* name) {
    PyObject* dict = NULL;
    int result = _get_store(py_self, false, &dict);
    if (dict) {
        if (PyDict_ContainsString(dict, name))
            result = PyDict_DelItemString(dict, name);
        Py_DECREF(dict);
    }
    return result;
};
}

// Functions to store references to memoryview objects and release them
%fragment("memoryview_funcs", "header", fragment="private_data",
          fragment="Python_313_functions") {
static int store_view(PyObject* py_self, PyObject* view) {
    PyObject* callback = PyObject_GetAttrString(py_self, "_view_deleted_cb");
    if (!callback)
        return -1;
    PyObject* view_ref = PyWeakref_NewRef(view, callback);
    Py_DECREF(callback);
    if (!view_ref)
        return -1;
    PyObject* view_list = NULL;
    int result = private_store_get(py_self, "view_list", &view_list);
    if (!view_list) {
        view_list = PyList_New(0);
        if (!view_list) {
            Py_DECREF(view_ref);
            return -1;
        }
        int error = private_store_set(py_self, "view_list", view_list);
        if (error) {
            Py_DECREF(view_list);
            Py_DECREF(view_ref);
            return -1;
        }
    }
    result = PyList_Append(view_list, view_ref);
    Py_DECREF(view_list);
    Py_DECREF(view_ref);
    return result;
};
static int release_views(PyObject* py_self) {
    PyObject* view_list = NULL;
    int result = private_store_get(py_self, "view_list", &view_list);
    if (!view_list)
        return result;
    PyObject* view_ref = NULL;
    PyObject* view = NULL;
    for (Py_ssize_t idx = PyList_Size(view_list); idx > 0; idx--) {
        view_ref = PyList_GetItemRef(view_list, idx - 1);
        result = PyWeakref_GetRef(view_ref, &view);
        Py_DECREF(view_ref);
        if (result < 0) {
            Py_DECREF(view_list);
            return result;
        }
        if (view) {
            Py_XDECREF(PyObject_CallMethod(view, "release", NULL));
            Py_DECREF(view);
        }
        PyList_SetSlice(view_list, idx - 1, idx, NULL);
    }
    Py_DECREF(view_list);
    return result;
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
