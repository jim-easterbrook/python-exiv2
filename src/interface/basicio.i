// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2022-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
%constant char* __doc__ =
    "Class interface to access files, memory and remote data.";
#endif

%feature("docstring") Exiv2::BasicIo "An interface for simple binary IO.

This appears to be mainly for use internally by libexiv2, apart from
accessing data with the mmap() and munmap() methods. Since v0.18.0
python-exiv2 has an Image.data() method to provide data access without
going via a Python BasicIo object.

It is planned to remove BasicIo from the Python interface in a future
release. Please let me (jim@jim-easterbrook.me.uk) know if that wiould
be a problem for you.";

#pragma SWIG nowarn=321 // 'open' conflicts with a built-in name in python

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/keep_reference.i"
%include "shared/private_data.i"
%include "shared/windows.i"

%include "std_string.i"

%import "types.i"

// Catch all C++ exceptions
EXCEPTION()

UNIQUE_PTR(Exiv2::BasicIo);

// Potentially blocking calls allow Python threads
%thread Exiv2::BasicIo::close;
%thread Exiv2::BasicIo::data;
%thread Exiv2::BasicIo::open;
%thread Exiv2::BasicIo::mmap;
%thread Exiv2::BasicIo::munmap;
%thread Exiv2::BasicIo::read;
%thread Exiv2::BasicIo::seek;
%thread Exiv2::BasicIo::transfer;
%thread Exiv2::BasicIo::write;

// Some calls don't raise exceptions
%noexception Exiv2::BasicIo::eof;
%noexception Exiv2::BasicIo::error;
%noexception Exiv2::BasicIo::ioType;
%noexception Exiv2::BasicIo::isopen;
%noexception Exiv2::BasicIo::path;

// Convert path encoding on Windows
WINDOWS_PATH(const std::string& path)
WINDOWS_PATH(const std::string& orgPath)
WINDOWS_PATH(const std::string& url)
WINDOWS_PATH_OUT(path)

// Deprecate methods that Python should not be calling
// Deprecated since 2025-07-09
DEPRECATE_FUNCTION(Exiv2::BasicIo::eof,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::getb,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::putb,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::read,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::readOrThrow,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::seek,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::seekOrThrow,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::tell,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::transfer,)
DEPRECATE_FUNCTION(Exiv2::BasicIo::write,)

// Add method to get the subclass type
%feature("docstring") Exiv2::BasicIo::ioType "Return the derived class type.

You shouldn't usually need to know the type of IO as they all have
the same interface.
:rtype: str
:return: A class name such as \"FileIo\"."
%fragment("set_EXV_ENABLE_FILESYSTEM");
%extend Exiv2::BasicIo {
    const char* ioType() {
        if (dynamic_cast<Exiv2::MemIo*>($self))
            return "MemIo";
%#ifdef EXV_ENABLE_FILESYSTEM
        else if (dynamic_cast<Exiv2::FileIo*>($self)) {
            if (dynamic_cast<Exiv2::XPathIo*>($self))
                return "XPathIo";
            return "FileIo";
        }
%#endif
        else if (dynamic_cast<Exiv2::RemoteIo*>($self)) {
            if (dynamic_cast<Exiv2::HttpIo*>($self))
                return "HttpIo";
%#ifdef EXV_USE_CURL
            else if (dynamic_cast<Exiv2::CurlIo*>($self))
                return "CurlIo";
%#endif
%#ifdef EXV_USE_SSH
            else if (dynamic_cast<Exiv2::SshIo*>($self))
                return "SshIo";
%#endif
            return "RemoteIo";
        }
        return "unknown";
    }
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
INPUT_BUFFER_RO(const Exiv2::byte* data, BUFLEN_T wcount)

// BasicIo::read can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf, BUFLEN_T rcount)

// Use default typemap for isWriteable parameter.
%typemap(default) bool isWriteable {$1 = false;}
%ignore Exiv2::BasicIo::mmap();

// Convert mmap() result to a Python memoryview
RETURN_VIEW(Exiv2::byte* mmap, $1 ? arg1->size() : 0,
            arg2 ? PyBUF_WRITE : PyBUF_READ,)

// Some methods of BasicIo release any existing memoryview
%{
#define RELEASE_VIEWS_BasicIo_close
#define RELEASE_VIEWS_BasicIo_data
#define RELEASE_VIEWS_BasicIo_mmap
#define RELEASE_VIEWS_BasicIo_munmap
#define RELEASE_VIEWS_BasicIo_open
#define RELEASE_VIEWS_BasicIo_putb
#define RELEASE_VIEWS_BasicIo_transfer
#define RELEASE_VIEWS_BasicIo_write
%}
%typemap(check, fragment="memoryview_funcs") Exiv2::BasicIo* self {
%#ifdef RELEASE_VIEWS_$symname
    release_views(self);
%#endif
}

// Add data() method for easy access
// The callback is used to call munmap when the memoryview is deleted
RETURN_VIEW(Exiv2::byte* data, $1 ? arg1->size() : 0,
            arg2 ? PyBUF_WRITE : PyBUF_READ,)
%feature("docstring") Exiv2::BasicIo::data
"Easy access to the IO data.

Calls open() and mmap() and returns a Python memoryview of the data.
munmap() and close() are called when the memoryview object is deleted.

:type isWriteable: bool, optional
:param isWriteable: Set to true if the mapped area should be writeable
    (default is false).
:rtype: memoryview"
%extend Exiv2::BasicIo {
    Exiv2::byte* data(bool isWriteable) {
        self->open();
        return self->mmap(isWriteable);
    };
}
%fragment("release_ptr"{Exiv2::BasicIo}, "header") {
static void release_ptr(Exiv2::BasicIo* self) {
    SWIG_PYTHON_THREAD_BEGIN_ALLOW;
    self->munmap();
    self->close();
    SWIG_PYTHON_THREAD_END_ALLOW;
};
}
%fragment("release_ptr"{Exiv2::BasicIo});
DEFINE_VIEW_CALLBACK(Exiv2::BasicIo, release_ptr(self);)

// Enable len(Exiv2::BasicIo)
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::BasicIo::size;
// Expose Exiv2::BasicIo contents as a Python buffer
%fragment("buffer_fill_info"{Exiv2::BasicIo}, "header") {
static int buffer_fill_info(Exiv2::BasicIo* self, Py_buffer* view,
                            PyObject* exporter, int flags) {
    Exiv2::byte* ptr;
    bool writeable = (flags && PyBUF_WRITABLE);
    if (self->open())
        return -1;
    try {
        SWIG_PYTHON_THREAD_BEGIN_ALLOW;
        ptr = self->mmap(writeable);
        SWIG_PYTHON_THREAD_END_ALLOW;
    } catch(EXV_EXCEPTION const& e) {
        return -1;
    }
    return PyBuffer_FillInfo(view, exporter, ptr, ptr ? self->size() : 0,
                             writeable ? 0 : 1, flags);
};
}
EXPOSE_OBJECT_BUFFER(Exiv2::BasicIo)
RELEASE_OBJECT_BUFFER(Exiv2::BasicIo)

// Make enum more Pythonic
#ifndef SWIGIMPORTED
DEFINE_CLASS_ENUM(BasicIo, Position,)
#else
IMPORT_CLASS_ENUM(_basicio, BasicIo, Position)
#endif

// deprecated since 2023-12-01
DEPRECATED_ENUM(BasicIo, Position)

%ignore Exiv2::BasicIo::bigBlock_;
%ignore Exiv2::BasicIo::operator=;
%ignore Exiv2::BasicIo::populateFakeData;
%ignore Exiv2::curlWriter;
%ignore Exiv2::IoCloser;
%ignore Exiv2::ReplaceStringInPlace;
%ignore Exiv2::readFile;
%ignore Exiv2::writeFile;
%ignore Exiv2::CurlIo;
%ignore Exiv2::FileIo;
%ignore Exiv2::HttpIo;
%ignore Exiv2::MemIo;
%ignore Exiv2::RemoteIo;
%ignore Exiv2::SshIo;
%ignore Exiv2::XPathIo;
%ignore EXV_XPATH_MEMIO;

%include "exiv2/basicio.hpp"
