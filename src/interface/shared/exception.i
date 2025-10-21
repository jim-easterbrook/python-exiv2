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
%include "shared/python_import.i"
%include "shared/windows.i"

%include "exception.i"

IMPORT_ENUM(_error, ErrorCode)
IMPORT_MODULE_OBJECT(extras, Exiv2Error)

// Exiv2 throws different exception in v0.27
#if EXIV2_VERSION_HEX < 0x001c0000
#define EXV_EXCEPTION Exiv2::AnyError
#else
#define EXV_EXCEPTION Exiv2::Error
#endif

// Function that re-raises an exception to handle different types
%fragment("_set_python_exception", "header",
          fragment="import_module_object"{Exiv2::Exiv2Error},
          fragment="py_from_enum",
          fragment="import_enum"{Exiv2::ErrorCode},
          fragment="utf8_to_wcp") {
static void _set_python_exception() {
    try {
        throw;
    }
    catch(EXV_EXCEPTION const& e) {
        std::string msg = e.what();
        if (wcp_to_utf8(&msg))
            msg = e.what();
        PyObject* args = Py_BuildValue(
            "Ns", py_from_enum(Python_%mangle(Exiv2::ErrorCode),
            static_cast<long>(e.code())), msg.c_str());
        PyErr_SetObject(Python_%mangle(Exiv2::Exiv2Error), args);
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

// Macros to deprecate a function
%define DEPRECATE(method, message)
%fragment("_set_python_exception");
%exception method {
PyErr_WarnEx(PyExc_DeprecationWarning, message, 1);
    try {
        $action
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // DEPRECATE

%define DEPRECATE_FUNCTION(method, preserve_doc)
DEPRECATE(method, "Python scripts should not need to call " #method)
#if #preserve_doc == "" 
%feature("docstring") method "Deprecated."
#endif
%enddef // DEPRECATE_FUNCTION

%define EXIV2_DEPRECATED(method)
DEPRECATE(method, #method " is deprecated in libexiv2")
%enddef // EXIV2_DEPRECATED

// Macro to not call a function if EXV_ENABLE_FILESYSTEM is OFF
%define EXV_ENABLE_FILESYSTEM_FUNCTION(signature)
%fragment("_set_python_exception");
%fragment("set_EXV_ENABLE_FILESYSTEM");
%exception signature {
    try {
%#ifdef EXV_ENABLE_FILESYSTEM
        $action
%#else
        throw Exiv2::Error(Exiv2::ErrorCode::kerFunctionNotSupported);
%#endif
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // EXV_ENABLE_FILESYSTEM_FUNCTION
