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

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/enum.i"
%include "shared/keep_reference.i"
%include "shared/unique_ptr.i"
%include "shared/windows_path.i"

%include "std_string.i"

%import "types.i"

UNIQUE_PTR(Exiv2::BasicIo);

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

// Convert path encoding on Windows
WINDOWS_PATH(const std::string& path)
WINDOWS_PATH(const std::string& orgPath)
WINDOWS_PATH(const std::string& url)
WINDOWS_PATH_OUT(std::string path)

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
INPUT_BUFFER_RO_EX(const Exiv2::byte* data, long size)
INPUT_BUFFER_RO_EX(const Exiv2::byte* data, size_t size)

// BasicIo::read can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf, long rcount)
OUTPUT_BUFFER_RW(Exiv2::byte* buf, size_t rcount)

// Use default typemap for isWriteable parameter. Some derived classes don't
// name the parameter so a plain bool typemap is needed. This is far too
// general, so SWIGIMPORTED is used to limit it to this module.
#ifndef SWIGIMPORTED
%typemap(default) bool {$1 = false;}
%ignore Exiv2::BasicIo::mmap();
#endif
// Convert mmap() result to a Python memoryview, assumes arg2 = isWriteable
%typemap(out) Exiv2::byte* mmap {
    size_t len = arg1->size();
    if (!$1)
        len = 0;
    $result = PyMemoryView_FromMemory(
        (char*)$1, len, arg2 ? PyBUF_WRITE : PyBUF_READ);
}

// Expose BasicIo contents as a Python buffer
%fragment("get_buffer"{Exiv2::BasicIo}, "header") {
static int %mangle(Exiv2::BasicIo)_getbuff(
        PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::BasicIo* self = 0;
    Exiv2::byte* ptr = 0;
    bool writeable = flags && PyBUF_WRITABLE;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(Exiv2::BasicIo*), 0)))
        goto fail;
    if (self->open())
        goto fail;
    try {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        ptr = self->mmap(writeable);
        SWIG_PYTHON_THREAD_END_ALLOW;
#if EXIV2_VERSION_HEX < 0x001c0000
    } catch(Exiv2::AnyError const& e) {
#else
    } catch(Exiv2::Error const& e) {
#endif
        goto fail;
    }
    return PyBuffer_FillInfo(view, exporter, ptr,
        ptr ? self->size() : 0, writeable ? 0 : 1, flags);
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
};
static void %mangle(Exiv2::BasicIo)_releasebuff(
        PyObject* exporter, Py_buffer* view) {
    Exiv2::BasicIo* self = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(Exiv2::BasicIo*), 0))) {
        return;
    }
    SWIG_PYTHON_THREAD_BEGIN_ALLOW;
    self->munmap();
    self->close();
    SWIG_PYTHON_THREAD_END_ALLOW;
};
}
%fragment("get_buffer"{Exiv2::BasicIo});
%feature("python:bf_getbuffer", functype="getbufferproc")
    Exiv2::BasicIo "Exiv2_BasicIo_getbuff";
%feature("python:bf_releasebuffer", functype="releasebufferproc")
    Exiv2::BasicIo "Exiv2_BasicIo_releasebuff";

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
