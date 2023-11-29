// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-23  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

// Enable len(PreviewImage)
%feature("python:slot", "mp_length", functype="lenfunc")
    Exiv2::PreviewImage::__len__;
%extend Exiv2::PreviewImage {
    size_t __len__() {
        return $self->size();
    }
}

// Expose Exiv2::PreviewImage contents as a Python buffer
%feature("python:bf_getbuffer", functype="getbufferproc")
    Exiv2::PreviewImage "PreviewImage_getbuf";
%{
static int PreviewImage_getbuf(PyObject* exporter, Py_buffer* view,
                               int flags) {
    Exiv2::PreviewImage* self = 0;
    int res = SWIG_ConvertPtr(
        exporter, (void**)&self, SWIGTYPE_p_Exiv2__PreviewImage, 0);
    if (!SWIG_IsOK(res))
        goto fail;
    return PyBuffer_FillInfo(
        view, exporter, (void*)self->pData(), self->size(), 1, flags);
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
}
%}

// Convert pData result to a Python memoryview
// WARNING: return value does not keep a reference to the data it points to
%typemap(out) Exiv2::byte* pData %{
    $result = PyMemoryView_FromMemory((char*)$1, arg1->size(), PyBUF_READ);
%}
%feature("docstring") Exiv2::PreviewImage::pData
"Returns a temporary Python memoryview of the image data.

WARNING: do not modify or delete the PreviewImage object while using
the memoryview."

%immutable Exiv2::PreviewProperties::mimeType_;
%immutable Exiv2::PreviewProperties::extension_;
%immutable Exiv2::PreviewProperties::wextension_;
%immutable Exiv2::PreviewProperties::size_;
%immutable Exiv2::PreviewProperties::width_;
%immutable Exiv2::PreviewProperties::height_;
%immutable Exiv2::PreviewProperties::id_;

%ignore Exiv2::PreviewImage::operator=;

%include "exiv2/preview.hpp"
