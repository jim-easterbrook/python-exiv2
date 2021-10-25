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

%module(package="exiv2") preview

%include "preamble.i"

%include "std_string.i"
%include "std_vector.i"

%import "image.i";
%import "types.i";

%immutable Exiv2::PreviewProperties::mimeType_;
%immutable Exiv2::PreviewProperties::extension_;
%immutable Exiv2::PreviewProperties::wextension_;
%immutable Exiv2::PreviewProperties::size_;
%immutable Exiv2::PreviewProperties::width_;
%immutable Exiv2::PreviewProperties::height_;
%immutable Exiv2::PreviewProperties::id_;

%ignore Exiv2::PreviewImage::operator=;

%include "exiv2/preview.hpp"

%template(Exiv2PreviewPropertiesList) std::vector<Exiv2::PreviewProperties>;
