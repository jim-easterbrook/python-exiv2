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
#pragma SWIG nowarn=325     // Nested struct not currently supported (X ignored)
#pragma SWIG nowarn=403     // Class 'X' might be abstract, no constructors generated, Method Y might not be implemented.

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"
%include "std_vector.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::Value);

STR(Exiv2::Value, toString)

// Macro for subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name)
%feature("docstring") type_name::downCast
    "Convert general 'Exiv2::Value' to specific 'type_name'."
%newobject type_name::downCast;
%extend type_name {
    static type_name* downCast(const Exiv2::Value& value) {
        type_name* pv = dynamic_cast< type_name* >(value.clone().release());
        if (pv == 0)
            throw Exiv2::Error(Exiv2::kerErrorMessage, "Downcast failed");
        return pv;
    }
}
wrap_auto_unique_ptr(type_name)
%enddef

VALUE_SUBCLASS(Exiv2::DataValue)
VALUE_SUBCLASS(Exiv2::DateValue)
VALUE_SUBCLASS(Exiv2::TimeValue)
VALUE_SUBCLASS(Exiv2::StringValueBase)
VALUE_SUBCLASS(Exiv2::AsciiValue)
VALUE_SUBCLASS(Exiv2::CommentValue)
VALUE_SUBCLASS(Exiv2::StringValue)
VALUE_SUBCLASS(Exiv2::XmpValue)
VALUE_SUBCLASS(Exiv2::LangAltValue)
VALUE_SUBCLASS(Exiv2::XmpArrayValue)
VALUE_SUBCLASS(Exiv2::XmpTextValue)

%ignore Exiv2::getValue;
%ignore LARGE_INT;

// Ignore ambiguous or unusable constructors
%ignore Exiv2::ValueType::ValueType(TypeId);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder, TypeId);

%ignore Exiv2::operator<<;
%ignore Exiv2::Value::operator=;

%include "exiv2/value.hpp"

// Macro to apply templates to Exiv2::ValueType
%define VALUETYPE(type_name, T)
VALUE_SUBCLASS(Exiv2::ValueType<T>)
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
