// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2022-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2", threads="1") basicio
%nothread;

#pragma SWIG nowarn=321     // 'open' conflicts with a built-in name in python

%include "preamble.i"

%include "std_string.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::BasicIo);

// Potentially blocking calls allow Python threads
%thread Exiv2::BasicIo::mmap;
%thread Exiv2::BasicIo::munmap;
%thread Exiv2::BasicIo::open;
%thread Exiv2::BasicIo::close;
%thread Exiv2::BasicIo::read;
%thread Exiv2::BasicIo::write;
%thread Exiv2::BasicIo::transfer;
%thread Exiv2::BasicIo::seek;

// BasicIo return values keep a reference to the Image they refer to
KEEP_REFERENCE(Exiv2::BasicIo&)

// Allow BasicIo::write to take any Python buffer
INPUT_BUFFER_RO(const Exiv2::byte* data, long wcount)

// Ensure Io is open before calling mmap() or read()
EXCEPTION(mmap,
    if (!arg1->isopen()) {
        PyErr_SetString(PyExc_RuntimeError, "$symname: not open");
        SWIG_fail;
    })
EXCEPTION(read,
    if (!arg1->isopen()) {
        PyErr_SetString(PyExc_RuntimeError, "$symname: not open");
        SWIG_fail;
    })

// Convert mmap() result to an object with a buffer interface
%typemap(check) bool isWriteable %{
    _global_writeable = $1;
%}
%typemap(out) Exiv2::byte* mmap (bool _global_writeable = false) {
    if ($1 == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "$symname: not implemented");
        SWIG_fail;
    }
    $result = SWIG_NewPointerObj(
        new byte_buffer($1, arg1->size(), _global_writeable ? 0 : 1),
        $descriptor(byte_buffer*), SWIG_POINTER_OWN);
}
// mmap() return value keeps a reference to the Io it points to
KEEP_REFERENCE(Exiv2::byte* mmap)

#ifndef SWIGIMPORTED
BYTE_BUFFER_CLASS()
#endif

// Expose BasicIo contents as a Python buffer
%feature("python:bf_getbuffer",
         functype="getbufferproc") Exiv2::BasicIo "Exiv2_BasicIo_getbuf";
%feature("python:bf_releasebuffer",
         functype="releasebufferproc") Exiv2::BasicIo "Exiv2_BasicIo_releasebuf";
%{
static int Exiv2_BasicIo_getbuf(PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::BasicIo* self = 0;
    Exiv2::byte* ptr = 0;
    size_t len = 0;
    PyErr_WarnEx(PyExc_DeprecationWarning,
        "use 'Io.mmap()' to get the data buffer", 1);
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res)) {
        PyErr_SetNone(PyExc_BufferError);
        view->obj = NULL;
        return -1;
    }
    {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        self->open();
        ptr = self->mmap();
        len = self->size();
        SWIG_PYTHON_THREAD_END_ALLOW;
    }
    return PyBuffer_FillInfo(view, exporter, ptr, len, 1, flags);
}
static void Exiv2_BasicIo_releasebuf(PyObject* exporter, Py_buffer* view) {
    Exiv2::BasicIo* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res)) {
        return;
    }
    {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        self->close();
        SWIG_PYTHON_THREAD_END_ALLOW;
    }
}
%}

// Make enum more Pythonic
ENUM(Position, "Seek starting positions.",
        "beg", Exiv2::BasicIo::beg,
        "cur", Exiv2::BasicIo::cur,
        "end", Exiv2::BasicIo::end);

%ignore Exiv2::BasicIo::bigBlock_;
%ignore Exiv2::BasicIo::populateFakeData;
%ignore Exiv2::BasicIo::read(byte*, long);
%ignore Exiv2::BasicIo::readOrThrow;
%ignore Exiv2::BasicIo::seekOrThrow;
%ignore Exiv2::IoCloser;
%ignore Exiv2::ReplaceStringInPlace;
%ignore Exiv2::readFile;
%ignore Exiv2::writeFile;
%ignore Exiv2::XPathIo::GEN_FILE_EXT;
%ignore Exiv2::XPathIo::TEMP_FILE_EXT;
%ignore Exiv2::CurlIo::operator=;
%ignore Exiv2::FileIo::operator=;
%ignore Exiv2::HttpIo::operator=;
%ignore Exiv2::MemIo::operator=;
%ignore Exiv2::SshIo::operator=;
%ignore EXV_XPATH_MEMIO;

%include "exiv2/basicio.hpp"
