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


// Recursive macro to output #define statements for list of functions
%define _HOLD_BUFFER(hold_func, remainder...)
%{#define KEEPREF_VIEW_##hold_func%}
#if #remainder != ""
_HOLD_BUFFER(remainder)
#endif
%enddef

// Macro for input read only byte buffer
// hold_funcs is a list of functions that don't read the input data
// immediately, so keep a reference to the Python object
%define INPUT_BUFFER_RO(buf_type, len_type, hold_funcs...)
%typemap(doctype) buf_type ":py:term:`bytes-like object`";
%typemap(in) (buf_type, len_type) (PyObject* _global_view = NULL) {
    Py_buffer* buff = NULL;
    _global_view = PyMemoryView_FromObject($input);
    if (_global_view)
        buff = PyMemoryView_GET_BUFFER(_global_view);
    else
        PyErr_Clear();
    if (!_global_view || !PyBuffer_IsContiguous(buff, 'A')
        || (buff->shape && buff->itemsize != 1)) {
        %argument_fail(
            SWIG_TypeError, "bytes-like object", $symname, $argnum);
    }
    $1 = ($1_ltype) buff->buf;
    $2 = ($2_ltype) buff->len;
}
%typemap(freearg) (buf_type, len_type) %{
    Py_XDECREF(_global_view);
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_CHAR_PTR) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}

#if #hold_funcs != ""
_HOLD_BUFFER(hold_funcs)
%typemap(argout, fragment="private_data") (buf_type, len_type) {
%#ifdef KEEPREF_VIEW_$symname
    private_store_set(resultobj, "using_view", _global_view);
%#endif
}
#endif
%enddef // INPUT_BUFFER_RO

// Macro for functions to release the held reference
%define RELEASE_BUFFER(signature)
%typemap(ret, fragment="private_data") signature %{
    private_store_del(self, "using_view");
%}
%enddef

// Macro for output writeable byte buffer
%define OUTPUT_BUFFER_RW(buf_type, count_type)
%typemap(doctype) buf_type "writeable :py:term:`bytes-like object`";
#if #count_type != ""
%typemap(in) (buf_type, count_type) (Py_buffer _global_buff) {
    _global_buff.obj = NULL;
    if (PyObject_GetBuffer(
            $input, &_global_buff, PyBUF_CONTIG | PyBUF_WRITABLE) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "writable bytes-like object",
                       $symname, $argnum);
    }
    $1 = ($1_ltype) _global_buff.buf;
    $2 = ($2_ltype) _global_buff.len;
}
%typemap(freearg) (buf_type, count_type) %{
    if (_global_buff.obj) {
        PyBuffer_Release(&_global_buff);
    }
%}
#else
%typemap(in) (buf_type) (Py_buffer _global_buff) {
    _global_buff.obj = NULL;
    if (PyObject_GetBuffer(
            $input, &_global_buff, PyBUF_CONTIG | PyBUF_WRITABLE) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "writable bytes-like object",
                       $symname, $argnum);
    }
    // check buffer is large enough, assumes arg1 points to self
    if ((Py_ssize_t) arg1->size() > _global_buff.len) {
        %argument_fail(SWIG_ValueError, "buffer too small",
                       $symname, $argnum);
    }
    $1 = ($1_ltype) _global_buff.buf;
}
%typemap(freearg) (buf_type) %{
    if (_global_buff.obj) {
        PyBuffer_Release(&_global_buff);
    }
%}
#endif
%typemap(typecheck, precedence=SWIG_TYPECHECK_CHAR_PTR) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}
%enddef // OUTPUT_BUFFER_RW


// Macros to expose object data with a buffer interface

// Add getbuffer slot to an object type
%define EXPOSE_OBJECT_BUFFER(object_type)
%fragment("getbuffer"{object_type}, "header",
          fragment="buffer_fill_info"{object_type}) {
static int getbuffer_%mangle(object_type)(
        PyObject* exporter, Py_buffer* view, int flags) {
    // Deprecated since 2025-07-09
    PyErr_WarnEx(PyExc_DeprecationWarning, "Please use 'data()' to get a"
                 " memoryview of object_type", 1);
    object_type* self = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(object_type*), 0)))
        goto fail;
    if (buffer_fill_info(self, view, exporter, flags))
        goto fail;
    return 0;
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
};
}
%fragment("getbuffer"{object_type});
_SET_BF_GETBUFFER(object_type, getbuffer_%mangle(object_type))
%enddef // EXPOSE_OBJECT_BUFFER
%define _SET_BF_GETBUFFER(object_type, func)
%feature("python:bf_getbuffer", functype="getbufferproc")
    object_type "func";
%enddef // _SET_BF_GETBUFFER


// Add releasebuffer slot to an object type (not often needed)
%define RELEASE_OBJECT_BUFFER(object_type)
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
_SET_BF_RELEASEBUFFER(object_type, releasebuffer_%mangle(object_type))
%enddef // RELEASE_OBJECT_BUFFER
%define _SET_BF_RELEASEBUFFER(object_type, func)
%feature("python:bf_releasebuffer", functype="releasebufferproc")
    object_type "func";
%enddef // _SET_BF_RELEASEBUFFER
