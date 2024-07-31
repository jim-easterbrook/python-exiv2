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

%module(package="exiv2") version

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 library version information.";
#endif

%include "shared/preamble.i"
%include "shared/exception.i"
%include "shared/exv_options.i"

%include "stdint.i"
%include "std_string.i"

// Catch all C++ exceptions
EXCEPTION()

// Import __version__ and __version_tuple__ from exiv2 module
%fragment("import_exiv2");
%constant PyObject* __version__ = PyObject_GetAttrString(
    exiv2_module, "__version__");
%constant PyObject* __version_tuple__ = PyObject_GetAttrString(
    exiv2_module, "__version_tuple__");

// Function to report build options used
%feature("docstring") versionInfo "Return a dict of libexiv2 build options."
%fragment("set_EXV_ENABLE_FILESYSTEM");
%inline %{
static PyObject* versionInfo() {
    bool nls = false;
    bool bmff = false;
    bool video = false;
    bool unicode = false;
    bool webready = false;
    bool curl = false;
    bool filesystem = false;
#ifdef EXV_ENABLE_NLS
    nls = true;
#endif
#ifdef EXV_ENABLE_BMFF
    bmff = true;
#endif
#ifdef EXV_ENABLE_VIDEO
    video = true;
#endif
#ifdef EXV_ENABLE_WEBREADY
    webready = true;
#endif
#ifdef EXV_USE_CURL
    curl = true;
#endif
#ifdef EXV_ENABLE_FILESYSTEM
    filesystem = true;
#endif
    return Py_BuildValue("{ss,sN,sN,sN,sN,sN,sN,sN}",
        "version", Exiv2::version(),
        "EXV_ENABLE_NLS", PyBool_FromLong(nls),
        "EXV_ENABLE_BMFF", PyBool_FromLong(bmff),
        "EXV_ENABLE_VIDEO", PyBool_FromLong(video),
        "EXV_UNICODE_PATH", PyBool_FromLong(unicode),
        "EXV_ENABLE_WEBREADY", PyBool_FromLong(webready),
        "EXV_USE_CURL", PyBool_FromLong(curl),
        "EXV_ENABLE_FILESYSTEM", PyBool_FromLong(filesystem));
};
%}

%ignore exv_grep_keys_t;
%ignore Exiv2_grep_key_t;
%ignore Exiv2::dumpLibraryInfo;
%ignore CPLUSPLUS11;
%ignore EXIV2_VERSION;

%include "exiv2/version.hpp"
