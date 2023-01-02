// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-22  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%import "image.i";
%import "types.i";

// Convert getPreviewProperties result to a Python list
%typemap(out) Exiv2::PreviewPropertiesList {
    $result = PyList_New(0);
    if (!$result) {
        SWIG_fail;
    }
    Exiv2::PreviewPropertiesList::iterator e = $1.end();
    for (Exiv2::PreviewPropertiesList::iterator i = $1.begin(); i != e; ++i) {
        if (PyList_Append($result, SWIG_NewPointerObj(
                new Exiv2::PreviewProperties(*i),
                $descriptor(Exiv2::PreviewProperties*), SWIG_POINTER_OWN))) {
            SWIG_fail;
        }
    }
}

// Make sure PreviewManager keeps a reference to the image it's using
%typemap(ret) Exiv2::PreviewManager* %{
    if (PyObject_SetAttrString($result, "_refers_to", swig_obj[0])) {
        SWIG_fail;
    }
%}

// Convert pData() result to an object with a buffer interface
BYTE_BUFFER_TYPEMAPS(Exiv2::byte* pData)
#ifndef SWIGIMPORTED
BYTE_BUFFER_CLASS()
#endif

%immutable Exiv2::PreviewProperties::mimeType_;
%immutable Exiv2::PreviewProperties::extension_;
%immutable Exiv2::PreviewProperties::wextension_;
%immutable Exiv2::PreviewProperties::size_;
%immutable Exiv2::PreviewProperties::width_;
%immutable Exiv2::PreviewProperties::height_;
%immutable Exiv2::PreviewProperties::id_;

%ignore Exiv2::PreviewImage::operator=;

%include "exiv2/preview.hpp"
