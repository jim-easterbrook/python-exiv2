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
%constant char* __doc__ = "Exiv2 error codes and message logging.";
#endif

%include "shared/preamble.i"
%include "shared/python_import.i"

%include "std_except.i"


// Add enum table to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. rubric:: Enums

.. autosummary::

    ErrorCode

.. rubric:: Module Attributes

.. autosummary::

    pythonHandler
'''
%}

// Import logger from extras.py
IMPORT_PYTHON_OBJECT(exiv2.extras, logger, logger)
%fragment("import_python_object"{logger});

// Set Python logger as Exiv2 log handler
%fragment("utf8_to_wcp");
%{
static void log_to_python(int level, const char* msg) {
    std::string copy = msg;
    if (wcp_to_utf8(&copy))
        copy = msg;
    Py_ssize_t len = copy.size();
    while (len > 0 && copy[len-1] == '\n')
        len--;
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* res = PyObject_CallMethod(
        Python_logger, "log", "(is#)", (level + 1) * 10, copy.data(), len);
    Py_XDECREF(res);
    PyGILState_Release(gstate);
};
%}
%init %{
Exiv2::LogMsg::setHandler(&log_to_python);
%}

// Replace LogMsg docs with something more relevant to Python
%feature("docstring") Exiv2::LogMsg
"Static class to control logging.

Applications can set the log level and change the log message handler.

The default handler :attr:`pythonHandler` sends messages to Python's
:mod:`logging` system. Exiv2's handler :attr:`defaultHandler` sends
messages to standard error. To change handler pass
:attr:`exiv2.pythonHandler<pythonHandler>` or
:attr:`exiv2.LogMsg.defaultHandler<defaultHandler>` to
:meth:`setHandler`.

To disable logging entirely pass :obj:`None` to :meth:`setHandler`."

// Provide Python logger as attribute of module
%constant Exiv2::LogMsg::Handler pythonHandler = &log_to_python;

// Provide default logger as attribute of LogMsg
%extend Exiv2::LogMsg {
    static const Exiv2::LogMsg::Handler defaultHandler;
}
// Adding static class attribute creates cvar and a getter function.
// Hide them from the user interface.
%pythoncode %{
if __package__ or "." in __name__:
    from ._error import __all__
else:
    from _error import __all__
__all__.remove('LogMsg_defaultHandler_get')
__all__.remove('cvar')
%}

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

#ifndef SWIGIMPORTED
DEFINE_CLASS_ENUM(LogMsg, Level,)
#else
IMPORT_CLASS_ENUM(_error, LogMsg, Level)
#endif

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
#ifndef SWIGIMPORTED
DEFINE_ENUM(ErrorCode,)
#else
IMPORT_ENUM(_error, ErrorCode)
#endif

%include "exiv2/error.hpp"
