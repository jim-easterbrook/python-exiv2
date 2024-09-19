// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "shared/enum.i"
%include "shared/windows_cp.i"

%include "exception.i"

IMPORT_ENUM(ErrorCode)

// Import PyExc_Exiv2Error exception
%fragment("_import_exception_decl", "header") {
static PyObject* PyExc_Exiv2Error = NULL;
}
%fragment("_import_exception", "init", fragment="_import_exception_decl",
          fragment="import_exiv2") {
{
    PyExc_Exiv2Error = PyObject_GetAttrString(exiv2_module, "Exiv2Error");
    if (!PyExc_Exiv2Error)
        return NULL;
}
}

// Function that re-raises an exception to handle different types
%fragment("_set_python_exception", "header",
          fragment="_import_exception",
          fragment="py_from_enum"{Exiv2::ErrorCode},
          fragment="utf8_to_wcp") {
static void _set_python_exception() {
    try {
        throw;
    }
#if EXIV2_VERSION_HEX < 0x001c0000
    catch(Exiv2::AnyError const& e) {
        std::string msg = e.what();
        if (wcp_to_utf8(&msg))
            msg = e.what();
        PyObject* args = Py_BuildValue(
            "Ns", py_from_enum((Exiv2::ErrorCode)e.code()), msg.c_str());
        PyErr_SetObject(PyExc_Exiv2Error, args);
        Py_DECREF(args);
    }
#else
    catch(Exiv2::Error const& e) {
        std::string msg = e.what();
        if (wcp_to_utf8(&msg))
            msg = e.what();
        PyObject* args = Py_BuildValue(
            "Ns", py_from_enum((Exiv2::ErrorCode)e.code()), msg.c_str());
        PyErr_SetObject(PyExc_Exiv2Error, args);
        Py_DECREF(args);
    }
#endif
    SWIG_CATCH_STDEXCEPT
fail:
    return;
};
}

// Macro to define %exception directives
%define EXCEPTION(method)
%fragment("_set_python_exception");
%exception method {
    try {
        $action
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // EXCEPTION
