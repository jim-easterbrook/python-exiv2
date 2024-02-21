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

%module(package="exiv2") value
%feature("flatnested", "1");

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 metadata value classes.";
#endif

// We don't need Python access to SwigPyIterator
%ignore SwigPyIterator;

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/enum.i"
%include "shared/exception.i"
%include "shared/struct_dict.i"
%include "shared/unique_ptr.i"

%include "stdint.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"
%include "typemaps.i"

%import "types.i"

IMPORT_ENUM(ByteOrder)
IMPORT_ENUM(TypeId)

// Catch all C++ exceptions
EXCEPTION()

UNIQUE_PTR(Exiv2::Value);

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
%typemap(check) long idx %{
    if ($1 < 0 || $1 >= static_cast< long >(arg1->count())) {
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
// DataValue constructor and DataValue::read can take a Python buffer
#if EXIV2_VERSION_HEX < 0x001c0000
INPUT_BUFFER_RO(const Exiv2::byte* buf, long len)
#else
INPUT_BUFFER_RO(const Exiv2::byte* buf, size_t len)
#endif
// Value::copy can write to a Python buffer
OUTPUT_BUFFER_RW(Exiv2::byte* buf, Exiv2::ByteOrder byteOrder)
// redefine check typemap
%typemap(check) (Exiv2::byte* buf, Exiv2::ByteOrder byteOrder) {
    // check buffer is large enough, assumes arg1 points to self
    if ((Py_ssize_t) arg1->size() > _global_view.len) {
        %argument_fail(SWIG_ValueError, "buffer too small",
                       $symname, $argnum);
    }
}
// Downcast base class pointers to derived class
// Convert exiv2 type id to the appropriate value class type info
%fragment("get_type_object", "header") {
static swig_type_info* get_type_object(Exiv2::TypeId type_id) {
    switch(type_id) {
        case Exiv2::asciiString:
            return $descriptor(Exiv2::AsciiValue*);
        case Exiv2::unsignedShort:
            return $descriptor(Exiv2::ValueType<uint16_t>*);
        case Exiv2::unsignedLong:
        case Exiv2::tiffIfd:
            return $descriptor(Exiv2::ValueType<uint32_t>*);
        case Exiv2::unsignedRational:
            return $descriptor(Exiv2::ValueType<Exiv2::URational>*);
        case Exiv2::signedShort:
            return $descriptor(Exiv2::ValueType<int16_t>*);
        case Exiv2::signedLong:
            return $descriptor(Exiv2::ValueType<int32_t>*);
        case Exiv2::signedRational:
            return $descriptor(Exiv2::ValueType<Exiv2::Rational>*);
        case Exiv2::tiffFloat:
            return $descriptor(Exiv2::ValueType<float>*);
        case Exiv2::tiffDouble:
            return $descriptor(Exiv2::ValueType<double>*);
        case Exiv2::string:
            return $descriptor(Exiv2::StringValue*);
        case Exiv2::date:
            return $descriptor(Exiv2::DateValue*);
        case Exiv2::time:
            return $descriptor(Exiv2::TimeValue*);
        case Exiv2::comment:
            return $descriptor(Exiv2::CommentValue*);
        case Exiv2::xmpText:
            return $descriptor(Exiv2::XmpTextValue*);
        case Exiv2::xmpAlt:
        case Exiv2::xmpBag:
        case Exiv2::xmpSeq:
            return $descriptor(Exiv2::XmpArrayValue*);
        case Exiv2::langAlt:
            return $descriptor(Exiv2::LangAltValue*);
        default:
            return $descriptor(Exiv2::DataValue*);
    }
};
}
// Function to get swig type for an Exiv2 type id
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
        self->read(buf);
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
%ignore Exiv2::DataValue::DataValue(byte const *, long);
%ignore Exiv2::DataValue::DataValue(byte const *, long, ByteOrder);
%ignore Exiv2::DataValue::DataValue(byte const *, size_t);
%ignore Exiv2::DataValue::DataValue(byte const *, size_t, ByteOrder);
%ignore Exiv2::Value::toFloat() const;
%ignore Exiv2::Value::toInt64() const;
%ignore Exiv2::Value::toLong() const;
%ignore Exiv2::Value::toRational() const;
%ignore Exiv2::Value::toUint32() const;

// Make enums more Pythonic
DEFINE_CLASS_ENUM(CommentValue, CharsetId,
    "Character set identifiers for the character sets defined by Exif.",
    "ascii",            Exiv2::CommentValue::ascii,
    "jis",              Exiv2::CommentValue::jis,
    "unicode",          Exiv2::CommentValue::unicode,
    "undefined",        Exiv2::CommentValue::undefined,
    "invalidCharsetId", Exiv2::CommentValue::invalidCharsetId,
    "lastCharsetId",    Exiv2::CommentValue::lastCharsetId);
DEFINE_CLASS_ENUM(XmpValue, XmpArrayType, "XMP array types.",
    "xaNone",   Exiv2::XmpValue::xaNone,
    "xaAlt",    Exiv2::XmpValue::xaAlt,
    "xaBag",    Exiv2::XmpValue::xaBag,
    "xaSeq",    Exiv2::XmpValue::xaSeq);
DEFINE_CLASS_ENUM(XmpValue, XmpStruct, "XMP structure indicator.",
    "xsNone",   Exiv2::XmpValue::xsNone,
    "xsStruct", Exiv2::XmpValue::xsStruct);

// deprecated since 2023-12-01
DEPRECATED_ENUM(CommentValue, CharsetId,
    "Character set identifiers for the character sets defined by Exif.",
        "ascii",            Exiv2::CommentValue::ascii,
        "jis",              Exiv2::CommentValue::jis,
        "unicode",          Exiv2::CommentValue::unicode,
        "undefined",        Exiv2::CommentValue::undefined,
        "invalidCharsetId", Exiv2::CommentValue::invalidCharsetId,
        "lastCharsetId",    Exiv2::CommentValue::lastCharsetId);
// deprecated since 2023-12-01
DEPRECATED_ENUM(XmpValue, XmpArrayType, "XMP array types.",
        "xaNone",   Exiv2::XmpValue::xaNone,
        "xaAlt",    Exiv2::XmpValue::xaAlt,
        "xaBag",    Exiv2::XmpValue::xaBag,
        "xaSeq",    Exiv2::XmpValue::xaSeq);
// deprecated since 2023-12-01
DEPRECATED_ENUM(XmpValue, XmpStruct, "XMP structure indicator.",
        "xsNone",   Exiv2::XmpValue::xsNone,
        "xsStruct", Exiv2::XmpValue::xsStruct);

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%feature("python:slot", "sq_length", functype="lenfunc") type_name::count;
%ignore type_name::value_;
// Ignore overloaded methods replaced by default typemaps
%ignore type_name::copy(byte *) const;
%ignore type_name::read(byte const *, long);
%ignore type_name::read(byte const *, size_t);
%noexception type_name::~part_name;
%noexception type_name::__getitem__;
%noexception type_name::__setitem__;
%noexception type_name::append;
%noexception type_name::count;
%noexception type_name::size;
%extend type_name {
    part_name(const Exiv2::Value& value) {
        // deprecated since 2022-12-28
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Use '" #type_name ".clone()' to copy value", 1);
        type_name* pv = dynamic_cast< type_name* >(value.clone().release());
        if (pv == 0) {
            std::string msg = "Cannot cast type '";
            msg += Exiv2::TypeInfo::typeName(value.typeId());
            msg += "' to type '";
            msg += Exiv2::TypeInfo::typeName(type_name().typeId());
            msg += "'.";
#if EXIV2_VERSION_HEX < 0x001c0000
            throw Exiv2::Error(Exiv2::kerErrorMessage, msg);
#else
            throw Exiv2::Error(Exiv2::ErrorCode::kerErrorMessage, msg);
#endif
        }
        return pv;
    }
}
UNIQUE_PTR(type_name)
%enddef // VALUE_SUBCLASS

// Subscript macro for classes that can only hold one value
%define SUBSCRIPT_SINGLE(type_name, item_type, method)
%feature("python:slot", "sq_item", functype="ssizeargfunc")
    type_name::__getitem__;
%extend type_name {
    item_type __getitem__(long single_idx) {
        // deprecated since 2022-12-15
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Use 'value = " #type_name "." #method "()'", 1);
        return $self->method();
    }
}
%enddef // SUBSCRIPT_SINGLE

// Macro for Exiv2::ValueType classes
%define VALUETYPE(type_name, item_type, type_id)
VALUE_SUBCLASS(Exiv2::ValueType<item_type>, type_name)
// Use default typemap to handle "TypeId typeId=getType< T >()"
%typemap(default) Exiv2::TypeId typeId {$1 = type_id;}
// Ignore now overloaded constructors
%ignore Exiv2::ValueType<item_type>::ValueType(item_type const &);
#if EXIV2_VERSION_HEX < 0x001c0000
%ignore Exiv2::ValueType<item_type>::ValueType(
    byte const *, long, ByteOrder);
%ignore Exiv2::ValueType<item_type>::ValueType();
#else
%ignore Exiv2::ValueType<item_type>::ValueType(
    byte const *, size_t, ByteOrder);
#endif
// Also need to ignore equivalent primitive type definitions
%ignore Exiv2::ValueType<item_type>::ValueType(short const &);
%ignore Exiv2::ValueType<item_type>::ValueType(unsigned short const &);
%ignore Exiv2::ValueType<item_type>::ValueType(int const &);
%ignore Exiv2::ValueType<item_type>::ValueType(unsigned int const &);
%ignore Exiv2::ValueType<item_type>::ValueType(std::pair< int,int > const &);
%ignore Exiv2::ValueType<item_type>::ValueType(
    std::pair< unsigned int,unsigned int > const &);
// Access values as a list
%feature("python:slot", "sq_item", functype="ssizeargfunc")
    Exiv2::ValueType<item_type>::__getitem__;
#if SWIG_VERSION >= 0x040201
%feature("python:slot", "sq_ass_item", functype="ssizeobjargproc")
    Exiv2::ValueType<item_type>::__setitem__;
#else
// sq_ass_item segfaults when used to delete element
// See https://github.com/swig/swig/pull/2771
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    Exiv2::ValueType<item_type>::__setitem__;
#endif // SWIG_VERSION
%feature("docstring") Exiv2::ValueType<item_type>
"Sequence of " #item_type " values.\n"
"The data components can be accessed like a Python list."
%feature("docstring") Exiv2::ValueType<item_type>::append
"Append a " #item_type " component to the value."
%template() std::vector<item_type>;
%typemap(default) const item_type* INPUT {$1 = NULL;}
%extend Exiv2::ValueType<item_type> {
    // Constructor, reads values from a Python list
    ValueType<item_type>(Exiv2::ValueType<item_type>::ValueList value) {
        Exiv2::ValueType<item_type>* result = new Exiv2::ValueType<item_type>();
        result->value_ = value;
        return result;
    }
    item_type __getitem__(long idx) {
        return $self->value_[idx];
    }
    void __setitem__(long idx, const item_type* INPUT) {
        if (INPUT)
            $self->value_[idx] = *INPUT;
        else
            $self->value_.erase($self->value_.begin() + idx);
    }
    void append(item_type value) {
        $self->value_.push_back(value);
    }
}
%template(type_name) Exiv2::ValueType<item_type>;
%enddef // VALUETYPE

// Give Date and Time structs some dict-like behaviour
STRUCT_DICT(Exiv2::DateValue::Date)
STRUCT_DICT(Exiv2::TimeValue::Time)

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
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    Exiv2::LangAltValue::__getitem__;
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    Exiv2::LangAltValue::__setitem__;
%feature("python:slot", "sq_contains", functype="objobjproc")
    Exiv2::LangAltValue::__contains__;
%feature("docstring") Exiv2::LangAltValue::keys
"Get keys (i.e. languages) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::values
"Get values (i.e. text strings) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::items
"Get key, value pairs (i.e. language, text) of the LangAltValue
components."
%noexception Exiv2::LangAltValue::__contains__;
%noexception Exiv2::LangAltValue::__getitem__;
%noexception Exiv2::LangAltValue::__iter__;
%noexception Exiv2::LangAltValue::__setitem__;
%noexception Exiv2::LangAltValue::keys;
%noexception Exiv2::LangAltValue::items;
%noexception Exiv2::LangAltValue::values;
%template() std::map<
    std::string, std::string, Exiv2::LangAltValueComparator>;
%typemap(default) const std::string* INPUT {$1 = NULL;}
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
    PyObject* __getitem__(const std::string& key) {
        try {
            return SWIG_From_std_string($self->value_.at(key));
        } catch(std::out_of_range const&) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
        }
        return NULL;
    }
    PyObject* __setitem__(const std::string& key, const std::string* INPUT) {
        if (INPUT)
            $self->value_[key] = *INPUT;
        else {
            typedef Exiv2::LangAltValue::ValueType::iterator iter;
            iter pos = $self->value_.find(key);
            if (pos == $self->value_.end()) {
                PyErr_SetString(PyExc_KeyError, key.c_str());
                return NULL;
            }
            $self->value_.erase(pos);
        }
        return SWIG_Py_Void();
    }
    bool __contains__(const std::string& key) {
        return $self->value_.find(key) != $self->value_.end();
    }
}

// Add Python slots to Exiv2::Value base class
%feature("python:slot", "tp_str", functype="reprfunc") Exiv2::Value::__str__;
%feature("python:slot", "sq_length", functype="lenfunc") Exiv2::Value::count;
%extend Exiv2::Value {
    // Overloaded toString() means we need our own __str__
    std::string __str__() {return $self->toString();}
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

// Allow access to Exiv2::StringValueBase and Exiv2::XmpTextValue raw data
%define RAW_STRING_DATA(class)
RETURN_VIEW(const char* data, arg1->value_.size(), PyBUF_READ,
            class##::data)
%noexception class::data;
%extend class {
    const char* data() {
        return $self->value_.data();
    }
}
%enddef // RAW_STRING_DATA
RAW_STRING_DATA(Exiv2::StringValueBase)
RAW_STRING_DATA(Exiv2::XmpTextValue)

// XmpArrayValue holds multiple values but they're not assignable
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::XmpArrayValue::count;
%feature("python:slot", "sq_item", functype="ssizeargfunc")
    Exiv2::XmpArrayValue::__getitem__;
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
            result->read(*i);
        }
        return result;
    }
    // Replacement default constructor
    XmpArrayValue(Exiv2::TypeId typeId_xmpBag) {
        return new Exiv2::XmpArrayValue(typeId_xmpBag);
    }
    std::string __getitem__(long idx) {
        return $self->toString(idx);
    }
    void append(std::string value) {
        $self->read(value);
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
