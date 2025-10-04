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

%module(package="exiv2") value
%feature("flatnested", "1");

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 metadata value classes.";
#endif

// We don't need Python access to SwigPyIterator
%ignore SwigPyIterator;

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/keep_reference.i"
%include "shared/private_data.i"
%include "shared/slots.i"
%include "shared/struct_dict.i"

%include "stdint.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"
%include "typemaps.i"

%import "types.i"

// Add inheritance diagrams to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.value.Value
    :top-classes: exiv2.value.Value
    :parts: 1
    :include-subclasses:
'''
%}

// Catch all C++ exceptions
EXCEPTION()

UNIQUE_PTR(Exiv2::Value);

// Keep a reference to any object that returns a reference to a value.
KEEP_REFERENCE(const Exiv2::Value&)

// Remove exception handler for some methods known to be safe
%noexception Exiv2::Value::~Value;
%noexception Exiv2::Value::count;
%noexception Exiv2::Value::ok;
%noexception Exiv2::Value::size;
%noexception Exiv2::Value::typeId;
%noexception Exiv2::XmpValue::setXmpArrayType;
%noexception Exiv2::XmpValue::setXmpStruct;
%noexception Exiv2::XmpValue::xmpArrayType;
%noexception Exiv2::XmpValue::xmpStruct;

// ---- Typemaps ----
// Convert std::ostream inputs and outputs
%typemap(in) std::ostream& os (PyObject* _global_io, std::ostringstream temp) {
    $1 = &temp;
    _global_io = $input;
}
%typemap(out) std::ostream& {
    PyObject* OK = PyObject_CallMethod(_global_io, "write", "(s)",
        static_cast< std::ostringstream* >($1)->str().c_str());
    if (!OK)
        SWIG_fail;
    Py_DECREF(OK);
    Py_INCREF(_global_io);
    $result = _global_io;
}

// for indexing multi-value values, assumes arg1 points to self
%typemap(check) (size_t idx), (long n) %{
    if ($1 < 0 || $1 >= static_cast< $1_ltype >(arg1->count())) {
        PyErr_Format(PyExc_IndexError, "index %d out of range", $1);
        SWIG_fail;
    }
%}
// for indexing single-value values, assumes arg1 points to self
%typemap(check) size_t single_idx %{
    if ($1 < 0 || $1 >= (arg1->count() ? 1 : 0)) {
        PyErr_Format(PyExc_IndexError, "index %d out of range", $1);
        SWIG_fail;
    }
%}
// DataValue constructor and DataValue::read can take a Python buffer
INPUT_BUFFER_RO(const Exiv2::byte* buf, BUFLEN_T len)

// Value::copy can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf,)

// Downcast base class pointers to derived class
// Convert exiv2 type id to the appropriate value class type info
%fragment("_type_map_init", "init") {
_type_object = {
    {Exiv2::asciiString,    $descriptor(Exiv2::AsciiValue*)},
    {Exiv2::unsignedShort,  $descriptor(Exiv2::ValueType<uint16_t>*)},
    {Exiv2::unsignedLong,   $descriptor(Exiv2::ValueType<uint32_t>*)},
    {Exiv2::unsignedRational,
        $descriptor(Exiv2::ValueType<Exiv2::URational>*)},
    {Exiv2::signedShort,    $descriptor(Exiv2::ValueType<int16_t>*)},
    {Exiv2::signedLong,     $descriptor(Exiv2::ValueType<int32_t>*)},
    {Exiv2::signedRational, $descriptor(Exiv2::ValueType<Exiv2::Rational>*)},
    {Exiv2::tiffFloat,      $descriptor(Exiv2::ValueType<float>*)},
    {Exiv2::tiffDouble,     $descriptor(Exiv2::ValueType<double>*)},
    {Exiv2::tiffIfd,        $descriptor(Exiv2::ValueType<uint32_t>*)},
    {Exiv2::string,         $descriptor(Exiv2::StringValue*)},
    {Exiv2::date,           $descriptor(Exiv2::DateValue*)},
    {Exiv2::time,           $descriptor(Exiv2::TimeValue*)},
    {Exiv2::comment,        $descriptor(Exiv2::CommentValue*)},
    {Exiv2::xmpText,        $descriptor(Exiv2::XmpTextValue*)},
    {Exiv2::xmpAlt,         $descriptor(Exiv2::XmpArrayValue*)},
    {Exiv2::xmpBag,         $descriptor(Exiv2::XmpArrayValue*)},
    {Exiv2::xmpSeq,         $descriptor(Exiv2::XmpArrayValue*)},
    {Exiv2::langAlt,        $descriptor(Exiv2::LangAltValue*)}
};
}
%fragment("get_type_object", "header", fragment="_type_map_init") {
#include <map>
static std::map<Exiv2::TypeId, swig_type_info*> _type_object;
// Function to get swig type for an Exiv2 type id
static swig_type_info* get_type_object(const Exiv2::TypeId type_id) {
    auto ptr = _type_object.find(type_id);
    if (ptr == _type_object.end())
        return $descriptor(Exiv2::DataValue*);
    return ptr->second;
};
}

// Function to get swig type for an Exiv2 value
%fragment("get_swig_type", "header", fragment="get_type_object") {
static swig_type_info* get_swig_type(Exiv2::Value* value) {
    Exiv2::TypeId type_id = value->typeId();
    if (type_id == Exiv2::undefined) {
        // value could be a CommentValue
        if (dynamic_cast<Exiv2::CommentValue*>(value))
            return $descriptor(Exiv2::CommentValue*);
    }
    return get_type_object(type_id);
};

}
%typemap(out, fragment="get_swig_type") Exiv2::Value::SMART_PTR {
    if ($1.get()) {
        Exiv2::Value* value = $1.release();
        $result = SWIG_NewPointerObj(
            value, get_swig_type(value), SWIG_POINTER_OWN);
    }
    else {
        $result = SWIG_Py_Void();
    }
}
%typemap(out, fragment="get_swig_type") const Exiv2::Value& {
    $result = SWIG_NewPointerObj($1, get_swig_type($1), 0);
}

// AsciiValue constructor should call AsciiValue::read to ensure string
// is null terminated
%extend Exiv2::AsciiValue {
    AsciiValue(const std::string &buf) {
        Exiv2::AsciiValue* self = new Exiv2::AsciiValue();
        if (self->read(buf)) {
            delete self;
            return NULL;
        }
        return self;
    }
}
%ignore Exiv2::AsciiValue::AsciiValue(const std::string &buf);

// CommentValue::detectCharset has a string reference parameter
%apply const std::string& {std::string& c};

// Make Exiv2::ByteOrder parameters optional
%typemap(default) Exiv2::ByteOrder byteOrder {$1 = Exiv2::invalidByteOrder;}

// Make Exiv2::TypeId parameters optional
%typemap(default) Exiv2::TypeId typeId {$1 = Exiv2::undefined;}

// Use default parameter for toFloat etc.
%typemap(default) long n, size_t n {$1 = 0;}

// Ignore now redundant overloaded methods
%ignore Exiv2::DataValue::DataValue();
%ignore Exiv2::DataValue::DataValue(byte const *, BUFLEN_T);
%ignore Exiv2::DataValue::DataValue(byte const *, BUFLEN_T, ByteOrder);
%ignore Exiv2::Value::toFloat() const;
%ignore Exiv2::Value::toInt64() const;
%ignore Exiv2::Value::toLong() const;
%ignore Exiv2::Value::toString() const;
%ignore Exiv2::Value::toRational() const;
%ignore Exiv2::Value::toUint32() const;

// Make enums more Pythonic
#ifndef SWIGIMPORTED
DEFINE_CLASS_ENUM(CommentValue, CharsetId,)
DEFINE_CLASS_ENUM(XmpValue, XmpArrayType,)
DEFINE_CLASS_ENUM(XmpValue, XmpStruct,)
#else
IMPORT_CLASS_ENUM(_value, CommentValue, CharsetId)
IMPORT_CLASS_ENUM(_value, CommentValue, XmpArrayType)
IMPORT_CLASS_ENUM(_value, CommentValue, XmpStruct)
#endif

// deprecated since 2023-12-01
DEPRECATED_ENUM(CommentValue, CharsetId)
// deprecated since 2023-12-01
DEPRECATED_ENUM(XmpValue, XmpArrayType)
// deprecated since 2023-12-01
DEPRECATED_ENUM(XmpValue, XmpStruct)

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%feature("python:slot", "sq_length", functype="lenfunc") type_name::count;
%ignore type_name::value_;
// Ignore overloaded methods replaced by default typemaps
%ignore type_name::copy(byte *) const;
%ignore type_name::read(byte const *, BUFLEN_T);
%noexception type_name::~part_name;
%noexception type_name::append;
%noexception type_name::count;
%noexception type_name::size;
UNIQUE_PTR(type_name)
// Deprecate some methods since 2025-08-25
DEPRECATE_FUNCTION(type_name::copy, true)
DEPRECATE_FUNCTION(type_name::read(const byte*, long, ByteOrder), true)
DEPRECATE_FUNCTION(type_name::read(const byte*, size_t, ByteOrder), true)
DEPRECATE_FUNCTION(type_name::write, true)
%enddef // VALUE_SUBCLASS

// Deprecate some base class methods since 2025-08-25
DEPRECATE_FUNCTION(Exiv2::Value::copy, true)
DEPRECATE_FUNCTION(Exiv2::Value::read(const byte*, long, ByteOrder), true)
DEPRECATE_FUNCTION(Exiv2::Value::read(const byte*, size_t, ByteOrder), true)
DEPRECATE_FUNCTION(Exiv2::Value::write, true)

// Macro for Exiv2::ValueType classes
%define VALUETYPE(type_name, item_type, type_id)
VALUE_SUBCLASS(Exiv2::ValueType<item_type>, type_name)
// Use default typemap to handle "TypeId typeId=getType< T >()"
%typemap(default) Exiv2::TypeId typeId {$1 = type_id;}
// Ignore now overloaded constructors
%ignore Exiv2::ValueType<item_type>::ValueType(item_type const &);
#if EXIV2_VERSION_HEX < 0x001c0000
%ignore Exiv2::ValueType<item_type>::ValueType();
#endif
%ignore Exiv2::ValueType<item_type>::ValueType(
    byte const *, BUFLEN_T, ByteOrder);
// Also need to ignore equivalent primitive type definitions
%ignore Exiv2::ValueType<item_type>::ValueType(short const &);
%ignore Exiv2::ValueType<item_type>::ValueType(unsigned short const &);
%ignore Exiv2::ValueType<item_type>::ValueType(int const &);
%ignore Exiv2::ValueType<item_type>::ValueType(unsigned int const &);
%ignore Exiv2::ValueType<item_type>::ValueType(std::pair< int,int > const &);
%ignore Exiv2::ValueType<item_type>::ValueType(
    std::pair< unsigned int,unsigned int > const &);
// Access values as a list
SQ_ITEM(Exiv2::ValueType<item_type>, item_type, self->value_[idx])
SQ_ASS_ITEM(Exiv2::ValueType<item_type>, item_type,
            self->value_[idx] = value,
            self->value_.erase(self->value_.begin() + idx))
%feature("docstring") Exiv2::ValueType<item_type>
"Sequence of " #item_type " values.\n"
"The data components can be accessed like a Python list."
%feature("docstring") Exiv2::ValueType<item_type>::append
"Append a " #item_type " component to the value."
%template() std::vector<item_type>;
%extend Exiv2::ValueType<item_type> {
    // Constructor, reads values from a Python list
    ValueType<item_type>(Exiv2::ValueType<item_type>::ValueList value) {
        Exiv2::ValueType<item_type>* result = new Exiv2::ValueType<item_type>();
        result->value_ = value;
        return result;
    }
    void append(item_type value) {
        $self->value_.push_back(value);
    }
}
%template(type_name) Exiv2::ValueType<item_type>;
%enddef // VALUETYPE


// Give Date and Time structs some dict-like behaviour
STRUCT_DICT(Exiv2::DateValue::Date, true, false)
STRUCT_DICT(Exiv2::TimeValue::Time, true, false)

%extend Exiv2::DateValue {
    // Allow DateValue to be constructed from a Date
    DateValue(Exiv2::DateValue::Date &src) {
        Exiv2::DateValue* self = new Exiv2::DateValue;
        self->setDate(src);
        return self;
    }
    // Allow DateValue to be set from int values
    void setDate(int year, int month, int day) {
        Exiv2::DateValue::Date date;
        date.year = year;
        date.month = month;
        date.day = day;
        $self->setDate(date);
    }
}

// Use SWIG default value handling instead of C++ overloads
%typemap(default) int second {$1 = 0;}
%typemap(default) int tzHour {$1 = 0;}
%typemap(default) int tzMinute {$1 = 0;}
%ignore Exiv2::TimeValue::TimeValue(int,int);
%ignore Exiv2::TimeValue::TimeValue(int,int,int);
%ignore Exiv2::TimeValue::TimeValue(int,int,int,int);
// int is replaced by int32_t from exiv2 0.28.0
%typemap(default) int32_t second {$1 = 0;}
%typemap(default) int32_t tzHour {$1 = 0;}
%typemap(default) int32_t tzMinute {$1 = 0;}
%ignore Exiv2::TimeValue::TimeValue(int32_t,int32_t);
%ignore Exiv2::TimeValue::TimeValue(int32_t,int32_t,int32_t);
%ignore Exiv2::TimeValue::TimeValue(int32_t,int32_t,int32_t,int32_t);
%extend Exiv2::TimeValue {
    // Allow TimeValue to be constructed from a Time
    TimeValue(Exiv2::TimeValue::Time &src) {
        Exiv2::TimeValue* self = new Exiv2::TimeValue;
        self->setTime(src);
        return self;
    }
    // Allow TimeValue to be set from int values
    void setTime(int32_t hour, int32_t minute, int32_t second,
                 int32_t tzHour, int32_t tzMinute) {
        Exiv2::TimeValue::Time time;
        time.hour = hour;
        time.minute = minute;
        time.second = second;
        time.tzHour = tzHour;
        time.tzMinute = tzMinute;
        $self->setTime(time);
    }
}

// Make LangAltValue like a Python dict
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::LangAltValue::__iter__;
%feature("python:slot", "mp_length", functype="lenfunc")
    Exiv2::LangAltValue::count;
MP_SUBSCRIPT(Exiv2::LangAltValue, std::string, self->value_.at(key))
MP_ASS_SUBSCRIPT(Exiv2::LangAltValue, std::string, self->value_[key] = value,
{
    auto pos = self->value_.find(key);
    if (pos == self->value_.end())
        return PyErr_Format(PyExc_KeyError, "'%s'", key);
    self->value_.erase(pos);
},)
SQ_CONTAINS(
    Exiv2::LangAltValue, self->value_.find(key) != self->value_.end())
%feature("docstring") Exiv2::LangAltValue::keys
"Get keys (i.e. languages) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::values
"Get values (i.e. text strings) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::items
"Get key, value pairs (i.e. language, text) of the LangAltValue
components."
%noexception Exiv2::LangAltValue::__iter__;
%noexception Exiv2::LangAltValue::keys;
%noexception Exiv2::LangAltValue::items;
%noexception Exiv2::LangAltValue::values;
%template() std::map<
    std::string, std::string, Exiv2::LangAltValueComparator>;
%extend Exiv2::LangAltValue {
    // Constructor, reads values from a Python dict
    LangAltValue(Exiv2::LangAltValue::ValueType value) {
        Exiv2::LangAltValue* result = new Exiv2::LangAltValue;
        result->value_ = value;
        return result;
    }
    PyObject* keys() {
        PyObject* as_dict = swig::from($self->value_);
        PyObject* result = PyDict_Keys(as_dict);
        Py_DECREF(as_dict);
        return result;
    }
    PyObject* values() {
        PyObject* as_dict = swig::from($self->value_);
        PyObject* result = PyDict_Values(as_dict);
        Py_DECREF(as_dict);
        return result;
    }
    PyObject* items() {
        PyObject* as_dict = swig::from($self->value_);
        PyObject* result = PyDict_Items(as_dict);
        Py_DECREF(as_dict);
        return result;
    }
    PyObject* __iter__() {
        PyObject* keys = %mangle(Exiv2::LangAltValue::keys)($self);
        PyObject* result = PySeqIter_New(keys);
        Py_DECREF(keys);
        return result;
    }
}

// Add Python slots to Exiv2::Value base class
%feature("python:slot", "sq_length", functype="lenfunc") Exiv2::Value::count;
// Overloaded toString() means we need our own function
TP_STR(Exiv2::Value, self->toString())

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

// Allow access to Exiv2::StringValueBase and Exiv2::XmpTextValue raw data
%define RAW_STRING_DATA(class)
RETURN_VIEW(const char* data, arg1->value_.size(), PyBUF_READ, class##::data)
%noexception class::data;
%extend class {
    const char* data() {
        return (char*)self->value_.data();
    };
}
DEFINE_VIEW_CALLBACK(class,)
// Release memoryviews when new data is read
%typemap(ret, fragment="memoryview_funcs") (int class::read) %{
    release_views(self);
%}
%enddef // RAW_STRING_DATA
RAW_STRING_DATA(Exiv2::StringValueBase)
RAW_STRING_DATA(Exiv2::XmpTextValue)

// Add data() method to DataValue
#if EXIV2_VERSION_HEX >= 0x001c0800
RAW_STRING_DATA(Exiv2::DataValue)
#else
%feature("docstring") Exiv2::DataValue::data "Return a copy of the raw data.

Allocates a :obj:`bytearray` of the correct size and copies the value's
data into it.

:rtype: bytearray"
%extend Exiv2::DataValue {
PyObject* data() {
    PyObject* result = PyByteArray_FromStringAndSize(NULL, self->size());
    if (!result)
        return NULL;
    PyObject* view = PyMemoryView_FromObject(result);
    if (!view) {
        Py_DECREF(result);
        return NULL;
    }
    Py_buffer* buffer = PyMemoryView_GET_BUFFER(view);
    self->copy((Exiv2::byte*)buffer->buf);
    Py_DECREF(view);
    return result;
}
}
#endif

// XmpArrayValue holds multiple values but they're not assignable
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::XmpArrayValue::count;
%feature("python:slot", "sq_item", functype="ssizeargfunc")
    Exiv2::XmpArrayValue::toString;
%typemap(default) Exiv2::TypeId typeId_xmpBag {$1 = Exiv2::xmpBag;}
%template() std::vector<std::string>;
%extend Exiv2::XmpArrayValue {
    // Constructor, reads values from a Python list
    XmpArrayValue(std::vector<std::string> value,
                  Exiv2::TypeId typeId_xmpBag) {
        Exiv2::XmpArrayValue* result =
            new Exiv2::XmpArrayValue(typeId_xmpBag);
        for (std::vector<std::string>::const_iterator i = value.begin();
             i != value.end(); ++i) {
            if (result->read(*i)) {
                delete result;
                return NULL;
            }
        }
        return result;
    }
    // Replacement default constructor
    XmpArrayValue(Exiv2::TypeId typeId_xmpBag) {
        return new Exiv2::XmpArrayValue(typeId_xmpBag);
    }
    PyObject* append(std::string value) {
        int error = $self->read(value);
        if (error)
            return PyErr_Format(PyExc_RuntimeError,
                                "XmpArrayValue.read returned %d", error);
        return SWIG_Py_Void();
    }
}
%ignore Exiv2::XmpArrayValue::XmpArrayValue();
%ignore Exiv2::XmpArrayValue::XmpArrayValue(TypeId);

// Some classes wrongly appear to be abstract to SWIG
%feature("notabstract") Exiv2::LangAltValue;
%feature("notabstract") Exiv2::XmpArrayValue;
%feature("notabstract") Exiv2::XmpTextValue;

// Ignore overloaded static xmpArrayType method. SWIG gets confused and makes
// the other method static as well.
%ignore Exiv2::XmpValue::xmpArrayType(TypeId typeId);

// Ignore "abstract" base class destructors.
%ignore Exiv2::Value::~Value;
%ignore Exiv2::StringValueBase::~StringValueBase;
%ignore Exiv2::XmpValue::~XmpValue;

// Ignore stuff Python can't use or SWIG can't handle
%ignore Exiv2::getValue;
%ignore Exiv2::operator<<;
%ignore Exiv2::Value::operator=;
%ignore Exiv2::CommentValue::CharsetInfo;
%ignore Exiv2::CommentValue::CharsetTable;
%ignore Exiv2::LangAltValueComparator;
%ignore LARGE_INT;
%ignore ValueList;

%include "exiv2/value.hpp"

// Turn off default typemap for ValueType classes
%typemap(default) Exiv2::ByteOrder byteOrder;

VALUETYPE(UShortValue, uint16_t, Exiv2::unsignedShort)
VALUETYPE(ULongValue, uint32_t, Exiv2::unsignedLong)
VALUETYPE(URationalValue, Exiv2::URational, Exiv2::unsignedRational)
VALUETYPE(ShortValue, int16_t, Exiv2::signedShort)
VALUETYPE(LongValue, int32_t, Exiv2::signedLong)
VALUETYPE(RationalValue, Exiv2::Rational, Exiv2::signedRational)
VALUETYPE(FloatValue, float, Exiv2::tiffFloat)
VALUETYPE(DoubleValue, double, Exiv2::tiffDouble)

INIT_STRUCT_DICT(Exiv2::DateValue::Date)
INIT_STRUCT_DICT(Exiv2::TimeValue::Time)
