// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
%include "shared/windows.i"

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
    if (!PyExc_Exiv2Error) {
        PyErr_SetString(PyExc_RuntimeError,
                        "Import error: exiv2.Exiv2Error not found.");
        return INIT_ERROR_RETURN;
    }
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
#else
    catch(Exiv2::Error const& e) {
#endif
        std::string msg = e.what();
        if (wcp_to_utf8(&msg))
            msg = e.what();
        PyObject* args = Py_BuildValue(
            "Ns", py_from_enum_%mangle(Exiv2::ErrorCode)
            (static_cast<long>(e.code())), msg.c_str());
        PyErr_SetObject(PyExc_Exiv2Error, args);
        Py_DECREF(args);
    }
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

// Macro to deprecate a function
%define DEPRECATE_FUNCTION(method, message)
%fragment("_set_python_exception");
%feature("docstring") method "Deprecated."
%exception method {
#if #message != ""
    PyErr_WarnEx(PyExc_DeprecationWarning, message, 1);
#else
    PyErr_WarnEx(PyExc_DeprecationWarning,
                 "Python scripts should not need to call " #method, 1);
#endif
    try {
        $action
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // DEPRECATE_FUNCTION
