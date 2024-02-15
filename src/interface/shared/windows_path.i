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

// If exiv2's wstring methods are available then use them!
#ifdef EXV_UNICODE_PATH
%include "std_wstring.i"
#endif

// Macro to convert Windows path inputs from utf-8 to current code page
%define WINDOWS_PATH(signature)
#ifndef EXV_UNICODE_PATH
%typemap(check, fragment="utf8_to_wcp") signature {
    if (utf8_to_wcp($1, true) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode path");
    }
}
#endif
%enddef // WINDOWS_PATH

// Macro to convert Windows path outputs from current code page to utf-8
%define WINDOWS_PATH_OUT(function)
#ifndef EXV_UNICODE_PATH
%typemap(out, fragment="utf8_to_wcp") std::string function {
    if (utf8_to_wcp(&$1, false) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode result");
    }
    $result = SWIG_From_std_string($1);
}
%typemap(out, fragment="utf8_to_wcp") const std::string& function {
    std::string copy = *$1;
    if (utf8_to_wcp(&copy, false) < 0) {
        SWIG_exception_fail(SWIG_ValueError, "failed to transcode result");
    }
    $result = SWIG_From_std_string(copy);
}
#endif
%enddef // WINDOWS_PATH_OUT
