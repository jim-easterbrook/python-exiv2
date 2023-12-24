// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// If exiv2's wstring methods are available then use them!
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif

// Function to convert utf-8 string to/from current code page
%fragment("transcode_path", "header") %{
#ifdef _WIN32
#include <windows.h>
#endif

static int transcode_path(std::string *path, bool to_cp) {
#ifdef _WIN32
    UINT cp_in = CP_UTF8;
    UINT cp_out = GetACP();
    if (cp_out == cp_in)
        return 0;
    if (!to_cp) {
        cp_in = cp_out;
        cp_out = CP_UTF8;
    }
    // Convert utf-8 path to active code page, via widechar version
    int size = MultiByteToWideChar(cp_in, 0, &(*path)[0], (int)path->size(),
                                   NULL, 0);
    if (!size)
        return -1;
    std::wstring wide_str;
    wide_str.resize(size);
    if (!MultiByteToWideChar(cp_in, 0, &(*path)[0], (int)path->size(),
                             &wide_str[0], size))
        return -1;
    size = WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                               NULL, 0, NULL, NULL);
    if (!size)
        return -1;
    path->resize(size);
    if (!WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                             &(*path)[0], size, NULL, NULL))
        return -1;
#endif
    return 0;
};
%}

// Macro to convert Windows path inputs from utf-8 to current code page
%define WINDOWS_PATH(signature)
#ifndef EXV_UNICODE_PATH
%typemap(check, fragment="transcode_path") signature {
    if (transcode_path($1, true) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode path");
    }
}
#endif
%enddef // WINDOWS_PATH

// Macro to convert Windows path outputs from current code page to utf-8
%define WINDOWS_PATH_OUT(function)
#ifndef EXV_UNICODE_PATH
%typemap(out, fragment="transcode_path") std::string function {
    if (transcode_path(&$1, false) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode result");
    }
    $result = SWIG_From_std_string($1);
}
%typemap(out, fragment="transcode_path") const std::string& function {
    std::string copy = *$1;
    if (transcode_path(&copy, false) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode result");
    }
    $result = SWIG_From_std_string(copy);
}
#endif
%enddef // WINDOWS_PATH_OUT
