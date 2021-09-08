// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") types

#pragma SWIG nowarn=202     // Could not evaluate expression...
#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=362     // operator= ignored
#pragma SWIG nowarn=503     // Can't wrap 'X' unless renamed to a valid identifier.
#pragma SWIG nowarn=509     // Overloaded method X effectively ignored, as it is shadowed by Y.

%include "preamble.i"

%include "stdint.i"
%include "std_pair.i"

// Add __len__ to Exiv2::DataBuf
%feature("python:slot", "sq_length", functype="lenfunc") Exiv2::DataBuf::__len__;
%extend Exiv2::DataBuf {
    long __len__() {return $self->size_;}
}
// Memory efficient conversion of Exiv2::DataBuf return values
%typemap(out) Exiv2::DataBuf {
    std::pair<Exiv2::byte*, long> buf = $1.release();
    $result = SWIG_NewPointerObj(
        new $type(buf.first, buf.second), $&1_descriptor, SWIG_POINTER_OWN);
}
// Expose Exiv2::DataBuf contents as a Python buffer
%feature("python:bf_getbuffer",
         functype="getbufferproc") Exiv2::DataBuf "Exiv2_DataBuf_getbuf";
%{
static int Exiv2_DataBuf_getbuf(PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::DataBuf* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__DataBuf, 0);
    if (!SWIG_IsOK(res)) {
        PyErr_SetNone(PyExc_BufferError);
        view->obj = NULL;
        return -1;
    }
    return PyBuffer_FillInfo(view, exporter, self->pData_, self->size_, 1, flags);
    }
%}
// Hide parts of Exiv2::DataBuf that Python shouldn't see
%ignore Exiv2::DataBuf::pData_;
%ignore Exiv2::DataBuf::size_;

// Ignore slice stuff that SWIG can't understand
%ignore makeSlice;

%include "exiv2/types.hpp"

%template(URational) std::pair<uint32_t, uint32_t>;
%template(Rational) std::pair<int32_t, int32_t>;