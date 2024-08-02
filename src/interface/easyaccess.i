// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Simplified reading of Exif metadata.";
#endif

%include "shared/preamble.i"
%include "shared/exception.i"
%include "shared/exv_options.i"

// Catch all C++ exceptions
EXCEPTION()

EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::apertureValue)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::brightnessValue)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::dateTimeOriginal)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::exposureBiasValue)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::exposureIndex)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::flash)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::flashEnergy)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::lightSource)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::maxApertureValue)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::sensingMethod)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::shutterSpeedValue)
EXV_ENABLE_EASYACCESS_FUNCTION(Exiv2::subjectArea)

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
