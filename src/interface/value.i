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

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::Value);

// ---- Typemaps ----
%typemap(out) Exiv2::DateValue::Date %{
    $result = Py_BuildValue("(iii)", $1.year, $1.month, $1.day);
%}
%typemap(out) Exiv2::TimeValue::Time %{
    $result = Py_BuildValue(
        "(iiiii)", $1.hour, $1.minute, $1.second, $1.tzHour, $1.tzMinute);
%}
// for indexing multi-value values, assumes arg1 points to self
%typemap(check) long multi_idx %{
    if ($1 < 0 || $1 >= arg1->count()) {
        PyErr_Format(PyExc_IndexError, "index %d out of range", $1);
        SWIG_fail;
    }
%}
// for indexing single-value values, assumes arg1 points to self
%typemap(check) long single_idx %{
    if ($1 < 0 || $1 >= (arg1->count() ? 1 : 0)) {
        PyErr_Format(PyExc_IndexError, "index %d out of range", $1);
        SWIG_fail;
    }
%}

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%ignore type_name::value_;
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
        PyErr_WarnFormat(PyExc_DeprecationWarning, 1,
            "Replace part_name.downCast(value) with copy constructor "
            "part_name(value).");
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
%enddef // VALUE_SUBCLASS

// Subscript macro for classes that can only hold one value
%define SUBSCRIPT_SINGLE(type_name, item_type, method)
%feature("python:slot", "sq_length", functype="lenfunc") type_name::__len__;
%feature("python:slot", "sq_item",
         functype="ssizeargfunc") type_name::__getitem__;
%extend type_name {
    long __len__() {
        return $self->count() ? 1 : 0;
    }
    item_type __getitem__(long single_idx) {
        return $self->method();
    }
}
%enddef // SUBSCRIPT_SINGLE

// Macro for subclases of Exiv2::ValueType
%define VALUETYPE(type_name, item_type)
VALUE_SUBCLASS(Exiv2::ValueType<item_type>, type_name)
%feature("python:slot", "sq_item",
         functype="ssizeargfunc") Exiv2::ValueType<item_type>::__getitem__;
%feature("python:slot", "sq_ass_item",
         functype="ssizeobjargproc") Exiv2::ValueType<item_type>::__setitem__;
%feature("python:slot", "sq_inplace_concat",
         functype="binaryfunc") Exiv2::ValueType<item_type>::__iadd__;
%extend Exiv2::ValueType<item_type> {
    item_type __getitem__(long multi_idx) {
        return $self->value_.at(multi_idx);
    }
    void __setitem__(long multi_idx, item_type value) {
        $self->value_.at(multi_idx) = value;
    }
#if EXIV2_VERSION_HEX < 0x01000000
    Exiv2::ValueType<item_type>::AutoPtr __iadd__(item_type value) {
#else
    Exiv2::ValueType<item_type>::UniquePtr __iadd__(item_type value) {
#endif
        $self->value_.push_back(value);
        return $self->clone();
    }
}
%template(type_name) Exiv2::ValueType<item_type>;
%enddef // VALUETYPE

// Allow Date and Time to be set from int values
%ignore Exiv2::DateValue::setDate(const Date&);
%extend Exiv2::DateValue {
    void setDate(int year, int month, int day) {
        Exiv2::DateValue::Date date;
        date.year = year;
        date.month = month;
        date.day = day;
        $self->setDate(date);
    }
}
%ignore Exiv2::TimeValue::setTime(const Time&);
%extend Exiv2::TimeValue {
    void setTime(int hour, int minute, int second = 0,
                 int tzHour = 0, int tzMinute = 0) {
        Exiv2::TimeValue::Time time;
        time.hour = hour;
        time.minute = minute;
        time.second = second;
        time.tzHour = tzHour;
        time.tzMinute = tzMinute;
        $self->setTime(time);
    }
}

// Add Python slots to Exiv2::Value base class
%feature("python:slot", "tp_str", functype="reprfunc") Exiv2::Value::__str__;
%feature("python:slot", "sq_length", functype="lenfunc") Exiv2::Value::__len__;
%extend Exiv2::Value {
    std::string __str__() {return $self->toString();}
    long __len__() {return $self->count();}
}

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

SUBSCRIPT_SINGLE(Exiv2::DateValue, Exiv2::DateValue::Date, getDate)
SUBSCRIPT_SINGLE(Exiv2::TimeValue, Exiv2::TimeValue::Time, getTime)
SUBSCRIPT_SINGLE(Exiv2::StringValueBase, std::string, toString)
SUBSCRIPT_SINGLE(Exiv2::XmpTextValue, std::string, toString)

// XmpArrayValue holds multiple values but they're not assignable
%feature("python:slot", "sq_item",
         functype="ssizeargfunc") Exiv2::XmpArrayValue::__getitem__;
%feature("python:slot", "sq_inplace_concat",
         functype="binaryfunc") Exiv2::XmpArrayValue::__iadd__;
%extend Exiv2::XmpArrayValue {
    std::string __getitem__(long multi_idx) {
        return $self->toString(multi_idx);
    }
#if EXIV2_VERSION_HEX < 0x01000000
    Exiv2::XmpArrayValue::AutoPtr __iadd__(std::string value) {
#else
    Exiv2::XmpArrayValue::UniquePtr __iadd__(std::string value) {
#endif
        $self->read(value);
        return $self->clone();
    }
}

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

VALUETYPE(UShortValue, uint16_t)
VALUETYPE(ULongValue, uint32_t)
VALUETYPE(URationalValue, Exiv2::URational)
VALUETYPE(ShortValue, int16_t)
VALUETYPE(LongValue, int32_t)
VALUETYPE(RationalValue, Exiv2::Rational)
VALUETYPE(FloatValue, float)
VALUETYPE(DoubleValue, double)
