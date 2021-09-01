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

%module(package="exiv2") tags

#pragma SWIG nowarn=305     // Bad constant value (ignored).
#pragma SWIG nowarn=325     // Nested struct not currently supported (X ignored)
#pragma SWIG nowarn=362     // operator= ignored

%include "preamble.i"

%import "metadatum.i";

%include "std_auto_ptr.i"

%auto_ptr(Exiv2::ExifKey)

%immutable Exiv2::GroupInfo::ifdName_;
%immutable Exiv2::GroupInfo::groupName_;
%immutable Exiv2::TagInfo::name_;
%immutable Exiv2::TagInfo::title_;
%immutable Exiv2::TagInfo::desc_;

%include "exiv2/tags.hpp"
