// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Stuff to handle auto_ptr or unique_ptr
#if EXIV2_VERSION_HEX < 0x001c0000
#define SMART_PTR AutoPtr
%ignore AutoPtr;
%define UNIQUE_PTR(pointed_type)
%include "std_auto_ptr.i"
%typemap(doctype) pointed_type##::AutoPtr #pointed_type
%auto_ptr(pointed_type)
%enddef // UNIQUE_PTR
#else
#define SMART_PTR UniquePtr
%ignore UniquePtr;
#if SWIG_VERSION >= 0x040100
%define UNIQUE_PTR(pointed_type)
%include "std_unique_ptr.i"
%typemap(doctype) pointed_type##::UniquePtr #pointed_type
%unique_ptr(pointed_type)
%enddef // UNIQUE_PTR
#else
template <typename T>
struct std::unique_ptr {};
%define UNIQUE_PTR(pointed_type)
%typemap(out) std::unique_ptr<pointed_type> %{
    $result = SWIG_NewPointerObj(
        $1.release(), $descriptor(pointed_type *), SWIG_POINTER_OWN);
%}
%template() std::unique_ptr<pointed_type>;
%enddef // UNIQUE_PTR
#endif
#endif
