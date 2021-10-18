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

%module(package="exiv2") types

#pragma SWIG nowarn=202     // Could not evaluate expression...
#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=503     // Can't wrap 'X' unless renamed to a valid identifier.
#pragma SWIG nowarn=509     // Overloaded method X effectively ignored, as it is shadowed by Y.

%include "preamble.i"

%include "stdint.i"
%include "std_pair.i"

// Add __len__ to Exiv2::DataBuf
%feature("python:slot", "sq_length", functype="lenfunc") Exiv2::DataBuf::__len__;
%extend Exiv2::DataBuf {
#if EXIV2_VERSION_HEX < 0x01000000
    long __len__() {return $self->size_;}
#else
    long __len__() {return $self->size();}
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
// Hide parts of Exiv2::DataBuf that Python shouldn't see
%ignore Exiv2::DataBuf::pData_;
%ignore Exiv2::DataBuf::size_;
%ignore Exiv2::DataBuf::operator=;

// Make various enums more Pythonic
ENUM(AccessMode,
        none =      Exiv2::amNone,
        Read =      Exiv2::amRead,
        Write =     Exiv2::amWrite,
        ReadWrite = Exiv2::amReadWrite);

ENUM(MetadataId,
        none =       Exiv2::mdNone,
        Exif =       Exiv2::mdExif,
        Iptc =       Exiv2::mdIptc,
        Comment =    Exiv2::mdComment,
        Xmp =        Exiv2::mdXmp,
        IccProfile = Exiv2::mdIccProfile);

ENUM(TypeId,
        unsignedByte =     Exiv2::unsignedByte,
        asciiString =      Exiv2::asciiString,
        unsignedShort =    Exiv2::unsignedShort,
        unsignedLong =     Exiv2::unsignedLong,
        unsignedRational = Exiv2::unsignedRational,
        signedByte =       Exiv2::signedByte,
        undefined =        Exiv2::undefined,
        signedShort =      Exiv2::signedShort,
        signedLong =       Exiv2::signedLong,
        signedRational =   Exiv2::signedRational,
        tiffFloat =        Exiv2::tiffFloat,
        tiffDouble =       Exiv2::tiffDouble,
        tiffIfd =          Exiv2::tiffIfd,
        string =           Exiv2::string,
        date =             Exiv2::date,
        time =             Exiv2::time,
        comment =          Exiv2::comment,
        directory =        Exiv2::directory,
        xmpText =          Exiv2::xmpText,
        xmpAlt =           Exiv2::xmpAlt,
        xmpBag =           Exiv2::xmpBag,
        xmpSeq =           Exiv2::xmpSeq,
        langAlt =          Exiv2::langAlt,
        invalidTypeId =    Exiv2::invalidTypeId,
        lastTypeId =       Exiv2::lastTypeId);

// Ignore slice stuff that SWIG can't understand
%ignore makeSlice;

// Ignore stuff that Python doesn't need
%ignore Exiv2::ByteOrder;
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
%ignore Exiv2::ur2Data;
%ignore Exiv2::us2Data;
%ignore Exiv2::toData;
%ignore Exiv2::floatToRationalCast;
%ignore Exiv2::hexdump;
%ignore Exiv2::parseLong;
%ignore Exiv2::parseFloat;
%ignore Exiv2::parseRational;
%ignore Exiv2::s2ws;
%ignore Exiv2::ws2s;
%ignore Exiv2::exvGettext;
%ignore Exiv2::operator<<;

%include "exiv2/types.hpp"

%template(URational) std::pair<uint32_t, uint32_t>;
%template(Rational) std::pair<int32_t, int32_t>;
