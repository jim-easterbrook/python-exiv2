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

%module(package="exiv2") types

%include "preamble.i"

%include "stdint.i"
%include "std_pair.i"

// Function to set location of localisation files
// (types.hpp includes exiv2's localisation stuff)
#ifdef EXV_ENABLE_NLS
%{
#include <libintl.h>
%}
%inline %{
void _set_locale_dir(const char* dirname) {
    // initialise libexiv2's translator by asking it for a string
    Exiv2::exvGettext("dummy");
    // reset libexiv2's translator to use our directory
    bindtextdomain("exiv2", dirname);
};
%}
#else   // EXV_ENABLE_NLS
%inline %{
void _set_locale_dir(const char* dirname) {
};
%}
#endif  // EXV_ENABLE_NLS

// Make Exiv2::DataBuf behave more like a tuple of ints
%feature("python:slot", "mp_length", functype="lenfunc") Exiv2::DataBuf::__len__;
%feature("python:slot", "mp_subscript",
         functype="binaryfunc") Exiv2::DataBuf::__getitem__;
%extend Exiv2::DataBuf {
#if EXIV2_VERSION_HEX < 0x01000000
    long __len__() {
        return $self->size_;
    }
    PyObject* __getitem__(PyObject* idx) {
        PyErr_WarnEx(PyExc_DeprecationWarning,
            "use 'DataBuf.data()' to get a data buffer",
            1);
        if (PySlice_Check(idx)) {
            Py_ssize_t i1, i2, di, sl;
            if (PySlice_GetIndicesEx(idx, $self->size_, &i1, &i2, &di, &sl))
                return NULL;
            PyObject* result = PyTuple_New(sl);
            Exiv2::byte* ptr = $self->pData_ + i1;
            for (Py_ssize_t i = 0; i < sl; ++i) {
                PyTuple_SetItem(result, i, PyLong_FromLong((long)*ptr));
                ptr += di;
            }
            return result;
        }
        if (PyLong_Check(idx)) {
            long i = PyLong_AsLong(idx);
            if (i < 0)
                i += $self->size_;
            if ((i < 0) || (i >= $self->size_)) {
                PyErr_SetString(PyExc_IndexError, "index out of range");
                return NULL;
            }
            return PyLong_FromLong((long)*($self->pData_ + i));
        }
        return PyErr_Format(PyExc_TypeError,
            "indices must be integers or slices, not %s",
            Py_TYPE(idx)->tp_name);
    }
#else
    long __len__() {
        return $self->size();
    }
#endif
}

// Memory efficient conversion of Exiv2::DataBuf return values
%typemap(out) Exiv2::DataBuf %{
    $result = SWIG_NewPointerObj(
        new $type($1), $&1_descriptor, SWIG_POINTER_OWN);
%}

// Expose Exiv2::DataBuf contents as a Python buffer
%feature("python:bf_getbuffer",
         functype="getbufferproc") Exiv2::DataBuf "Exiv2_DataBuf_getbuf";
%{
static int Exiv2_DataBuf_getbuf(PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::DataBuf* self = 0;
    PyErr_WarnEx(PyExc_DeprecationWarning,
        "use 'DataBuf.data()' to get a data buffer", 1);
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__DataBuf, 0);
    if (!SWIG_IsOK(res)) {
        PyErr_SetNone(PyExc_BufferError);
        view->obj = NULL;
        return -1;
    }
%}
#if EXIV2_VERSION_HEX < 0x01000000
%{
    return PyBuffer_FillInfo(
        view, exporter, self->pData_, self->size_, 1, flags);
}
%}
#else
%{
    return PyBuffer_FillInfo(
        view, exporter, self->data(), self->size(), 1, flags);
}
%}
#endif

// Convert pData_ and data() result to an object with a buffer interface
#if EXIV2_VERSION_HEX < 0x01000000
%typemap(out) (Exiv2::byte* pData_), (Exiv2::byte* data) %{
    $result = SWIG_NewPointerObj(new byte_buffer($1, arg1->size_),
        $descriptor(byte_buffer*), SWIG_POINTER_OWN);
%}
// return value keeps a reference to the data it points to
KEEP_REFERENCE(Exiv2::byte* pData_)
KEEP_REFERENCE(Exiv2::byte* data)
#else
BYTE_BUFFER_TYPEMAPS(Exiv2::byte* data)
#endif

#ifndef SWIGIMPORTED
BYTE_BUFFER_CLASS()
#endif

// Backport Exiv2 v1.0.0 methods
#if EXIV2_VERSION_HEX < 0x01000000
%extend Exiv2::DataBuf {
    Exiv2::byte* data() const { return $self->pData_; }
    size_t size() const { return $self->size_; }
}
#endif

// Some things are read-only
%immutable Exiv2::DataBuf::size_;
%immutable Exiv2::DataBuf::pData_;

// Hide parts of Exiv2::DataBuf that Python shouldn't see
%ignore Exiv2::DataBuf::c_data;
%ignore Exiv2::DataBuf::c_str;
%ignore Exiv2::DataBuf::release;
%ignore Exiv2::DataBuf::reset;
%ignore Exiv2::DataBuf::read_uint8;
%ignore Exiv2::DataBuf::read_uint16;
%ignore Exiv2::DataBuf::read_uint32;
%ignore Exiv2::DataBuf::read_uint64;
%ignore Exiv2::DataBuf::write_uint8;
%ignore Exiv2::DataBuf::write_uint16;
%ignore Exiv2::DataBuf::write_uint32;
%ignore Exiv2::DataBuf::write_uint64;
%ignore Exiv2::DataBuf::operator=;
// Exiv2 v1.0.0 makes DataBuf iterable. We don't need that as we already have
// a Python buffer interface.
%ignore Exiv2::DataBuf::iterator;
%ignore Exiv2::DataBuf::const_iterator;
%ignore Exiv2::DataBuf::begin;
%ignore Exiv2::DataBuf::cbegin;
%ignore Exiv2::DataBuf::end;
%ignore Exiv2::DataBuf::cend;

// Make various enums more Pythonic
ENUM(AccessMode, "An identifier for each mode of metadata support.",
        "none",      Exiv2::amNone,
        "Read",      Exiv2::amRead,
        "Write",     Exiv2::amWrite,
        "ReadWrite", Exiv2::amReadWrite);

ENUM(ByteOrder, "Type to express the byte order (little or big endian).",
        "invalidByteOrder", Exiv2::invalidByteOrder,
        "littleEndian",     Exiv2::littleEndian,
        "bigEndian",        Exiv2::bigEndian);

ENUM(MetadataId, "An identifier for each type of metadata.",
        "none",       Exiv2::mdNone,
        "Exif",       Exiv2::mdExif,
        "Iptc",       Exiv2::mdIptc,
        "Comment",    Exiv2::mdComment,
        "Xmp",        Exiv2::mdXmp,
        "IccProfile", Exiv2::mdIccProfile);

ENUM(TypeId, "Exiv2 value type identifiers.\n"
"\nUsed primarily as identifiers when creating Exiv2 Value instances. See"
"\nexiv2.Value.create(). 0x0000 to 0xffff are reserved for TIFF (Exif) types.",
        "unsignedByte",     Exiv2::unsignedByte,
        "asciiString",      Exiv2::asciiString,
        "unsignedShort",    Exiv2::unsignedShort,
        "unsignedLong",     Exiv2::unsignedLong,
        "unsignedRational", Exiv2::unsignedRational,
        "signedByte",       Exiv2::signedByte,
        "undefined",        Exiv2::undefined,
        "signedShort",      Exiv2::signedShort,
        "signedLong",       Exiv2::signedLong,
        "signedRational",   Exiv2::signedRational,
        "tiffFloat",        Exiv2::tiffFloat,
        "tiffDouble",       Exiv2::tiffDouble,
        "tiffIfd",          Exiv2::tiffIfd,
        "string",           Exiv2::string,
        "date",             Exiv2::date,
        "time",             Exiv2::time,
        "comment",          Exiv2::comment,
        "directory",        Exiv2::directory,
        "xmpText",          Exiv2::xmpText,
        "xmpAlt",           Exiv2::xmpAlt,
        "xmpBag",           Exiv2::xmpBag,
        "xmpSeq",           Exiv2::xmpSeq,
        "langAlt",          Exiv2::langAlt,
        "invalidTypeId",    Exiv2::invalidTypeId,
        "lastTypeId",       Exiv2::lastTypeId);

// Ignore slice stuff that SWIG can't understand
%ignore makeSlice;

// Ignore DataBufRef auxiliary type
%ignore Exiv2::DataBufRef;
%ignore Exiv2::DataBuf::DataBuf(const DataBufRef&);
%ignore Exiv2::DataBuf::DataBuf(const DataBuf&);
%ignore Exiv2::DataBuf::operator DataBufRef;

// Ignore stuff that Python doesn't need
%ignore Exiv2::exifTime;
%ignore Exiv2::isHex;
%ignore Exiv2::exvGettext;
%ignore Exiv2::WriteMethod;
%ignore Exiv2::getDouble;
%ignore Exiv2::getFloat;
%ignore Exiv2::getLong;
%ignore Exiv2::getRational;
%ignore Exiv2::getShort;
%ignore Exiv2::getULong;
%ignore Exiv2::getULongLong;
%ignore Exiv2::getURational;
%ignore Exiv2::getUShort;
%ignore Exiv2::getValue;
%ignore Exiv2::d2Data;
%ignore Exiv2::f2Data;
%ignore Exiv2::l2Data;
%ignore Exiv2::r2Data;
%ignore Exiv2::s2Data;
%ignore Exiv2::ul2Data;
%ignore Exiv2::ull2Data;
%ignore Exiv2::ur2Data;
%ignore Exiv2::us2Data;
%ignore Exiv2::toData;
%ignore Exiv2::floatToRationalCast;
%ignore Exiv2::hexdump;
%ignore Exiv2::parseLong;
%ignore Exiv2::parseFloat;
%ignore Exiv2::parseRational;
%ignore Exiv2::parseInt64;
%ignore Exiv2::parseUint32;
%ignore Exiv2::s2ws;
%ignore Exiv2::ws2s;
%ignore Exiv2::operator<<;
%ignore Exiv2::operator>>;

%include "exiv2/types.hpp"

%template(URational) std::pair<uint32_t, uint32_t>;
%template(Rational) std::pair<int32_t, int32_t>;
