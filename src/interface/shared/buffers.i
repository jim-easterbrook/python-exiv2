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


%include "shared/keep_reference.i"

// Macro for input read only byte buffer
%define INPUT_BUFFER_RO(buf_type, len_type)
%typemap(doctype) buf_type ":py:term:`bytes-like object`";
%typemap(in) (buf_type, len_type) (PyObject* _global_view = NULL) {
    _global_view = PyMemoryView_GetContiguous($input, PyBUF_READ, 'A');
    if (!_global_view) {
        PyErr_Clear();
        %argument_fail(
            SWIG_TypeError, "bytes-like object", $symname, $argnum);
    }
    Py_buffer* buff = PyMemoryView_GET_BUFFER(_global_view);
    $1 = ($1_ltype) buff->buf;
    $2 = ($2_ltype) buff->len;
}
%typemap(freearg) (buf_type, len_type) %{
    Py_XDECREF(_global_view);
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_CHAR_PTR) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}
%enddef // INPUT_BUFFER_RO


// Macro for output writeable byte buffer
%define OUTPUT_BUFFER_RW(buf_type, count_type)
%typemap(doctype) buf_type "writeable :py:term:`bytes-like object`";
%typemap(in) (buf_type) (Py_buffer _global_view) {
    _global_view.obj = NULL;
    if (PyObject_GetBuffer(
            $input, &_global_view, PyBUF_CONTIG | PyBUF_WRITABLE) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "writable bytes-like object",
                       $symname, $argnum);
    }
    $1 = ($1_ltype) _global_view.buf;
}
%typemap(check) (buf_type, count_type) {
    if ($2 > ($2_ltype) _global_view.len) {
        %argument_fail(SWIG_ValueError, "buffer too small",
                       $symname, $argnum);
    }
}
%typemap(freearg) (buf_type) %{
    if (_global_view.obj) {
        PyBuffer_Release(&_global_view);
    }
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_CHAR_PTR) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}
%enddef // OUTPUT_BUFFER_RW

// Import exiv2.utilities.view_manager
%fragment("_import_view_manager_decl", "header") {
static PyObject* view_manager = NULL;
}
%fragment("_import_view_manager", "init",
          fragment="_import_view_manager_decl") {
{
    PyObject* mod = PyImport_ImportModule("exiv2.utilities");
    if (!mod)
        return INIT_ERROR_RETURN;
    view_manager = PyObject_GetAttrString(mod, "view_manager");
    if (!view_manager) {
        PyErr_SetString(
            PyExc_RuntimeError,
            "Import error: exiv2.utilities.view_manager not found.");
        return INIT_ERROR_RETURN;
    }
}
}

// Functions to store references to memoryview objects and release them
%fragment("memoryview_funcs", "header", fragment="private_data",
          fragment="_import_view_manager") {
static int store_view(PyObject* py_self, PyObject* view,
                      PyObject* callback=NULL) {
    PyObject* view_ref = PyWeakref_NewRef(view, callback);
    if (!view_ref)
        return -1;
    PyObject* marker = private_store_get(py_self, "marker");
    if (!marker) {
        // Marker is any weakrefable object.
        marker = PySet_New(NULL);
        if (!marker)
            return -1;
        int error = private_store_set(py_self, "marker", marker);
        Py_DECREF(marker);
        if (error)
            return -1;
    }
    PyObject* OK = PyObject_CallMethod(
        view_manager, "store_view", "(OO)", marker, view_ref);
    Py_DECREF(view_ref);
    if (!OK)
        return -1;
    Py_DECREF(OK);
    return 0;
};
static int release_views(PyObject* py_self) {
    private_store_del(py_self, "marker");
    return 0;
};
}

// Macro to convert byte* return value to memoryview
// WARNING: return value does not keep a reference to the data it points to
%define RETURN_VIEW_CB(signature, size_func, flags, callback, doc_method)
%typemap(doctype) signature "memoryview";
%typemap(out, fragment="memoryview_funcs") (signature) %{
    $result = PyMemoryView_FromMemory((char*)$1, size_func, flags);
    if (!$result)
        SWIG_fail;
    // Store a weak ref to the new memoryview
    if (store_view(self, $result, callback))
        SWIG_fail;
%}
#if #doc_method != ""
%feature("docstring") doc_method
"Returns a temporary Python memoryview of the object's data.

WARNING: do not resize or delete the object while using the view.

:rtype: memoryview"
#endif
%enddef // RETURN_VIEW_CB
%define RETURN_VIEW(signature, size_func, flags, doc_method)
RETURN_VIEW_CB(signature, size_func, flags, NULL, doc_method)
%enddef // RETURN_VIEW


// Macros to expose object data with a buffer interface
%define _BF_GETBUFFER(object_type, writeable, get_func)
%fragment("getbuffer"{object_type}, "header",
          fragment="get_ptr_size"{object_type}) {
static int getbuffer_%mangle(object_type)(
        PyObject* exporter, Py_buffer* view, int flags) {
    // Deprecated since 2025-07-09
    PyErr_WarnEx(PyExc_DeprecationWarning, "Please use 'data()' to get a"
                 " memoryview of object_type", 1);
    object_type* self = 0;
    Exiv2::byte* ptr = 0;
    Py_ssize_t size = 0;
    bool is_writeable = writeable && (flags && PyBUF_WRITABLE);
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(object_type*), 0)))
        goto fail;
    if (!get_ptr_size(self, is_writeable, ptr, size))
        goto fail;
    return PyBuffer_FillInfo(view, exporter, ptr,
        ptr ? size : 0, is_writeable ? 0 : 1, flags);
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
};
}
%fragment("getbuffer"{object_type});
%feature("python:bf_getbuffer", functype="getbufferproc")
    object_type "get_func";
%enddef // _BF_GETBUFFER

%define _BF_RELEASEBUFFER(object_type, release_func)
%fragment("releasebuffer"{object_type}, "header",
          fragment="release_ptr"{object_type}) {
static void releasebuffer_%mangle(object_type)(
        PyObject* exporter, Py_buffer* view) {
    object_type* self = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(object_type*), 0)))
        return;
    release_ptr(self);
};
}
%fragment("releasebuffer"{object_type});
%feature("python:bf_releasebuffer", functype="releasebufferproc")
    object_type "release_func";
%enddef // _BF_RELEASEBUFFER

%define EXPOSE_OBJECT_BUFFER(object_type, writeable, with_release)
// Add getbuffer slot to an object type
_BF_GETBUFFER(object_type, writeable, getbuffer_%mangle(object_type))
#if #with_release == "true"
// Add releasebuffer slot to an object type (not often needed)
_BF_RELEASEBUFFER(object_type, releasebuffer_%mangle(object_type))
#endif
%enddef // EXPOSE_OBJECT_BUFFER
