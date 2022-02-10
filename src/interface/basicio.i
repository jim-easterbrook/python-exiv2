// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2022  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") basicio

#pragma SWIG nowarn=321     // 'open' conflicts with a built-in name in python

%include "preamble.i"

%include "pybuffer.i"
%include "std_string.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::BasicIo);

// Allow BasicIo::write to take any Python buffer
%pybuffer_binary(const Exiv2::byte* data, long wcount)
%typecheck(SWIG_TYPECHECK_POINTER) const Exiv2::byte* %{
    $1 = PyObject_CheckBuffer($input);
%}

// Expose BasicIo contents as a Python buffer
%feature("python:bf_getbuffer",
         functype="getbufferproc") Exiv2::BasicIo "Exiv2_BasicIo_getbuf";
%feature("python:bf_releasebuffer",
         functype="releasebufferproc") Exiv2::BasicIo "Exiv2_BasicIo_releasebuf";
%{
static int Exiv2_BasicIo_getbuf(PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::BasicIo* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res)) {
        PyErr_SetNone(PyExc_BufferError);
        view->obj = NULL;
        return -1;
    }
    self->open();
    return PyBuffer_FillInfo(
        view, exporter, self->mmap(), self->size(), 1, flags);
}
static void Exiv2_BasicIo_releasebuf(PyObject* exporter, Py_buffer* view) {
    Exiv2::BasicIo* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res)) {
        return;
    }
    self->close();
}
%}

// Cludge to check Io is open before reading
%typemap(check) long rcount %{
    if (!arg1->isopen()) {
        PyErr_SetString(PyExc_RuntimeError, "$symname: not open");
        SWIG_fail;
    }
%}

// Make enum more Pythonic
ENUM(Position, "Seek starting positions.",
        beg = Exiv2::BasicIo::beg,
        cur = Exiv2::BasicIo::cur,
        end = Exiv2::BasicIo::end);

%ignore Exiv2::BasicIo::bigBlock_;
%ignore Exiv2::BasicIo::mmap;
%ignore Exiv2::BasicIo::munmap;
%ignore Exiv2::BasicIo::populateFakeData;
%ignore Exiv2::BasicIo::read(byte*, long);
%ignore Exiv2::IoCloser;
%ignore Exiv2::CurlIo::operator=;
%ignore Exiv2::FileIo::operator=;
%ignore Exiv2::HttpIo::operator=;
%ignore Exiv2::MemIo::operator=;
%ignore Exiv2::SshIo::operator=;

%include "exiv2/basicio.hpp"
