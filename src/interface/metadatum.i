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

%module(package="exiv2") metadatum

#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=314     // 'print' is a python keyword, renaming to '_print'

%include "preamble.i"

%include "std_string.i"

%import "types.i"
%import "value.i"

wrap_auto_unique_ptr(Exiv2::Key);

STR(Exiv2::Key, key)

%ignore Exiv2::Key::operator=;
%ignore Exiv2::Metadatum::operator=;

%include "exiv2/metadatum.hpp"
