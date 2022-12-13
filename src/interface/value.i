// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%include "pybuffer.i"
%include "stdint.i"
%include "std_map.i"
%include "std_string.i"
%include "std_vector.i"

%import "types.i"

wrap_auto_unique_ptr(Exiv2::Value);

// ---- Typemaps ----
%typemap(typecheck, precedence=SWIG_TYPECHECK_LIST) Exiv2::DateValue::Date & %{
    $1 = (PyTuple_Check($input) || PyList_Check($input)) ? 1 : 0;
%}
%typemap(in) Exiv2::DateValue::Date & (Exiv2::DateValue::Date date) %{
    if (!PyArg_ParseTuple(Py_BuildValue("(O)", $input), "(iii)",
                          &date.year, &date.month, &date.day)) {
        SWIG_fail;
    }
    $1 = &date;
%}
%typemap(out) Exiv2::DateValue::Date %{
    $result = Py_BuildValue("(iii)", $1.year, $1.month, $1.day);
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_LIST) Exiv2::TimeValue::Time & %{
    $1 = (PyTuple_Check($input) || PyList_Check($input)) ? 1 : 0;
%}
%typemap(in) Exiv2::TimeValue::Time & (Exiv2::TimeValue::Time time) %{
    if (!PyArg_ParseTuple(Py_BuildValue("(O)", $input), "(iiiii)",
                          &time.hour, &time.minute, &time.second,
                          &time.tzHour, &time.tzMinute)) {
        SWIG_fail;
    }
    $1 = &time;
%}
%typemap(out) Exiv2::TimeValue::Time %{
    $result = Py_BuildValue(
        "(iiiii)", $1.hour, $1.minute, $1.second, $1.tzHour, $1.tzMinute);
%}
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
%pybuffer_binary(const Exiv2::byte* buf, long len)
#else
%pybuffer_binary(const Exiv2::byte* buf, size_t len)
#endif
%typecheck(SWIG_TYPECHECK_POINTER) const Exiv2::byte* {
    $1 = PyObject_CheckBuffer($input);
}
// Value::copy can write to a Python buffer
#if EXIV2_VERSION_HEX < 0x01000000
%typemap(in) Exiv2::byte* buf (Py_buffer view, long _global_len) {
#else
%typemap(in) Exiv2::byte* buf (Py_buffer view, size_t _global_len) {
#endif
    int res = PyObject_GetBuffer($input, &view, PyBUF_WRITABLE);
    if (res < 0)
        %argument_fail(res, writable buffer, $symname, $argnum);
    $1 = (Exiv2::byte*) view.buf;
    _global_len = view.len;
    PyBuffer_Release(&view);
}
// check writeable buf is large enough, assumes arg1 points to self
%typemap(check) (const Exiv2::byte* buf) {}
%typemap(check) Exiv2::byte* buf %{
    if (_global_len < arg1->size()) {
        PyErr_Format(PyExc_ValueError,
            "in method '$symname', '$1_name' value is a %d byte buffer,"
            " %d bytes needed",
            _global_len, arg1->size());
        SWIG_fail;
    }
%}

// ---- Macros ----
// Macro for all subclasses of Exiv2::Value
%define VALUE_SUBCLASS(type_name, part_name)
%ignore type_name::value_;
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
%feature("python:slot", "sq_length", functype="lenfunc") type_name::__len__;
%feature("python:slot", "sq_item",
         functype="ssizeargfunc") type_name::__getitem__;
%noexception type_name::__len__;
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
%template() std::vector<item_type>;
%feature("docstring") Exiv2::ValueType<item_type>
"Sequence of " #item_type " values."
%feature("docstring") Exiv2::ValueType<item_type>::append
"Append a " #item_type " component to the value."
%extend Exiv2::ValueType<item_type> {
    // Constructor, reads values from a Python list
    ValueType<item_type>(Exiv2::ValueType<item_type>::ValueList value) {
        Exiv2::ValueType<item_type>* result = new Exiv2::ValueType<item_type>();
        result->value_ = value;
        return result;
    }
    item_type __getitem__(long multi_idx) {
        return $self->value_.at(multi_idx);
    }
    void __setitem__(long multi_idx, item_type value) {
        $self->value_.at(multi_idx) = value;
    }
    void append(item_type value) {
        $self->value_.push_back(value);
    }
}
%template(type_name) Exiv2::ValueType<item_type>;
%enddef // VALUETYPE

// Allow Date and Time to be constructed from sequences or set from int values
%extend Exiv2::DateValue {
    DateValue(const Exiv2::DateValue::Date &date) {
        return new Exiv2::DateValue(date.year, date.month, date.day);
    }
    void setDate(int year, int month, int day) {
        Exiv2::DateValue::Date date;
        date.year = year;
        date.month = month;
        date.day = day;
        $self->setDate(date);
    }
}
%extend Exiv2::TimeValue {
    TimeValue(const Exiv2::TimeValue::Time &time) {
        return new Exiv2::TimeValue(time.hour, time.minute, time.second,
                                    time.tzHour, time.tzMinute);
    }
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

// Make LangAltValue like a Python dict
%feature("python:slot", "tp_iter",
         functype="getiterfunc") Exiv2::LangAltValue::__iter__;
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") Exiv2::LangAltValue::__getitem__;
%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") Exiv2::LangAltValue::__setitem__;
%feature("python:slot", "sq_contains",
         functype="objobjproc") Exiv2::LangAltValue::__contains__;
%feature("docstring") Exiv2::LangAltValue::keys
"Get keys (i.e. languages) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::values
"Get values (i.e. text strings) of the LangAltValue components."
%feature("docstring") Exiv2::LangAltValue::items
"Get key, value pairs (i.e. language, text) of the LangAltValue
components. These are also available by iterating over the
LangAltValue."
%template() std::map<std::string, std::string, Exiv2::LangAltValueComparator>;
// typemaps to convert Python dict to Exiv2::LangAltValue::ValueType
%typemap(in) Exiv2::LangAltValue::ValueType {
    PyObject* key;
    PyObject* value;
    Py_ssize_t pos = 0;
    while (PyDict_Next($input, &pos, &key, &value)) {
        $1.insert(std::make_pair(
            SWIG_Python_str_AsChar(key), SWIG_Python_str_AsChar(value)));
    }
}
%typemap(typecheck,
         precedence=SWIG_TYPECHECK_POINTER) Exiv2::LangAltValue::ValueType %{
    $1 = PyDict_Check($input);
%}
// helper functions
%{
static PyObject* LangAltValue_get_key(
        Exiv2::LangAltValue::ValueType::iterator i) {
    return PyString_FromString(i->first.c_str());
};
static PyObject* LangAltValue_get_value(
        Exiv2::LangAltValue::ValueType::iterator i) {
    return PyString_FromString(i->second.c_str());
};
static PyObject* LangAltValue_get_item(
        Exiv2::LangAltValue::ValueType::iterator i) {
    return Py_BuildValue("(ss)", i->first.c_str(), i->second.c_str());
};
static PyObject* LangAltValue_to_list(
        Exiv2::LangAltValue::ValueType value,
        PyObject* (*convert)(Exiv2::LangAltValue::ValueType::iterator)) {
    PyObject* result = PyList_New(0);
    if (!result)
        return result;
    Exiv2::LangAltValue::ValueType::iterator e = value.end();
    for (Exiv2::LangAltValue::ValueType::iterator i = value.begin();
                                                  i != e; ++i) {
        if (PyList_Append(result, convert(i))) {
            Py_DECREF(result);
            return NULL;
        }
    }
    return result;
};
%}
%exception Exiv2::LangAltValue::__getitem__ {
    $action
    if (PyErr_Occurred())
        SWIG_fail;
}
%extend Exiv2::LangAltValue {
    // Constructor, reads values from a Python dict
    LangAltValue(Exiv2::LangAltValue::ValueType value) {
        Exiv2::LangAltValue* result = new Exiv2::LangAltValue;
        result->value_ = value;
        return result;
    }
    PyObject* keys() {
        return LangAltValue_to_list($self->value_, &LangAltValue_get_key);
    }
    PyObject* values() {
        return LangAltValue_to_list($self->value_, &LangAltValue_get_value);
    }
    PyObject* items() {
        return LangAltValue_to_list($self->value_, &LangAltValue_get_item);
    }
    PyObject* __iter__() {
        return PySeqIter_New(
            LangAltValue_to_list($self->value_, &LangAltValue_get_item));
    }
    std::string __getitem__(const std::string& key) {
        try {
            return $self->value_.at(key);
        } catch(std::out_of_range const&) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return "";
        }
    }
    void __setitem__(const std::string& key, const std::string& value) {
        $self->value_[key] = value;
    }
#if defined(SWIGPYTHON_BUILTIN)
    PyObject* __setitem__(const std::string& key) {
#else
    PyObject* __delitem__(const std::string& key) {
#endif
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
%noexception Exiv2::Value::__len__;
%noexception Exiv2::Value::count;
%noexception Exiv2::Value::size;
%noexception Exiv2::Value::ok;
%noexception Exiv2::Value::typeId;

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

%ignore Exiv2::getValue;
%ignore LARGE_INT;

// Some classes wrongly appear to be abstract to SWIG
%feature("notabstract") Exiv2::LangAltValue;
%feature("notabstract") Exiv2::XmpArrayValue;
%feature("notabstract") Exiv2::XmpTextValue;

// Ignore ambiguous constructor
%ignore Exiv2::ValueType< int32_t >::ValueType(int const &);

// Ignore stuff Python can't use or SWIG can't handle
%ignore Exiv2::operator<<;
%ignore Exiv2::Value::operator=;
%ignore Exiv2::Value::write;
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
