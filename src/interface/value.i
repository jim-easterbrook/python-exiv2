// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

// We don't need Python access to SwigPyIterator
%ignore SwigPyIterator;

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/enum.i"
%include "shared/fragments.i"
%include "shared/unique_ptr.i"

%include "stdint.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"

%import "types.i"

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
// for indexing multi-value values, assumes arg1 points to self
%typemap(check) long multi_idx %{
    if ($1 < 0 || $1 >= (long)arg1->count()) {
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
%typemap(doctype) Exiv2::byte* buf "writeable bytes-like object";
%typemap(in) Exiv2::byte* buf {
    Py_buffer view;
    if (PyObject_GetBuffer($input, &view,
                           PyBUF_CONTIG | PyBUF_WRITABLE) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "writable buffer", $symname, $argnum);
    }
    $1 = (Exiv2::byte*) view.buf;
    size_t len = view.len;
    PyBuffer_Release(&view);
    // check writeable buf is large enough, assumes arg1 points to self
    if (len < (size_t) arg1->size()) {
        PyErr_Format(PyExc_ValueError,
            "in method '$symname', argument $argnum is a %d byte buffer,"
            " %d bytes needed", len, arg1->size());
        SWIG_fail;
    }
}
// Downcast base class pointers to derived class
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
#if EXIV2_VERSION_HEX < 0x001c0000
%typemap(out, fragment="get_swig_type") Exiv2::Value::AutoPtr {
    if ($1.get()) {
        Exiv2::Value* value = $1.release();
        $result = SWIG_NewPointerObj(
            value, get_swig_type(value), SWIG_POINTER_OWN);
    }
    else {
        $result = SWIG_Py_Void();
    }
}
#else   // EXIV2_VERSION_HEX
%typemap(out, fragment="get_swig_type") Exiv2::Value::UniquePtr {
    if ($1.get()) {
        Exiv2::Value* value = $1.release();
        $result = SWIG_NewPointerObj(
            value, get_swig_type(value), SWIG_POINTER_OWN);
    }
    else {
        $result = SWIG_Py_Void();
    }
}
#endif  // EXIV2_VERSION_HEX
%typemap(out, fragment="get_swig_type") const Exiv2::Value& {
    Exiv2::Value* value = $1;
    $result = SWIG_NewPointerObj(value, get_swig_type(value), 0);
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

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%feature("python:slot", "sq_length", functype="lenfunc") type_name::count;
%ignore type_name::value_;
%noexception type_name::~part_name;
%noexception type_name::__getitem__;
%noexception type_name::__setitem__;
%noexception type_name::append;
%noexception type_name::count;
%noexception type_name::size;
%extend type_name {
    part_name(const Exiv2::Value& value) {
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
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Use 'value = " #type_name "." #method "()'", 1);
        return $self->method();
    }
}
%enddef // SUBSCRIPT_SINGLE

// Macro for Exiv2::ValueType classes
%define VALUETYPE(type_name, item_type)
VALUE_SUBCLASS(Exiv2::ValueType<item_type>, type_name)
%feature("python:slot", "sq_item", functype="ssizeargfunc")
    Exiv2::ValueType<item_type>::__getitem__;
// sq_ass_item would be more logical, but it doesn't work for deletion
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    Exiv2::ValueType<item_type>::__setitem__;
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
    item_type __getitem__(long multi_idx) {
        return $self->value_[multi_idx];
    }
    void __setitem__(long multi_idx, item_type value) {
        $self->value_[multi_idx] = value;
    }
    void __setitem__(long multi_idx) {
        $self->value_.erase($self->value_.begin() + multi_idx);
    }
    void append(item_type value) {
        $self->value_.push_back(value);
    }
}
%template(type_name) Exiv2::ValueType<item_type>;
%enddef // VALUETYPE

// Use Python dict for Exiv2::DateValue::Date outputs
%typemap(out) const Exiv2::DateValue::Date& {
    $result = Py_BuildValue("{si,si,si}",
        "year", $1->year, "month", $1->month, "day", $1->day);
}
// Use Python dict for Exiv2::DateValue::Date inputs
%typemap(doctype) Exiv2::DateValue::Date "dict"
// Dummy typecheck to make SWIG check other overloads first
%typemap(typecheck, precedence=SWIG_TYPECHECK_SWIGOBJECT)
        Exiv2::DateValue::Date &src { }
%typemap(in) Exiv2::DateValue::Date &src (Exiv2::DateValue::Date date) {
    if (SWIG_IsOK(SWIG_ConvertPtr(
            $input, (void**)&$1, $descriptor(Exiv2::DateValue::Date*), 0))) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use dict instead of DateValue::Date", 1);
    }
    else {
        if (!PyDict_Check($input)) {
            %argument_fail(SWIG_TypeError, "dict", $symname, $argnum);
        }
        PyObject* py_val = PyDict_GetItemString($input, "year");
        date.year = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "month");
        date.month = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "day");
        date.day = py_val ? PyLong_AsLong(py_val) : 0;
        $1 = &date;
    }
}
%extend Exiv2::DateValue {
    // Allow DateValue to be constructed from a dict
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
// Make Date struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::DateValue::Date::__iter__;
%noexception Exiv2::DateValue::Date::__iter__;
%extend Exiv2::DateValue::Date {
    PyObject* __iter__() {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use getDate() to get Python dict", 1);
        PyObject* seq = Py_BuildValue("((si)(si)(si))",
            "year", $self->year, "month", $self->month, "day", $self->day);
        PyObject* result = PySeqIter_New(seq);
        Py_DECREF(seq);
        return result;
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
// Use Python datetime.time for Exiv2::TimeValue::Time outputs
%typemap(out) const Exiv2::TimeValue::Time& {
    $result = Py_BuildValue("{si,si,si,si,si}",
        "hour", $1->hour, "minute", $1->minute, "second", $1->second,
        "tzHour", $1->tzHour, "tzMinute", $1->tzMinute);
}
// Use Python dict for Exiv2::TimeValue::Time inputs
%typemap(doctype) Exiv2::TimeValue::Time "dict"
// Dummy typecheck to make SWIG check other overloads first
%typemap(typecheck, precedence=SWIG_TYPECHECK_SWIGOBJECT)
        Exiv2::TimeValue::Time &src { }
%typemap(in) Exiv2::TimeValue::Time &src (Exiv2::TimeValue::Time time) {
    if (SWIG_IsOK(SWIG_ConvertPtr(
            $input, (void**)&$1, $descriptor(Exiv2::TimeValue::Time*), 0))) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use dict instead of TimeValue::Time", 1);
    }
    else {
        if (!PyDict_Check($input)) {
            %argument_fail(SWIG_TypeError, "dict", $symname, $argnum);
        }
        PyObject* py_val = PyDict_GetItemString($input, "hour");
        time.hour = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "minute");
        time.minute = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "second");
        time.second = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "tzHour");
        time.tzHour = py_val ? PyLong_AsLong(py_val) : 0;
        py_val = PyDict_GetItemString($input, "tzMinute");
        time.tzMinute = py_val ? PyLong_AsLong(py_val) : 0;
        $1 = &time;
    }
}
%extend Exiv2::TimeValue {
    // Allow TimeValue to be constructed from a dict
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
// Make Time struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::TimeValue::Time::__iter__;
%noexception Exiv2::TimeValue::Time::__iter__;
%extend Exiv2::TimeValue::Time {
    PyObject* __iter__() {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use getDate() to get Python dict", 1);
        PyObject* seq = Py_BuildValue("((si)(si)(si)(si)(si))",
            "hour", $self->hour, "minute", $self->minute,
            "second", $self->second,
            "tzHour", $self->tzHour, "tzMinute", $self->tzMinute);
        PyObject* result = PySeqIter_New(seq);
        Py_DECREF(seq);
        return result;
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
    void __setitem__(const std::string& key, const std::string& value) {
        $self->value_[key] = value;
    }
    PyObject* __setitem__(const std::string& key) {
        typedef Exiv2::LangAltValue::ValueType::iterator iter;
        iter pos = $self->value_.find(key);
        if (pos == $self->value_.end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->value_.erase(pos);
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
%template() std::vector<std::string>;
%extend Exiv2::XmpArrayValue {
    // Constructor, reads values from a Python list
    XmpArrayValue(std::vector<std::string> value,
                  Exiv2::TypeId typeId=Exiv2::xmpBag) {
        Exiv2::XmpArrayValue* result = new Exiv2::XmpArrayValue(typeId);
        for (std::vector<std::string>::const_iterator i = value.begin();
             i != value.end(); ++i) {
            result->read(*i);
        }
        return result;
    }
    std::string __getitem__(long multi_idx) {
        return $self->toString(multi_idx);
    }
    void append(std::string value) {
        $self->read(value);
    }
}

// Make enums more Pythonic
DEPRECATED_ENUM(CommentValue, CharsetId,
    "Character set identifiers for the character sets defined by Exif.",
        "ascii",            Exiv2::CommentValue::ascii,
        "jis",              Exiv2::CommentValue::jis,
        "unicode",          Exiv2::CommentValue::unicode,
        "undefined",        Exiv2::CommentValue::undefined,
        "invalidCharsetId", Exiv2::CommentValue::invalidCharsetId,
        "lastCharsetId",    Exiv2::CommentValue::lastCharsetId);
DEPRECATED_ENUM(XmpValue, XmpArrayType, "XMP array types.",
        "xaNone",   Exiv2::XmpValue::xaNone,
        "xaAlt",    Exiv2::XmpValue::xaAlt,
        "xaBag",    Exiv2::XmpValue::xaBag,
        "xaSeq",    Exiv2::XmpValue::xaSeq);
DEPRECATED_ENUM(XmpValue, XmpStruct, "XMP structure indicator.",
        "xsNone",   Exiv2::XmpValue::xsNone,
        "xsStruct", Exiv2::XmpValue::xsStruct);

// Some classes wrongly appear to be abstract to SWIG
%feature("notabstract") Exiv2::LangAltValue;
%feature("notabstract") Exiv2::XmpArrayValue;
%feature("notabstract") Exiv2::XmpTextValue;

// Ignore ambiguous constructor
%ignore Exiv2::ValueType< int32_t >::ValueType(TypeId typeId);

// Ignore overloaded static xmpArrayType method. SWIG gets confused and makes
// the other method static as well.
%ignore Exiv2::XmpValue::xmpArrayType(TypeId typeId);

// Ignore stuff Python can't use or SWIG can't handle
%ignore Exiv2::getValue;
%ignore Exiv2::operator<<;
%ignore Exiv2::Value::operator=;
%ignore Exiv2::Value::write;
%ignore Exiv2::CommentValue::CharsetInfo;
%ignore Exiv2::CommentValue::CharsetTable;
%ignore Exiv2::LangAltValueComparator;
%ignore LARGE_INT;

%include "exiv2/value.hpp"

CLASS_ENUM(CommentValue, CharsetId,
    "Character set identifiers for the character sets defined by Exif.",
    "ascii",            Exiv2::CommentValue::ascii,
    "jis",              Exiv2::CommentValue::jis,
    "unicode",          Exiv2::CommentValue::unicode,
    "undefined",        Exiv2::CommentValue::undefined,
    "invalidCharsetId", Exiv2::CommentValue::invalidCharsetId,
    "lastCharsetId",    Exiv2::CommentValue::lastCharsetId);
CLASS_ENUM(XmpValue, XmpArrayType, "XMP array types.",
    "xaNone",   Exiv2::XmpValue::xaNone,
    "xaAlt",    Exiv2::XmpValue::xaAlt,
    "xaBag",    Exiv2::XmpValue::xaBag,
    "xaSeq",    Exiv2::XmpValue::xaSeq);
CLASS_ENUM(XmpValue, XmpStruct, "XMP structure indicator.",
    "xsNone",   Exiv2::XmpValue::xsNone,
    "xsStruct", Exiv2::XmpValue::xsStruct);

VALUETYPE(UShortValue, uint16_t)
VALUETYPE(ULongValue, uint32_t)
VALUETYPE(URationalValue, Exiv2::URational)
VALUETYPE(ShortValue, int16_t)
VALUETYPE(LongValue, int32_t)
VALUETYPE(RationalValue, Exiv2::Rational)
VALUETYPE(FloatValue, float)
VALUETYPE(DoubleValue, double)
