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
