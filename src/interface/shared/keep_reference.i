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


// Macro to keep a reference to any object when returning a particular type.
%define KEEP_REFERENCE_EX(return_type, target)
%typemap(ret) return_type %{
    if ($result != Py_None)
        if (PyObject_SetAttrString($result, "_refers_to", target)) {
            SWIG_fail;
        }
%}
%enddef // KEEP_REFERENCE_EX

// Macro to keep a reference to "self" when returning a particular type.
%define KEEP_REFERENCE(return_type)
KEEP_REFERENCE_EX(return_type, self)
%enddef // KEEP_REFERENCE
