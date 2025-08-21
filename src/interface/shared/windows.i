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


// Function to convert utf-8 string to/from current Windows code page
%fragment("utf8_to_wcp", "header") %{
#ifdef _WIN32
#include <windows.h>

static int _transcode(std::string *str, UINT cp_in, UINT cp_out) {
    if (cp_out == cp_in)
        return 0;
    int size = MultiByteToWideChar(cp_in, 0, &(*str)[0], (int)str->size(),
                                   NULL, 0);
    if (!size)
        return GetLastError();
    std::wstring wide_str;
    wide_str.resize(size);
    if (!MultiByteToWideChar(cp_in, 0, &(*str)[0], (int)str->size(),
                             &wide_str[0], size))
        return GetLastError();
    size = WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                               NULL, 0, NULL, NULL);
    if (!size)
        return GetLastError();
    str->resize(size);
    if (!WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                             &(*str)[0], size, NULL, NULL))
        return GetLastError();
    return 0;
};
#endif

static int utf8_to_wcp(std::string *str) {
#ifdef _WIN32
    return _transcode(str, CP_UTF8, GetACP());
#else
    return 0;
#endif
};

static int wcp_to_utf8(std::string *str) {
#ifdef _WIN32
    return _transcode(str, GetACP(), CP_UTF8);
#else
    return 0;
#endif
};
%}

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
    $typemap(out, std::string)
}
%typemap(out, fragment="utf8_to_wcp") const std::string& function {
%#ifdef _WIN32
    std::string copy = *$1;
    int error = wcp_to_utf8(&copy);
    if (error) {
        PyErr_SetFromWindowsErr(error);
        SWIG_fail;
    }
    $1 = &copy;
%#endif
    $typemap(out, const std::string&)
}
%enddef // WINDOWS_PATH_OUT
