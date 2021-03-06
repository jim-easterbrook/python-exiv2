// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "preamble.i"

%include "std_except.i"

#ifdef EXV_ENABLE_NLS
// Make all exiv2's localised strings UTF-8
%{
#include "libintl.h"
%}
%init %{
bind_textdomain_codeset("exiv2", "UTF-8");
%}
#endif


// Set Python logger as Exiv2 log handler
%{
static void log_to_python(int level, const char* msg) {
    Py_ssize_t len = strlen(msg);
    while (len > 0 && msg[len-1] == '\n')
        len--;
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* res = PyObject_CallMethod(
        logger, "log", "(is#)", (level + 1) * 10, msg, len);
    Py_XDECREF(res);
    PyGILState_Release(gstate);
};
%}
%init %{
Exiv2::LogMsg::setHandler(&log_to_python);
%}


// Ignore anything that's unusable from Python
%ignore Exiv2::AnyError;
%ignore Exiv2::Error;
%ignore Exiv2::WError;
%ignore Exiv2::errMsg;
%ignore Exiv2::ErrorCode;
%ignore Exiv2::LogMsg::LogMsg;
%ignore Exiv2::LogMsg::~LogMsg;
%ignore Exiv2::LogMsg::os;
%ignore Exiv2::LogMsg::handler;
%ignore Exiv2::LogMsg::setHandler;
%ignore Exiv2::LogMsg::defaultHandler;
%ignore Exiv2::operator<<;

%include "exiv2/error.hpp"
