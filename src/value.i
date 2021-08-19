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

%module(package="exiv2") value

#pragma SWIG nowarn=325     // Nested struct not currently supported (X ignored)
#pragma SWIG nowarn=362     // operator= ignored
#pragma SWIG nowarn=403     // Class 'X' might be abstract, no constructors generated, Method Y might not be implemented.

%include "preamble.i"

%import "types.i"

%include "std_auto_ptr.i"
%include "std_string.i"

%auto_ptr(Exiv2::AsciiValue)
%auto_ptr(Exiv2::CommentValue)
%auto_ptr(Exiv2::DataValue)
%auto_ptr(Exiv2::DateValue)
%auto_ptr(Exiv2::LangAltValue)
%auto_ptr(Exiv2::StringValue)
%auto_ptr(Exiv2::StringValueBase)
%auto_ptr(Exiv2::TimeValue)
%auto_ptr(Exiv2::Value)
%auto_ptr(Exiv2::XmpArrayValue)
%auto_ptr(Exiv2::XmpTextValue)

STR(Exiv2::Value, toString)

%ignore Exiv2::getValue;
%ignore Exiv2::Value::dataArea;

%include "exiv2/value.hpp"
