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
%include "shared/buffers.i"

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
    PyObject* py_obj = NULL;
    Py_ssize_t size = $1.size();
    $result = PyList_New(size);
    if (!$result)
        SWIG_fail;
    for (Py_ssize_t idx = 0; idx < size; ++idx) {
        py_obj = SWIG_NewPointerObj(new Exiv2::PreviewProperties($1.at(idx)),
            $descriptor(Exiv2::PreviewProperties*), SWIG_POINTER_OWN);
        if (!py_obj)
            SWIG_fail;
        PyList_SET_ITEM($result, idx, py_obj);
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
%fragment("get_buffer"{Exiv2::PreviewImage}, "header") {
static int %mangle(Exiv2::PreviewImage)_getbuff(
        PyObject* exporter, Py_buffer* view, int flags) {
    Exiv2::PreviewImage* self = 0;
    if (!SWIG_IsOK(SWIG_ConvertPtr(
            exporter, (void**)&self, $descriptor(Exiv2::PreviewImage*), 0)))
        goto fail;
    return PyBuffer_FillInfo(
        view, exporter, (void*)self->pData(), self->size(), 1, flags);
fail:
    PyErr_SetNone(PyExc_BufferError);
    view->obj = NULL;
    return -1;
};
}
%fragment("get_buffer"{Exiv2::PreviewImage});
%feature("python:bf_getbuffer", functype="getbufferproc")
    Exiv2::PreviewImage "Exiv2_PreviewImage_getbuff";

// Convert pData result to a Python memoryview
RETURN_VIEW(Exiv2::byte* pData, arg1->size(), PyBUF_READ,
            Exiv2::PreviewImage::pData)

%immutable Exiv2::PreviewProperties::mimeType_;
%immutable Exiv2::PreviewProperties::extension_;
%immutable Exiv2::PreviewProperties::wextension_;
%immutable Exiv2::PreviewProperties::size_;
%immutable Exiv2::PreviewProperties::width_;
%immutable Exiv2::PreviewProperties::height_;
%immutable Exiv2::PreviewProperties::id_;

%ignore Exiv2::PreviewImage::operator=;

%include "exiv2/preview.hpp"
