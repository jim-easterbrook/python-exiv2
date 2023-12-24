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


// Macro for input read only byte buffer
%define INPUT_BUFFER_RO(buf_type, len_type)
%typemap(doctype) buf_type "bytes-like object";
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


// Macro for input read only byte buffer, result keeps reference to input
%define INPUT_BUFFER_RO_EX(buf_type, len_type)
INPUT_BUFFER_RO(buf_type, len_type)
%typemap(freearg) (buf_type, len_type) %{
    if (resultobj && SwigPyObject_Check(resultobj)) {
        PyObject_SetAttrString(
            resultobj, "_refers_to", _global_view);
    }
    Py_XDECREF(_global_view);
%}
%enddef // INPUT_BUFFER_RO_EX


// Macro for output writeable byte buffer
%define OUTPUT_BUFFER_RW(buf_type, count_type)
%typemap(doctype) buf_type "writeable bytes-like object";
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

// Macro to convert byte* return value to memoryview
// WARNING: return value does not keep a reference to the data it points to
%define RETURN_VIEW(signature, size_func, flags, doc_method)
%typemap(out) (signature) %{
    $result = PyMemoryView_FromMemory((char*)$1, size_func, flags);
%}
%feature("docstring") doc_method
"Returns a temporary Python memoryview of the object's data.

WARNING: do not resize or delete the object while using the view."
%enddef // RETURN_VIEW
