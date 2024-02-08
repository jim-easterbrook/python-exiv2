// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2022-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Classes to access files, memory and remote data.";
#endif

#pragma SWIG nowarn=321 // 'open' conflicts with a built-in name in python

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/enum.i"
%include "shared/exception.i"
%include "shared/keep_reference.i"
%include "shared/unique_ptr.i"
%include "shared/windows_path.i"

%include "std_string.i"

%import "types.i"

// Catch all C++ exceptions
EXCEPTION()

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
WINDOWS_PATH_OUT(path)

// Convert BasicIo return values to actual subclass
%fragment("basicio_subtype", "header") {
static swig_type_info* basicio_subtype(Exiv2::BasicIo* ptr) {
    if (dynamic_cast<Exiv2::MemIo*>(ptr))
        return $descriptor(Exiv2::MemIo*);
    else if (dynamic_cast<Exiv2::FileIo*>(ptr)) {
        if (dynamic_cast<Exiv2::XPathIo*>(ptr))
            return $descriptor(Exiv2::XPathIo*);
        else
            return $descriptor(Exiv2::FileIo*);
    }
    else if (dynamic_cast<Exiv2::RemoteIo*>(ptr)) {
        if (dynamic_cast<Exiv2::HttpIo*>(ptr))
            return $descriptor(Exiv2::HttpIo*);
        else
            return $descriptor(Exiv2::RemoteIo*);
    }
    return $descriptor(Exiv2::BasicIo*);
};
}
%typemap(out, fragment="basicio_subtype") Exiv2::BasicIo& {
    $result = SWIG_NewPointerObj($1, basicio_subtype($1), 0);
}
%typemap(out, fragment="basicio_subtype") Exiv2::BasicIo::SMART_PTR {
    Exiv2::BasicIo* ptr = (&$1)->release();
    $result = SWIG_NewPointerObj(
        ptr, basicio_subtype(ptr), SWIG_POINTER_OWN);
}

// readOrThrow & seekOrThrow use ErrorCode internally without Exiv2:: prefix
// as if SWIG doesn't realise ErrorCode is in the Exiv2 namespace
%{
typedef Exiv2::ErrorCode ErrorCode;
%}

// readOrThrow has an optional ErrorCode parameter, seekOrThrow isn't
// optional but this typemap makes it so
%typemap(default) ErrorCode err
    {$1 = Exiv2::ErrorCode::kerCorruptedMetadata;}
%ignore Exiv2::BasicIo::readOrThrow(byte *, size_t);

// BasicIo return values keep a reference to the Image they refer to
KEEP_REFERENCE(Exiv2::BasicIo&)

// Allow BasicIo::write to take any Python buffer
INPUT_BUFFER_RO(const Exiv2::byte* data, long wcount)
INPUT_BUFFER_RO(const Exiv2::byte* data, size_t wcount)

// Allow MemIo to be ceated from a buffer
INPUT_BUFFER_RO_EX(const Exiv2::byte* data, long size)
INPUT_BUFFER_RO_EX(const Exiv2::byte* data, size_t size)

// BasicIo::read can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf, long rcount)
OUTPUT_BUFFER_RW(Exiv2::byte* buf, size_t rcount)

// Use default typemap for isWriteable parameter.
%typemap(default) bool isWriteable {$1 = false;}
%ignore Exiv2::BasicIo::mmap();

// Convert mmap() result to a Python memoryview, assumes arg2 = isWriteable
RETURN_VIEW(Exiv2::byte* mmap, $1 ? arg1->size() : 0,
            arg2 ? PyBUF_WRITE : PyBUF_READ,)

%define EXTEND_BASICIO(io_type)
// Enable len(io_type)
%feature("python:slot", "sq_length", functype="lenfunc") io_type::size;
// Expose io_type contents as a Python buffer
%fragment("get_ptr_size"{io_type}, "header") {
static bool get_ptr_size(io_type* self, bool is_writeable,
                         Exiv2::byte*& ptr, Py_ssize_t& size) {
    if (self->open())
        return false;
    try {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        ptr = self->mmap(is_writeable);
        SWIG_PYTHON_THREAD_END_ALLOW;
#if EXIV2_VERSION_HEX < 0x001c0000
    } catch(Exiv2::AnyError const& e) {
#else
    } catch(Exiv2::Error const& e) {
#endif
        return false;
    }
    size = self->size();
    return true;
};
}
%fragment("release_ptr"{io_type}, "header") {
static void release_ptr(io_type* self) {
    SWIG_PYTHON_THREAD_BEGIN_ALLOW;
    self->munmap();
    self->close();
    SWIG_PYTHON_THREAD_END_ALLOW;
};
}
EXPOSE_OBJECT_BUFFER(io_type, true, true)
%enddef // EXTEND_BASICIO

EXTEND_BASICIO(Exiv2::FileIo)
EXTEND_BASICIO(Exiv2::MemIo)
EXTEND_BASICIO(Exiv2::RemoteIo)

// Make enum more Pythonic
DEFINE_CLASS_ENUM(BasicIo, Position, "Seek starting positions.",
    "beg", Exiv2::BasicIo::beg,
    "cur", Exiv2::BasicIo::cur,
    "end", Exiv2::BasicIo::end);

// deprecated since 2023-12-01
DEPRECATED_ENUM(BasicIo, Position, "Seek starting positions.",
        "beg", Exiv2::BasicIo::beg,
        "cur", Exiv2::BasicIo::cur,
        "end", Exiv2::BasicIo::end);

%ignore Exiv2::BasicIo::~BasicIo;
%ignore Exiv2::BasicIo::bigBlock_;
%ignore Exiv2::BasicIo::populateFakeData;
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
