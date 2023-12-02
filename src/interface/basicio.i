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
%thread Exiv2::BasicIo::close;
%thread Exiv2::BasicIo::open;
%thread Exiv2::BasicIo::mmap;
%thread Exiv2::BasicIo::munmap;
%thread Exiv2::BasicIo::read;
%thread Exiv2::MemIo::read;
%thread Exiv2::BasicIo::seek;
%thread Exiv2::FileIo::size;
%thread Exiv2::FileIo::tell;
%thread Exiv2::BasicIo::transfer;
%thread Exiv2::BasicIo::write;
%thread Exiv2::MemIo::write;

// Some calls don't raise exceptions
%noexception Exiv2::MemIo::close;
%noexception Exiv2::BasicIo::eof;
%noexception Exiv2::BasicIo::error;
%noexception Exiv2::BasicIo::isopen;
%noexception Exiv2::MemIo::mmap;
%noexception Exiv2::MemIo::munmap;
%noexception Exiv2::RemoteIo::munmap;
%noexception Exiv2::MemIo::open;
%noexception Exiv2::BasicIo::path;
%noexception Exiv2::MemIo::read;
%noexception Exiv2::MemIo::seek;
%noexception Exiv2::RemoteIo::seek;
%noexception Exiv2::MemIo::size;
%noexception Exiv2::RemoteIo::size;
%noexception Exiv2::MemIo::tell;
%noexception Exiv2::RemoteIo::tell;
%noexception Exiv2::MemIo::write;

// BasicIo return values keep a reference to the Image they refer to
KEEP_REFERENCE(Exiv2::BasicIo&)

// Enable len(io)
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::BasicIo::size;
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::FileIo::size;
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::RemoteIo::size;

// Allow BasicIo::write to take any Python buffer
INPUT_BUFFER_RO(const Exiv2::byte* data, long wcount)
INPUT_BUFFER_RO(const Exiv2::byte* data, size_t wcount)

// Allow MemIo to be ceated from a buffer
INPUT_BUFFER_RO(const Exiv2::byte* data, long size)
INPUT_BUFFER_RO(const Exiv2::byte* data, size_t size)
// Release Py_buffer after adding a reference to input object to result
%typemap(freearg) (const Exiv2::byte* data, long size),
                  (const Exiv2::byte* data, size_t size) %{
    if (_global_view.obj) {
        if (resultobj) {
            PyObject_SetAttrString(
                resultobj, "_refers_to", _global_view.obj);
        }
        PyBuffer_Release(&_global_view);
    }
%}

// BasicIo::read can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf, long rcount)
OUTPUT_BUFFER_RW(Exiv2::byte* buf, size_t rcount)

// Convert mmap() result to a Python memoryview
#ifndef SWIGIMPORTED
// plain bool typemap is general, restrict to this module with SWIGIMPORTED
%typemap(check) bool %{
    _global_writeable = $1;
%}
#endif
%typemap(out) Exiv2::byte* mmap (bool _global_writeable = false) {
    size_t len = arg1->size();
    if (!$1)
        len = 0;
    $result = PyMemoryView_FromMemory(
        (char*)$1, len, _global_writeable ? PyBUF_WRITE : PyBUF_READ);
}

// Expose BasicIo contents as a Python buffer
%feature("python:bf_getbuffer", functype="getbufferproc")
    Exiv2::BasicIo "BasicIo_getbuf";
%feature("python:bf_releasebuffer", functype="releasebufferproc")
    Exiv2::BasicIo "BasicIo_releasebuf";
%{
static int BasicIo_getbuf(PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::BasicIo* self = 0;
    Exiv2::byte* ptr = 0;
    bool writeable = flags && PyBUF_WRITABLE;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res))
        goto fail;
    if (self->open())
        goto fail;
    ptr = self->mmap(writeable);
    return PyBuffer_FillInfo(view, exporter, ptr,
        ptr ? self->size() : 0, writeable ? 0 : 1, flags);
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
}
static void BasicIo_releasebuf(PyObject* exporter, Py_buffer* view) {
    Exiv2::BasicIo* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__BasicIo, 0);
    if (!SWIG_IsOK(res)) {
        return;
    }
    self->munmap();
    self->close();
}
%}

// Make enum more Pythonic
DEPRECATED_ENUM(BasicIo, Position, "Seek starting positions.",
        "beg", Exiv2::BasicIo::beg,
        "cur", Exiv2::BasicIo::cur,
        "end", Exiv2::BasicIo::end);

%ignore Exiv2::BasicIo::bigBlock_;
%ignore Exiv2::BasicIo::populateFakeData;
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

// Make enum more Pythonic
CLASS_ENUM(BasicIo, Position, "Seek starting positions.",
    "beg", Exiv2::BasicIo::beg,
    "cur", Exiv2::BasicIo::cur,
    "end", Exiv2::BasicIo::end);
