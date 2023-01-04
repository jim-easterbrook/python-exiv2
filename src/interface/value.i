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

%include "preamble.i"

%include "stdint.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::Value);

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
#if EXIV2_VERSION_HEX < 0x01000000
INPUT_BUFFER_RO(const Exiv2::byte* buf, long len)
#else
INPUT_BUFFER_RO(const Exiv2::byte* buf, size_t len)
#endif
// Value::copy can write to a Python buffer
%typemap(in) Exiv2::byte* buf {
    Py_buffer view;
    int res = PyObject_GetBuffer($input, &view, PyBUF_CONTIG | PyBUF_WRITABLE);
    if (res < 0) {
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
// Macro to get swig type for an Exiv2 type id
%define GET_SWIG_TYPE()
    swig_type_info* swg_type = NULL;
    if (_global_type_id == Exiv2::lastTypeId)
        _global_type_id = value->typeId();
    switch(_global_type_id) {
        case Exiv2::asciiString:
            swg_type = $descriptor(Exiv2::AsciiValue*);
            value = dynamic_cast<Exiv2::AsciiValue*>(value);
            break;
        case Exiv2::unsignedShort:
            swg_type = $descriptor(Exiv2::ValueType<uint16_t>*);
            value = dynamic_cast<Exiv2::ValueType<uint16_t>*>(value);
            break;
        case Exiv2::unsignedLong:
        case Exiv2::tiffIfd:
            swg_type = $descriptor(Exiv2::ValueType<uint32_t>*);
            value = dynamic_cast<Exiv2::ValueType<uint32_t>*>(value);
            break;
        case Exiv2::unsignedRational:
            swg_type = $descriptor(Exiv2::ValueType<Exiv2::URational>*);
            value = dynamic_cast<Exiv2::ValueType<Exiv2::URational>*>(value);
            break;
        case Exiv2::undefined:
            swg_type = $descriptor(Exiv2::Value*);
            break;
        case Exiv2::signedShort:
            swg_type = $descriptor(Exiv2::ValueType<int16_t>*);
            value = dynamic_cast<Exiv2::ValueType<int16_t>*>(value);
            break;
        case Exiv2::signedLong:
            swg_type = $descriptor(Exiv2::ValueType<int32_t>*);
            value = dynamic_cast<Exiv2::ValueType<int32_t>*>(value);
            break;
        case Exiv2::signedRational:
            swg_type = $descriptor(Exiv2::ValueType<Exiv2::Rational>*);
            value = dynamic_cast<Exiv2::ValueType<Exiv2::Rational>*>(value);
            break;
        case Exiv2::tiffFloat:
            swg_type = $descriptor(Exiv2::ValueType<float>*);
            value = dynamic_cast<Exiv2::ValueType<float>*>(value);
            break;
        case Exiv2::tiffDouble:
            swg_type = $descriptor(Exiv2::ValueType<double>*);
            value = dynamic_cast<Exiv2::ValueType<double>*>(value);
            break;
        case Exiv2::string:
            swg_type = $descriptor(Exiv2::StringValue*);
            value = dynamic_cast<Exiv2::StringValue*>(value);
            break;
        case Exiv2::date:
            swg_type = $descriptor(Exiv2::DateValue*);
            value = dynamic_cast<Exiv2::DateValue*>(value);
            break;
        case Exiv2::time:
            swg_type = $descriptor(Exiv2::TimeValue*);
            value = dynamic_cast<Exiv2::TimeValue*>(value);
            break;
        case Exiv2::comment:
            swg_type = $descriptor(Exiv2::CommentValue*);
            value = dynamic_cast<Exiv2::CommentValue*>(value);
            break;
        case Exiv2::xmpText:
            swg_type = $descriptor(Exiv2::XmpTextValue*);
            value = dynamic_cast<Exiv2::XmpTextValue*>(value);
            break;
        case Exiv2::xmpAlt:
        case Exiv2::xmpBag:
        case Exiv2::xmpSeq:
            swg_type = $descriptor(Exiv2::XmpArrayValue*);
            value = dynamic_cast<Exiv2::XmpArrayValue*>(value);
            break;
        case Exiv2::langAlt:
            swg_type = $descriptor(Exiv2::LangAltValue*);
            value = dynamic_cast<Exiv2::LangAltValue*>(value);
            break;
        default:
            swg_type = $descriptor(Exiv2::DataValue*);
            value = dynamic_cast<Exiv2::DataValue*>(value);
    }
    if (!value) {
        PyErr_Format(PyExc_ValueError, "Cannot cast value to type '%s'.",
            Exiv2::TypeInfo::typeName(_global_type_id));
        SWIG_fail;
    }
%enddef // GET_SWIG_TYPE
#if EXIV2_VERSION_HEX < 0x01000000
%typemap(out) Exiv2::Value::AutoPtr
        (Exiv2::TypeId _global_type_id = Exiv2::lastTypeId) {
    if ($1.get()) {
        Exiv2::Value* value = $1.release();
        GET_SWIG_TYPE()
        $result = SWIG_NewPointerObj(value, swg_type, SWIG_POINTER_OWN);
    }
    else {
        $result = SWIG_Py_Void();
    }
}
#else   // EXIV2_VERSION_HEX
%typemap(out) Exiv2::Value::UniquePtr
        (Exiv2::TypeId _global_type_id = Exiv2::lastTypeId) {
    if ($1.get()) {
        Exiv2::Value* value = $1.release();
        GET_SWIG_TYPE()
        $result = SWIG_NewPointerObj(value, swg_type, SWIG_POINTER_OWN);
    }
    else {
        $result = SWIG_Py_Void();
    }
}
#endif  // EXIV2_VERSION_HEX
%typemap(out) const Exiv2::Value&
        (Exiv2::TypeId _global_type_id = Exiv2::lastTypeId) {
    Exiv2::Value* value = $1;
    GET_SWIG_TYPE()
    $result = SWIG_NewPointerObj(value, swg_type, 0);
}
// Keep a reference to Metadatum when calling value()
KEEP_REFERENCE(const Exiv2::Value&)

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%feature("python:slot", "sq_length", functype="lenfunc") type_name::count;
%ignore type_name::value_;
%noexception type_name::count;
%noexception type_name::size;
%extend type_name {
    part_name(const Exiv2::Value& value) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "Value should already have the correct type.", 1);
        type_name* pv = dynamic_cast< type_name* >(value.clone().release());
        if (pv == 0) {
            std::string msg = "Cannot cast type '";
            msg += Exiv2::TypeInfo::typeName(value.typeId());
            msg += "' to type '";
            msg += Exiv2::TypeInfo::typeName(type_name().typeId());
            msg += "'.";
#if EXIV2_VERSION_HEX < 0x01000000
            throw Exiv2::Error(Exiv2::kerErrorMessage, msg);
#else
            throw Exiv2::Error(Exiv2::ErrorCode::kerErrorMessage, msg);
#endif
        }
        return pv;
    }
}
wrap_auto_unique_ptr(type_name)
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
%noexception Exiv2::ValueType<item_type>::__getitem__;
%noexception Exiv2::ValueType<item_type>::__setitem__;
%noexception Exiv2::ValueType<item_type>::append;
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

// Allow DateValue to be set from int values
%extend Exiv2::DateValue {
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
        return PySeqIter_New(Py_BuildValue("((si)(si)(si))",
            "year", $self->year, "month", $self->month, "day", $self->day));
    }
}

// Allow TimeValue to be set from int values
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
// Make Time struct iterable for easy conversion to dict or list
%feature("python:slot", "tp_iter", functype="getiterfunc")
    Exiv2::TimeValue::Time::__iter__;
%noexception Exiv2::TimeValue::Time::__iter__;
%extend Exiv2::TimeValue::Time {
    PyObject* __iter__() {
        return PySeqIter_New(Py_BuildValue("((si)(si)(si)(si)(si))",
            "hour", $self->hour, "minute", $self->minute, "second", $self->second,
            "tzHour", $self->tzHour, "tzMinute", $self->tzMinute));
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
%template() std::map<std::string, std::string, Exiv2::LangAltValueComparator>;
%template() std::vector<std::string>;
%template() std::vector<std::pair<std::string,std::string>>;
%extend Exiv2::LangAltValue {
    // Constructor, reads values from a Python dict
    LangAltValue(Exiv2::LangAltValue::ValueType value) {
        Exiv2::LangAltValue* result = new Exiv2::LangAltValue;
        result->value_ = value;
        return result;
    }
    std::vector<std::string> keys() {
        std::vector<std::string> result;
        typedef Exiv2::LangAltValue::ValueType::iterator iter;
        iter e = $self->value_.end();
        for (iter i = $self->value_.begin(); i != e; ++i) {
            result.push_back(i->first);
        }
        return result;
    }
    std::vector<std::string> values() {
        std::vector<std::string> result;
        typedef Exiv2::LangAltValue::ValueType::iterator iter;
        iter e = $self->value_.end();
        for (iter i = $self->value_.begin(); i != e; ++i) {
            result.push_back(i->second);
        }
        return result;
    }
    std::vector<std::pair<std::string,std::string>> items() {
        std::vector<std::pair<std::string,std::string> > result;
        typedef Exiv2::LangAltValue::ValueType::iterator iter;
        iter e = $self->value_.end();
        for (iter i = $self->value_.begin(); i != e; ++i) {
            result.push_back(make_pair(i->first, i->second));
        }
        return result;
    }
    PyObject* __iter__() {
        return PySeqIter_New(swig::from(Exiv2_LangAltValue_keys($self)));
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
        Exiv2::LangAltValue::ValueType::iterator pos = $self->value_.find(key);
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

// Remove exception handler for some methods known to be safe
%noexception Exiv2::Value::count;
%noexception Exiv2::Value::size;
%noexception Exiv2::Value::ok;
%noexception Exiv2::Value::typeId;

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
        for (std::vector<std::string>::iterator i = value.begin();
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
ENUM(CharsetId,
    "Character set identifiers for the character sets defined by Exif.",
        "ascii",            Exiv2::CommentValue::ascii,
        "jis",              Exiv2::CommentValue::jis,
        "unicode",          Exiv2::CommentValue::unicode,
        "undefined",        Exiv2::CommentValue::undefined,
        "invalidCharsetId", Exiv2::CommentValue::invalidCharsetId,
        "lastCharsetId",    Exiv2::CommentValue::lastCharsetId);

// Some classes wrongly appear to be abstract to SWIG
%feature("notabstract") Exiv2::LangAltValue;
%feature("notabstract") Exiv2::XmpArrayValue;
%feature("notabstract") Exiv2::XmpTextValue;

// Ignore ambiguous constructor
%ignore Exiv2::ValueType< int32_t >::ValueType(int const &);

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

VALUETYPE(UShortValue, uint16_t)
VALUETYPE(ULongValue, uint32_t)
VALUETYPE(URationalValue, Exiv2::URational)
VALUETYPE(ShortValue, int16_t)
VALUETYPE(LongValue, int32_t)
VALUETYPE(RationalValue, Exiv2::Rational)
VALUETYPE(FloatValue, float)
VALUETYPE(DoubleValue, double)
