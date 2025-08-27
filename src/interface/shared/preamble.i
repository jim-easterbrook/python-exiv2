// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%{
#include "exiv2/exiv2.hpp"
%}

%include "shared/enum.i"
%include "shared/exception.i"

#if SWIG_VERSION < 0x040400
%{
#define INIT_ERROR_RETURN NULL
%}
#else
%{
#define INIT_ERROR_RETURN -1
%}
#endif

// EXIV2API prepends every function declaration
#define EXIV2API
// Some have this instead
#define EXIV2LIB_DEPRECATED_EXPORT
// Older versions of libexiv2 define these as well
#define EXV_DLLLOCAL
#define EXV_DLLPUBLIC

// Data sizes have different types in exiv2 0.27 and 0.28
#if EXIV2_VERSION_HEX < 0x001c0000
#define BUFLEN_T long
#else
#define BUFLEN_T size_t
#endif

// Stuff to handle auto_ptr or unique_ptr
#if EXIV2_VERSION_HEX < 0x001c0000
    #define SMART_PTR AutoPtr
    %ignore AutoPtr;

    %define UNIQUE_PTR(pointed_type)
    %include "std_auto_ptr.i"
    %typemap(doctype) pointed_type##::AutoPtr #pointed_type
    %auto_ptr(pointed_type)
    %enddef // UNIQUE_PTR
#else // EXIV2_VERSION_HEX
    #define SMART_PTR UniquePtr
    %ignore UniquePtr;

    %define UNIQUE_PTR(pointed_type)
    %include "std_unique_ptr.i"
    %typemap(doctype) pointed_type##::UniquePtr #pointed_type
    %unique_ptr(pointed_type)
    %enddef // UNIQUE_PTR
#endif // EXIV2_VERSION_HEX

// Fragment to set EXV_ENABLE_FILESYSTEM on old libexiv2 versions
%fragment("set_EXV_ENABLE_FILESYSTEM", "header") %{
#if !EXIV2_TEST_VERSION(0, 28, 3)
#define EXV_ENABLE_FILESYSTEM
#endif
%}

// Class extensions often need access to their Python object
%typemap(in, numinputs=0) PyObject* py_self {$1 = self;}

// Improve docstrings for some exiv2 types
%typemap(doctype) bool "bool"
%typemap(doctype) Exiv2::byte "int"
%typemap(doctype) std::string "str"
