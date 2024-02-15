// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
#endif

static int utf8_to_wcp(std::string *str, bool to_cp) {
#ifdef _WIN32
    UINT cp_in = CP_UTF8;
    UINT cp_out = GetACP();
    if (cp_out == cp_in)
        return 0;
    if (!to_cp) {
        cp_in = cp_out;
        cp_out = CP_UTF8;
    }
    int size = MultiByteToWideChar(cp_in, 0, &(*str)[0], (int)str->size(),
                                   NULL, 0);
    if (!size)
        return -1;
    std::wstring wide_str;
    wide_str.resize(size);
    if (!MultiByteToWideChar(cp_in, 0, &(*str)[0], (int)str->size(),
                             &wide_str[0], size))
        return -1;
    size = WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                               NULL, 0, NULL, NULL);
    if (!size)
        return -1;
    str->resize(size);
    if (!WideCharToMultiByte(cp_out, 0, &wide_str[0], (int)wide_str.size(),
                             &(*str)[0], size, NULL, NULL))
        return -1;
#endif
    return 0;
};
%}
