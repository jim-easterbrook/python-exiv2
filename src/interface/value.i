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

%module(package="exiv2") value

#pragma SWIG nowarn=305     // Bad constant value (ignored).

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"
%include "std_vector.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::Value);

STR(Exiv2::Value, toString)

// Macro for subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%feature("docstring") type_name::downCast
    "Convert general 'Exiv2::Value' to specific 'type_name'."
%newobject type_name::downCast;
%extend type_name {
    static type_name* downCast(const Exiv2::Value& value) {
        type_name* pv = dynamic_cast< type_name* >(value.clone().release());
        if (pv == 0) {
            std::string msg = "Cannot cast type '";
            msg += Exiv2::TypeInfo::typeName(value.typeId());
            msg += "' to type_name.";
            throw Exiv2::Error(Exiv2::kerErrorMessage, msg);
        }
        return pv;
    }
    part_name(const Exiv2::Value& value) {
        type_name* pv = dynamic_cast< type_name* >(value.clone().release());
        if (pv == 0) {
            std::string msg = "Cannot cast type '";
            msg += Exiv2::TypeInfo::typeName(value.typeId());
            msg += "' to type '";
            msg += Exiv2::TypeInfo::typeName(type_name().typeId());
            msg += "'.";
            throw Exiv2::Error(Exiv2::kerErrorMessage, msg);
        }
        return pv;
    }
}
wrap_auto_unique_ptr(type_name)
%enddef

VALUE_SUBCLASS(Exiv2::DataValue, DataValue)
VALUE_SUBCLASS(Exiv2::DateValue, DateValue)
VALUE_SUBCLASS(Exiv2::TimeValue, TimeValue)
VALUE_SUBCLASS(Exiv2::StringValueBase, StringValueBase)
VALUE_SUBCLASS(Exiv2::AsciiValue, AsciiValue)
VALUE_SUBCLASS(Exiv2::CommentValue, CommentValue)
VALUE_SUBCLASS(Exiv2::StringValue, StringValue)
VALUE_SUBCLASS(Exiv2::XmpValue, XmpValue)
VALUE_SUBCLASS(Exiv2::LangAltValue, LangAltValue)
VALUE_SUBCLASS(Exiv2::XmpArrayValue, XmpArrayValue)
VALUE_SUBCLASS(Exiv2::XmpTextValue, XmpTextValue)

%ignore Exiv2::getValue;
%ignore LARGE_INT;

// Some classes wrongly appear to be abstract to SWIG
%feature("notabstract") Exiv2::LangAltValue;
%feature("notabstract") Exiv2::XmpArrayValue;
%feature("notabstract") Exiv2::XmpTextValue;

// Ignore ambiguous or unusable constructors
%ignore Exiv2::ValueType::ValueType(TypeId);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder, TypeId);

// Ignore stuff Python can't use or SWIG can't handle
%ignore Exiv2::operator<<;
%ignore Exiv2::Value::operator=;
%ignore Exiv2::CommentValue::CharsetInfo;
%ignore Exiv2::CommentValue::CharsetTable;
%ignore Exiv2::DateValue::Date;
%ignore Exiv2::TimeValue::Time;

%include "exiv2/value.hpp"

// Macro to apply templates to Exiv2::ValueType
%define VALUETYPE(type_name, T)
VALUE_SUBCLASS(Exiv2::ValueType<T>, type_name)
%template(type_name) Exiv2::ValueType<T>;
%template(type_name ## List) std::vector<T>;
%enddef

VALUETYPE(UShortValue, uint16_t)
VALUETYPE(ULongValue, uint32_t)
VALUETYPE(URationalValue, Exiv2::URational)
VALUETYPE(ShortValue, int16_t)
VALUETYPE(LongValue, int32_t)
VALUETYPE(RationalValue, Exiv2::Rational)
VALUETYPE(FloatValue, float)
VALUETYPE(DoubleValue, double)
