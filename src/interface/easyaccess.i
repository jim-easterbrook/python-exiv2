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

%define WRAP(function)
%rename(function) deref_ ## function;
%ignore Exiv2::function;
%inline %{
const Exiv2::Exifdatum* deref_ ## function(const Exiv2::ExifData& ed) {
    Exiv2::ExifData::const_iterator result = Exiv2::function(ed);
    if (result == ed.end()) {
        return NULL;
    }
    return &(*result);
}
%}
%enddef

%typemap(out) const Exiv2::Exifdatum* %{
    $result = $1 ? SWIG_NewPointerObj(SWIG_as_voidptr($1),
                                      $1_descriptor, 0) : SWIG_Py_Void();
%}

WRAP(orientation)
WRAP(isoSpeed)
WRAP(flashBias)
WRAP(exposureMode)
WRAP(sceneMode)
WRAP(macroMode)
WRAP(imageQuality)
WRAP(whiteBalance)
WRAP(lensName)
WRAP(saturation)
WRAP(sharpness)
WRAP(contrast)
WRAP(sceneCaptureType)
WRAP(meteringMode)
WRAP(make)
WRAP(model)
WRAP(exposureTime)
WRAP(fNumber)
WRAP(subjectDistance)
WRAP(serialNumber)
WRAP(focalLength)
WRAP(afPoint)

// Ignore functions introduced in libexiv2 0.27.4
%ignore Exiv2::dateTimeOriginal;
%ignore Exiv2::shutterSpeedValue;
%ignore Exiv2::apertureValue;
%ignore Exiv2::brightnessValue;
%ignore Exiv2::exposureBiasValue;
%ignore Exiv2::maxApertureValue;
%ignore Exiv2::lightSource;
%ignore Exiv2::flash;
%ignore Exiv2::subjectArea;
%ignore Exiv2::flashEnergy;
%ignore Exiv2::exposureIndex;
%ignore Exiv2::sensingMethod;

%include "exiv2/easyaccess.hpp"
