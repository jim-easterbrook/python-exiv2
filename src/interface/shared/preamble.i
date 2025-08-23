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
%include "shared/unique_ptr.i"

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

// Fragment to set EXV_ENABLE_FILESYSTEM on old libexiv2 versions
%fragment("set_EXV_ENABLE_FILESYSTEM", "header") %{
#if !EXIV2_TEST_VERSION(0, 28, 3)
#define EXV_ENABLE_FILESYSTEM
#endif
%}

// Improve docstrings for some exiv2 types
%typemap(doctype) bool "bool"
%typemap(doctype) Exiv2::byte "int"
%typemap(doctype) std::string "str"
