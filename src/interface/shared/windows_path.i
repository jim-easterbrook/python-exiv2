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

// Function to convert utf-8 string to current code page
%fragment("transcode_path", "header") {
static void transcode_path(std::string *path) {
%#ifdef _WIN32
    UINT acp = GetACP();
    if (acp == CP_UTF8)
        return;
    // Convert utf-8 path to active code page, via widechar version
    int wide_len = MultiByteToWideChar(CP_UTF8, 0, &(*path)[0], -1, NULL, 0);
    std::wstring wide_str;
    wide_str.resize(wide_len);
    if (MultiByteToWideChar(CP_UTF8, 0, &(*path)[0], -1,
                            &wide_str[0], (int)wide_str.size()) >= 0) {
        int new_len = WideCharToMultiByte(acp, 0, &wide_str[0], -1,
                                          NULL, 0, NULL, NULL);
        path->resize(new_len);
        WideCharToMultiByte(acp, 0, &wide_str[0], -1,
                            &(*path)[0], (int)path->size(), NULL, NULL);
    }
%#endif
};
}

// Macro to convert Windows paths from utf-8 to current code page
%define WINDOWS_PATH(signature)
#ifndef EXV_UNICODE_PATH
%typemap(check, fragment="transcode_path") signature {
    transcode_path($1);
}
#endif
%enddef // WINDOWS_PATH
