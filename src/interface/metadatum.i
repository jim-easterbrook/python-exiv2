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
%constant char* __doc__ = "Exiv2 metadatum base class.";
#endif

%namewarn("") "print"; // don't rename print methods

%include "shared/preamble.i"
%include "shared/containers.i"

%import "value.i"

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

// Extend base type
%feature("python:slot", "tp_str", functype="reprfunc")
    Exiv2::Metadatum::__str__;
%extend Exiv2::Metadatum {
    std::string __str__() {
        return $self->key() + ": " + $self->print();
    }
}

%ignore Exiv2::Key::~Key;
%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum::~Metadatum;
%ignore Exiv2::Metadatum::operator=;
%ignore Exiv2::cmpMetadataByKey;
%ignore Exiv2::cmpMetadataByTag;

%include "exiv2/metadatum.hpp"
