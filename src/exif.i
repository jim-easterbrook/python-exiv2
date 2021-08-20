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

%module(package="exiv2") exif

#pragma SWIG nowarn=362     // operator= ignored
#pragma SWIG nowarn=389     // operator[] ignored (consider using %extend)

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "metadatum.i"
%import "tags.i"

GETITEM(Exiv2::ExifData, Exiv2::Exifdatum)
ITERATOR(Exiv2::ExifData, Exiv2::Exifdatum, ExifDataIterator)

%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") Exiv2::ExifData::__setitem__;

%extend Exiv2::ExifData {
    PyObject* __setitem__(const std::string& key, const Exiv2::Exifdatum &rhs) {
        using namespace Exiv2;
        TypeId type_id = ExifKey(key).defaultTypeId();
        if (type_id != rhs.typeId()) {
            EXV_WARNING << key << ": type change from '" <<
                TypeInfo::typeName(type_id) << "' to '" <<
                rhs.typeName() << "'.\n";
        }
        (*($self))[key] = rhs;
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const Exiv2::Value &value) {
        using namespace Exiv2;
        TypeId type_id = ExifKey(key).defaultTypeId();
        if (type_id != value.typeId()) {
            EXV_WARNING << key << ": type change from '" <<
                TypeInfo::typeName(type_id) << "' to '" <<
                TypeInfo::typeName(value.typeId()) << "'.\n";
        }
        (*($self))[key] = value;
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string &value) {
        (*($self))[key] = value;
        return SWIG_Py_Void();
    }
}

%ignore Exiv2::ExifData::begin() const;
%ignore Exiv2::ExifData::end() const;
%ignore Exiv2::ExifData::findKey(ExifKey const &) const;
%ignore Exiv2::Exifdatum::dataArea;
%ignore Exiv2::ExifThumbC::copy;

%include "exiv2/exif.hpp"
