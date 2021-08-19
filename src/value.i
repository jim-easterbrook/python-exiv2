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

#pragma SWIG nowarn=325     // Nested struct not currently supported (X ignored)
#pragma SWIG nowarn=362     // operator= ignored
#pragma SWIG nowarn=403     // Class 'X' might be abstract, no constructors generated, Method Y might not be implemented.

%include "preamble.i"

%import "types.i"

%include "stdint.i"
%include "std_auto_ptr.i"
%include "std_string.i"
%include "std_vector.i"

%auto_ptr(Exiv2::AsciiValue)
%auto_ptr(Exiv2::CommentValue)
%auto_ptr(Exiv2::DataValue)
%auto_ptr(Exiv2::DateValue)
%auto_ptr(Exiv2::LangAltValue)
%auto_ptr(Exiv2::StringValue)
%auto_ptr(Exiv2::StringValueBase)
%auto_ptr(Exiv2::TimeValue)
%auto_ptr(Exiv2::Value)
%auto_ptr(Exiv2::XmpArrayValue)
%auto_ptr(Exiv2::XmpTextValue)

STR(Exiv2::Value, toString)

%ignore Exiv2::getValue;
%ignore Exiv2::Value::dataArea;
%ignore Exiv2::ValueType::clone;

// Ignore ambiguous or unusable constructors
%ignore Exiv2::ValueType::ValueType(TypeId);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder);
%ignore Exiv2::ValueType::ValueType(const byte*, long, ByteOrder, TypeId);

%include "exiv2/value.hpp"

%template(UShortValueList) std::vector<uint16_t>;
%template(ULongValueList) std::vector<uint32_t>;
%template(URationalValueList) std::vector<Exiv2::URational>;
%template(ShortValueList) std::vector<int16_t>;
%template(LongValueList) std::vector<int32_t>;
%template(RationalValueList) std::vector<Exiv2::Rational>;
%template(FloatValueList) std::vector<float>;
%template(DoubleValueList) std::vector<double>;

%template(UShortValue) Exiv2::ValueType<uint16_t>;
%template(ULongValue) Exiv2::ValueType<uint32_t>;
%template(URationalValue) Exiv2::ValueType<Exiv2::URational>;
%template(ShortValue) Exiv2::ValueType<int16_t>;
%template(LongValue) Exiv2::ValueType<int32_t>;
%template(RationalValue) Exiv2::ValueType<Exiv2::Rational>;
%template(FloatValue) Exiv2::ValueType<float>;
%template(DoubleValue) Exiv2::ValueType<double>;
