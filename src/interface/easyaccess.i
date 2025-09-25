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

%module(package="exiv2") easyaccess

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Simplified reading of Exif metadata.";
#endif

%include "shared/preamble.i"

// Catch all C++ exceptions
EXCEPTION()

// Macro to not call a function if libexiv2 version is <= 0.27.3
%define EXV_ENABLE_EASYACCESS_FUNCTION(signature)
%fragment("_set_python_exception");
%exception signature {
    try {
%#if EXIV2_TEST_VERSION(0, 27, 4)
        $action
%#else
        throw Exiv2::Error(Exiv2::kerFunctionNotSupported);
%#endif
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // EXV_ENABLE_EASYACCESS_FUNCTION

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

// Convert result from iterator to datum or None
%typemap(out) Exiv2::ExifData::const_iterator %{
    if ($1 == arg1->end())
        $result = SWIG_Py_Void();
    else
        $result = SWIG_NewPointerObj(
            SWIG_as_voidptr(&(*$1)), $descriptor(Exiv2::Exifdatum*), 0);
%}

// Development version of exiv2 removes class declaration inside namespace
#if EXIV2_VERSION_HEX >= 0x001d0000
#define ExifData Exiv2::ExifData
#endif

%include "exiv2/easyaccess.hpp"
