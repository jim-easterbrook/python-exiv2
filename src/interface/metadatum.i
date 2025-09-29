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

%module(package="exiv2") metadatum

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 metadatum and key base classes.";
#endif

%namewarn("") "print"; // don't rename print methods

%include "shared/preamble.i"
%include "shared/slots.i"

%import "value.i"

// Add inheritance diagram to Sphinx docs
%pythoncode %{
import sys
if 'sphinx' in sys.modules:
    __doc__ += '''

.. inheritance-diagram:: exiv2.metadatum.Key
    :top-classes: exiv2.metadatum.Key
    :parts: 1
    :include-subclasses:

.. inheritance-diagram:: exiv2.metadatum.Metadatum
    :top-classes: exiv2.metadatum.Metadatum
    :parts: 1
    :include-subclasses:
'''
%}

// Catch all C++ exceptions
EXCEPTION()

// Use default parameter for toFloat etc.
%typemap(default) long n, size_t n {$1 = 0;}
%ignore Exiv2::Metadatum::toFloat() const;
%ignore Exiv2::Metadatum::toInt64() const;
%ignore Exiv2::Metadatum::toLong() const;
%ignore Exiv2::Metadatum::toRational() const;
%ignore Exiv2::Metadatum::toString() const;
%ignore Exiv2::Metadatum::toString(BUFLEN_T) const;
%ignore Exiv2::Metadatum::toUint32() const;

// Use default parameter in print() and write()
%typemap(default) const Exiv2::ExifData* pMetadata {$1 = NULL;}
%ignore Exiv2::Metadatum::print() const;
%ignore Exiv2::Metadatum::write(std::ostream &) const;

%define EXTEND_KEY(key_type)
UNIQUE_PTR(key_type);
%feature("python:slot", "tp_str", functype="reprfunc") key_type::key;
%enddef // EXTEND_KEY

EXTEND_KEY(Exiv2::Key);

// Deprecate some base class methods since 2025-08-25
DEPRECATE_FUNCTION(Exiv2::Metadatum::copy, true)
DEPRECATE_FUNCTION(Exiv2::Metadatum::write, true)

// Add __str__ slot to base type
TP_STR(Exiv2::Metadatum, metadatum_str(self))

// Metadatum pointer template classes from metadatum_pointer.hpp
%feature("docstring") MetadatumPointerBase
"Base class for pointers to :class:`Metadatum` objects."

TP_STR(MetadatumPointerBase, self->__str__())
%ignore MetadatumPointerBase::MetadatumPointerBase;
%ignore MetadatumPointerBase::~MetadatumPointerBase;
%ignore MetadatumPointerBase::operator*;
%ignore MetadatumPointerBase::size;
%ignore MetadatumPointerBase::count;
%ignore MetadatumPointerBase::_invalidate;
%ignore MetadatumPointerBase::__str__;

%ignore MetadatumPointer::MetadatumPointer;
%ignore MetadatumPointer::~MetadatumPointer;
%ignore MetadatumPointer::operator*;
%ignore MetadatumPointer::size;
%ignore MetadatumPointer::count;
%ignore MetadatumPointer::_invalidate;
%ignore MetadatumPointer::__str__;

%feature("python:slot", "tp_iter", functype="getiterfunc")
    MetadataIterator::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    MetadataIterator::__next__;
%noexception MetadataIterator::__iter__;
%ignore MetadataIterator::MetadataIterator;
%ignore MetadataIterator::_invalidated;
%ignore MetadataIterator::_ptr;
KEEP_REFERENCE(MetadataIterator*)

%ignore MetadatumReference::MetadatumReference;

%ignore metadatum_str;


%ignore Exiv2::Key::~Key;
%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum::~Metadatum;
%ignore Exiv2::Metadatum::operator=;
%ignore Exiv2::cmpMetadataByKey;
%ignore Exiv2::cmpMetadataByTag;

%include "exiv2/metadatum.hpp"
%include "metadatum_pointer.hpp"
