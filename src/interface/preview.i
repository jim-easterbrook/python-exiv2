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

%module(package="exiv2") preview

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Access to preview images.

For Exif thumbnail images see the :py:class:`ExifThumb` class.";
#endif

// We don't need Python access to SwigPyIterator
%ignore SwigPyIterator;

%include "shared/preamble.i"
%include "shared/buffers.i"
%include "shared/exception.i"
%include "shared/exv_options.i"
%include "shared/keep_reference.i"
%include "shared/struct_dict.i"
%include "shared/windows_path.i"

%include "std_string.i"
%include "std_vector.i"

%import "image.i";

// Catch all C++ exceptions
EXCEPTION()

%fragment("EXV_USE_CURL");
%fragment("EXV_USE_SSH");
%fragment("EXV_ENABLE_FILESYSTEM");
EXV_ENABLE_FILESYSTEM_FUNCTION(Exiv2::PreviewImage::writeFile)

// Some calls don't raise exceptions
%noexception Exiv2::PreviewImage::__len__;
%noexception Exiv2::PreviewImage::extension;
%noexception Exiv2::PreviewImage::height;
%noexception Exiv2::PreviewImage::id;
%noexception Exiv2::PreviewImage::mimeType;
%noexception Exiv2::PreviewImage::pData;
%noexception Exiv2::PreviewImage::size;
%noexception Exiv2::PreviewImage::wextension;
%noexception Exiv2::PreviewImage::width;

// Convert path encoding on Windows
WINDOWS_PATH(const std::string& path)
WINDOWS_PATH_OUT(extension)

// Convert getPreviewProperties result to a Python tuple
%template() std::vector<Exiv2::PreviewProperties>;

// Make sure PreviewManager keeps a reference to the image it's using
KEEP_REFERENCE_EX(Exiv2::PreviewManager*, args)

// Enable len(PreviewImage)
%feature("python:slot", "sq_length", functype="lenfunc")
    Exiv2::PreviewImage::__len__;
%extend Exiv2::PreviewImage {
    size_t __len__() {
        return $self->size();
    }
}

// Expose Exiv2::PreviewImage contents as a Python buffer
%fragment("get_ptr_size"{Exiv2::PreviewImage}, "header") {
static bool get_ptr_size(Exiv2::PreviewImage* self, bool is_writeable,
                         Exiv2::byte*& ptr, Py_ssize_t& size) {
    ptr = (Exiv2::byte*)self->pData();
    size = self->size();
    return true;
};
}
EXPOSE_OBJECT_BUFFER(Exiv2::PreviewImage, false, false)

// Convert pData result to a Python memoryview
RETURN_VIEW(Exiv2::byte* pData, arg1->size(), PyBUF_READ,
            Exiv2::PreviewImage::pData)

// Give Exiv2::PreviewProperties dict-like behaviour
STRUCT_DICT(Exiv2::PreviewProperties)

%immutable Exiv2::PreviewProperties::mimeType_;
%immutable Exiv2::PreviewProperties::extension_;
%immutable Exiv2::PreviewProperties::wextension_;
%immutable Exiv2::PreviewProperties::size_;
%immutable Exiv2::PreviewProperties::width_;
%immutable Exiv2::PreviewProperties::height_;
%immutable Exiv2::PreviewProperties::id_;

%ignore Exiv2::PreviewImage::operator=;
%ignore Exiv2::PreviewProperties::PreviewProperties;

%include "exiv2/preview.hpp"
