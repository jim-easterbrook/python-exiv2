// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") easyaccess

%include "preamble.i"

#ifndef SWIGIMPORTED
// Get definition of ExifDataWrap so functions can be passed
// either ExifDataWrap or Exiv2::ExifData
DATA_WRAPPER_DEC(ExifData, Exiv2::ExifData, Exiv2::Exifdatum, Exiv2::ExifKey)
#endif

// Store data.end() after converting input
%typemap(check) Exiv2::ExifData& (Exiv2::ExifData::const_iterator _global_end) %{
    _global_end = $1->end();
%}

// Convert result from iterator to datum or None
%typemap(out) Exiv2::ExifData::const_iterator %{
    if ($1 == _global_end)
        $result = SWIG_Py_Void();
    else
        $result = SWIG_NewPointerObj(
            SWIG_as_voidptr(&(*$1)), $descriptor(Exiv2::Exifdatum*), 0);
%}

%include "exiv2/easyaccess.hpp"
