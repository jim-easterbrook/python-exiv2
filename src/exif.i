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
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        if (type_id == rhs.typeId()) {
            (*($self))[key] = rhs;
            return SWIG_Py_Void();
        }
        msg = key + ": cannot convert '" + rhs.typeName();
        msg += "' to '" + std::string(Exiv2::TypeInfo::typeName(type_id));
        msg += "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const Exiv2::Value &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        if (type_id == value.typeId()) {
            (*($self))[key] = value;
            return SWIG_Py_Void();
        }
        msg = key + ": cannot convert '";
        msg += std::string(Exiv2::TypeInfo::typeName(value.typeId()));
        msg += "' to '" + std::string(Exiv2::TypeInfo::typeName(type_id));
        msg += "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const uint32_t &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        switch (type_id) {
            case Exiv2::unsignedRational:
                (*($self))[key] = Exiv2::URational(value, 1);
                return SWIG_Py_Void();
            case Exiv2::signedRational:
                if (value <= INT32_MAX) {
                    (*($self))[key] = Exiv2::Rational(value, 1);
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::unsignedLong:
                (*($self))[key] = (uint32_t)value;
                return SWIG_Py_Void();
            case Exiv2::signedLong:
                if (value <= INT32_MAX) {
                    (*($self))[key] = (int32_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::unsignedShort:
                if (value <= UINT16_MAX) {
                    (*($self))[key] = (uint16_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::signedShort:
                if (value <= INT16_MAX) {
                    (*($self))[key] = (int16_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::unsignedByte:
            case Exiv2::undefined:
                if (value <= UINT8_MAX) {
                    (*($self))[key] = (uint8_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::signedByte:
                if (value <= INT8_MAX) {
                    (*($self))[key] = (int8_t)value;
                    return SWIG_Py_Void();
                }
                break;
            default:
                msg = key + ": cannot convert 'unsigned int' to '";
                msg += std::string(Exiv2::TypeInfo::typeName(type_id));
                msg += "'.";
                PyErr_SetString(PyExc_ValueError, msg.c_str());
                return NULL;
        }
        msg = key + ": value out of range for '";
        msg += std::string(Exiv2::TypeInfo::typeName(type_id));
        msg += "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const int32_t &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        switch (type_id) {
            case Exiv2::signedRational:
                (*($self))[key] = Exiv2::Rational(value, 1);
                return SWIG_Py_Void();
            case Exiv2::unsignedRational:
                if (value >= 0) {
                    (*($self))[key] = Exiv2::URational(value, 1);
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::signedLong:
                (*($self))[key] = (int32_t)value;
                return SWIG_Py_Void();
            case Exiv2::unsignedLong:
                if (value >= 0) {
                    (*($self))[key] = (uint32_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::signedShort:
                if (value >= INT16_MIN && value <= INT16_MAX) {
                    (*($self))[key] = (int16_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::unsignedShort:
                if (value >= 0 && value <= UINT16_MAX) {
                    (*($self))[key] = (uint16_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::signedByte:
                if (value >= INT8_MIN && value <= INT8_MAX) {
                    (*($self))[key] = (int8_t)value;
                    return SWIG_Py_Void();
                }
                break;
            case Exiv2::unsignedByte:
                if (value >= 0 && value <= UINT8_MAX) {
                    (*($self))[key] = (uint8_t)value;
                    return SWIG_Py_Void();
                }
                break;
            default:
                msg = key + ": cannot convert 'int' to '";
                msg += std::string(Exiv2::TypeInfo::typeName(type_id));
                msg += "'.";
                PyErr_SetString(PyExc_ValueError, msg.c_str());
                return NULL;
        }
        msg = key + ": value out of range for '";
        msg += std::string(Exiv2::TypeInfo::typeName(type_id));
        msg += "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const Exiv2::Rational &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        if (type_id == Exiv2::signedRational) {
            (*($self))[key] = value;
            return SWIG_Py_Void();
        }
        msg = key + ": cannot convert 'Rational' to '";
        if (type_id == Exiv2::unsignedRational)
            msg += "URational";
        else
            msg += std::string(Exiv2::TypeInfo::typeName(type_id));
        msg += "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const Exiv2::URational &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        switch (type_id) {
            case Exiv2::signedRational:
                (*($self))[key] = Exiv2::Rational(value);
                return SWIG_Py_Void();
            case Exiv2::unsignedRational:
                (*($self))[key] = value;
                return SWIG_Py_Void();
            default:
                break;
        }
        msg = key + ": cannot convert 'URational' to '";
        msg += std::string(Exiv2::TypeInfo::typeName(type_id)) + "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const std::string &value) {
        std::string msg;
        Exiv2::TypeId type_id = Exiv2::ExifKey(key).defaultTypeId();
        if (type_id == Exiv2::asciiString) {
            (*($self))[key] = value;
            return SWIG_Py_Void();
        }
        msg = key + ": cannot convert 'str' to '";
        msg += std::string(Exiv2::TypeInfo::typeName(type_id)) + "'.";
        PyErr_SetString(PyExc_ValueError, msg.c_str());
        return NULL;
    }
}

%ignore Exiv2::ExifData::begin() const;
%ignore Exiv2::ExifData::end() const;
%ignore Exiv2::ExifData::findKey(ExifKey const &) const;
%ignore Exiv2::Exifdatum::dataArea;
%ignore Exiv2::ExifThumbC::copy;

%include "exiv2/exif.hpp"
