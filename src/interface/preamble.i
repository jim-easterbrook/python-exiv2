// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

// EXIV2API prepends every function declaration
#define EXIV2API
// Older versions of libexiv2 define these as well
#define EXV_DLLLOCAL
#define EXV_DLLPUBLIC

#ifndef SWIG_DOXYGEN
%feature("autodoc", "2");
#endif

// Get exception defined in __init__.py
%{
static PyObject* PyExc_Exiv2Error = NULL;
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("exiv2");
    if (module) {
        PyExc_Exiv2Error = PyObject_GetAttrString(module, "Exiv2Error");
        Py_DECREF(module);
    }
    if (!PyExc_Exiv2Error)
        return NULL;
}
%}

// Macro to define %exception directives
%define EXCEPTION(method, precheck)
%exception method {
precheck
    try {
        $action
#if EXIV2_VERSION_HEX < 0x001c0000
    } catch(Exiv2::AnyError const& e) {
#else
    } catch(Exiv2::Error const& e) {
#endif
        PyErr_SetString(PyExc_Exiv2Error, e.what());
        SWIG_fail;
    } catch(std::exception const& e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
        SWIG_fail;
    }
}
%enddef // EXCEPTION

// Catch all C++ exceptions
EXCEPTION(,)
