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

%module(package="exiv2") error

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 error codes and log messages.";
#endif

%include "shared/preamble.i"

%include "std_except.i"


// Import Exiv2Error from exiv2 module
%fragment("import_exiv2");
%constant PyObject* Exiv2Error = PyObject_GetAttrString(
    exiv2_module, "Exiv2Error");

// Set Python logger as Exiv2 log handler
%fragment("utf8_to_wcp");
%{
static PyObject* logger = NULL;
static void log_to_python(int level, const char* msg) {
    std::string copy = msg;
    if (wcp_to_utf8(&copy))
        copy = msg;
    Py_ssize_t len = copy.size();
    while (len > 0 && copy[len-1] == '\n')
        len--;
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* res = PyObject_CallMethod(
        logger, "log", "(is#)", (level + 1) * 10, copy.data(), len);
    Py_XDECREF(res);
    PyGILState_Release(gstate);
};
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("logging");
    if (!module)
        return INIT_ERROR_RETURN;
    logger = PyObject_CallMethod(module, "getLogger", "(s)", "exiv2");
    Py_DECREF(module);
    if (!logger) {
        PyErr_SetString(PyExc_RuntimeError, "logging.getLogger failed.");
        return INIT_ERROR_RETURN;
    }
    Exiv2::LogMsg::setHandler(&log_to_python);
}
%}

// Provide Python logger and default logger as attributes of LogMsg
%extend Exiv2::LogMsg {
%constant PyObject* pythonHandler = SWIG_NewFunctionPtrObj(
    (void*)log_to_python, SWIGTYPE_p_f_int_p_q_const__char__void);
%constant PyObject* defaultHandler = SWIG_NewFunctionPtrObj(
    (void*)Exiv2::LogMsg::defaultHandler,
    SWIGTYPE_p_f_int_p_q_const__char__void);
}

// Ignore anything that's unusable from Python
%ignore Exiv2::AnyError;
%ignore Exiv2::Error;
%ignore Exiv2::WError;
%ignore Exiv2::errMsg;
%ignore Exiv2::LogMsg::LogMsg;
%ignore Exiv2::LogMsg::~LogMsg;
%ignore Exiv2::LogMsg::os;
%ignore Exiv2::LogMsg::defaultHandler;
%ignore Exiv2::operator<<;

NEW_DEFINE_CLASS_ENUM(LogMsg, Level,)

#if EXIV2_VERSION_HEX < 0x001c0000
%{
// kerInvalidLangAltValue added to ErrorCode in v0.27.4
#if !EXIV2_TEST_VERSION(0,27,4)
#define kerInvalidLangAltValue kerGeneralError
#endif // EXIV2_TEST_VERSION
%}
#else
%{
// kerFileAccessDisabled added to ErrorCode in v0.28.4
#if !EXIV2_TEST_VERSION(0,28,4)
#define kerFileAccessDisabled kerGeneralError
#endif // EXIV2_TEST_VERSION
%}
#endif
NEW_DEFINE_ENUM(ErrorCode,)

%include "exiv2/error.hpp"
