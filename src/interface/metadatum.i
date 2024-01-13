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

%module(package="exiv2") metadatum

#pragma SWIG nowarn=314     // 'print' is a python keyword, renaming to '_print'

%include "shared/preamble.i"
%include "shared/exception.i"
%include "shared/keep_reference.i"
%include "shared/unique_ptr.i"

%include "std_string.i"

%import "types.i"
%import "value.i"

// Catch all C++ exceptions
EXCEPTION()

// Keep a reference to Metadatum when calling value()
KEEP_REFERENCE(const Exiv2::Value&)

%define EXTEND_KEY(key_type)
UNIQUE_PTR(key_type);
%feature("python:slot", "tp_str", functype="reprfunc") key_type::key;
%enddef // EXTEND_KEY

#ifndef SWIGIMPORTED
%feature("python:slot", "tp_str", functype="reprfunc") Exiv2::Metadatum::__str__;
%extend Exiv2::Metadatum {
    std::string __str__() {
        return $self->key() + ": " + $self->print();
    }
}
#endif

%ignore Exiv2::Key;
%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum::operator=;
%ignore Exiv2::Metadatum::write;
%ignore Exiv2::cmpMetadataByKey;
%ignore Exiv2::cmpMetadataByTag;

%include "exiv2/metadatum.hpp"
