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


%include "shared/windows_cp.i"

// Macro to convert Windows path inputs from utf-8 to current code page
%define WINDOWS_PATH(signature)
%typemap(check, fragment="utf8_to_wcp") signature {
%#ifdef _WIN32
    int error = utf8_to_wcp($1);
    if (error) {
        PyErr_SetFromWindowsErr(error);
        SWIG_fail;
    }
%#endif
}
%enddef // WINDOWS_PATH

// Macro to convert Windows path outputs from current code page to utf-8
%define WINDOWS_PATH_OUT(function)
%typemap(out, fragment="utf8_to_wcp") std::string function {
%#ifdef _WIN32
    int error = wcp_to_utf8(&$1);
    if (error) {
        PyErr_SetFromWindowsErr(error);
        SWIG_fail;
    }
%#endif
    $result = SWIG_FromCharPtrAndSize($1.data(), $1.size());
}
%typemap(out, fragment="utf8_to_wcp") const std::string& function {
    std::string copy = *$1;
%#ifdef _WIN32
    int error = wcp_to_utf8(&copy);
    if (error) {
        PyErr_SetFromWindowsErr(error);
        SWIG_fail;
    }
%#endif
    $result = SWIG_FromCharPtrAndSize(copy.data(), copy.size());
}
%enddef // WINDOWS_PATH_OUT
