// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-26  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") xmp

#ifndef SWIGIMPORTED
%constant char* __doc__ = "XMP metadatum, container and iterators.";
#endif

#pragma SWIG nowarn=508 // Declaration of '__str__' shadows declaration accessible via operator->()

%include "shared/preamble.i"
%include "shared/containers.i"

%include "stdint.i"
%include "std_string.i"

%import "properties.i"

// Add inheritance diagrams to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Metadatum
    :top-classes: exiv2.metadatum.Metadatum
    :parts: 1
    :include-subclasses:

.. inheritance-diagram:: exiv2.xmp.Xmpdatum_pointer
    :top-classes: exiv2.xmp.Xmpdatum_pointer
    :parts: 1
    :include-subclasses:
'''
%}

// Catch all C++ exceptions
EXCEPTION()

DATA_CONTAINER(XmpData, Xmpdatum, XmpKey,
    Exiv2::XmpProperties::propertyType(Exiv2::XmpKey(datum->key())))

// Typemaps for different uses of xmpPacket.
// Exiv2::Image::xmpPacket return value
%apply const std::string & {std::string &xmpPacket()};

// Exiv2::Image::setXmpPacket input value
%typemap(in) const std::string &xmpPacket = std::string &INPUT;
%typemap(argout) const std::string &xmpPacket ""

// Exiv2::XmpParser::encode output value
%typemap(in, numinputs=0) std::string &xmpPacket = std::string &OUTPUT;
%typemap(argout) std::string &xmpPacket = std::string &OUTPUT;
%typemap(freearg) std::string &xmpPacket "";

// Default typemaps for Exiv2::XmpParser::encode
%typemap(default) uint16_t formatFlags %{
    $1 = Exiv2::XmpParser::XmpFormatFlags::useCompactFormat;
%}
%typemap(default) uint32_t padding %{ $1 = 0; %}
%ignore Exiv2::XmpParser::encode(std::string &, const XmpData &);
%ignore Exiv2::XmpParser::encode(std::string &, const XmpData &, uint16_t);

// Initialise XMP parser during module initialisation
// A lock function is used to make NS registration thread safe
// See https://dev.exiv2.org/projects/exiv2/wiki/Thread_safety
%{
#include <mutex>
class XmpLock {
private:
    std::mutex lock;
public:
    static void LockUnlock(void* pLockData, bool lockUnlock) {
        XmpLock* self = reinterpret_cast<XmpLock*>(pLockData);
        if (self) {
            lockUnlock ? self->lock.lock() : self->lock.unlock();
        }
    }
};
static XmpLock xmp_lock;
%}
%init %{
    if (!Exiv2::XmpParser::initialize(xmp_lock.LockUnlock, &xmp_lock)) {
        PyErr_SetString(
            PyExc_RuntimeError, "XMP Toolkit initialisation failed");
        return -1;
    }
%}

// Deprecated since 2026-08-26
DEPRECATE(Exiv2::XmpParser::initialize, "XMP Toolkit is already initialised")

// Ignore XmpLockFct - Python can't use it anyway
%ignore Exiv2::XmpParser::initialize(XmpParser::XmpLockFct, void*);
%ignore Exiv2::XmpParser::initialize(XmpParser::XmpLockFct);

// Make enums more Pythonic
#ifndef SWIGIMPORTED
DEFINE_CLASS_ENUM(XmpParser, XmpFormatFlags,)
#else
IMPORT_CLASS_ENUM(_xmp, XmpParser, XmpFormatFlags)
#endif

// Ignore const overloads of some methods
%ignore Exiv2::XmpData::begin() const;
%ignore Exiv2::XmpData::end() const;
%ignore Exiv2::XmpData::findKey(XmpKey const &) const;

// Ignore other stuff Python doesn't need or can't use
%ignore Exiv2::operatorHelper;
%ignore Exiv2::XmpData::operator[];
%ignore Exiv2::XmpParser::decode;

%include "exiv2/xmp_exiv2.hpp"
