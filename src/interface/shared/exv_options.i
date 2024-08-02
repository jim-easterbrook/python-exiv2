// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
//
// This file is part of python-exiv2. python-exiv2 is free software: you can
// redistribute it and/or modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// python-exiv2 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with python-exiv2.  If not, see <http://www.gnu.org/licenses/>.


// Fragment to define Exiv2::CurlIo if EXV_USE_CURL is OFF
%fragment("EXV_USE_CURL", "header") %{
#ifndef EXV_USE_CURL
namespace Exiv2 {
    class CurlIo : public RemoteIo {};
}
#endif // EXV_USE_CURL
%}

// Fragment to define Exiv2::SshIo if EXV_USE_SSH is OFF
%fragment("EXV_USE_SSH", "header") %{
#ifndef EXV_USE_SSH
namespace Exiv2 {
    class SshIo : public RemoteIo {};
}
#endif // EXV_USE_SSH
%}

// Fragment to set EXV_ENABLE_FILESYSTEM on old libexiv2 versions
%fragment("set_EXV_ENABLE_FILESYSTEM", "header") %{
#if !EXIV2_TEST_VERSION(0, 28, 3)
#define EXV_ENABLE_FILESYSTEM
#endif
// Copy EXV_ENABLE_FILESYSTEM for use in macro
#ifdef EXV_ENABLE_FILESYSTEM
#define _EXV_ENABLE_FILESYSTEM
#endif
%}

// Fragment to define FileIo and XPathIo if EXV_ENABLE_FILESYSTEM is OFF
%fragment("EXV_ENABLE_FILESYSTEM", "header",
          fragment="set_EXV_ENABLE_FILESYSTEM") %{
#ifndef EXV_ENABLE_FILESYSTEM
namespace Exiv2 {
    class FileIo : public BasicIo {};
    class XPathIo : public MemIo {};
}
#endif // EXV_ENABLE_FILESYSTEM
%}

// Macro to not call a function if EXV_ENABLE_FILESYSTEM is OFF
%define EXV_ENABLE_FILESYSTEM_FUNCTION(signature)
%fragment("_set_python_exception");
%fragment("set_EXV_ENABLE_FILESYSTEM");
%exception signature {
    try {
%#ifdef _EXV_ENABLE_FILESYSTEM
        $action
%#else
        throw Exiv2::Error(Exiv2::ErrorCode::kerFunctionNotSupported);
%#endif
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // EXV_ENABLE_FILESYSTEM_FUNCTION

// Macro to not call a function if libexiv2 version is <= 0.27.3
%define EXV_ENABLE_EASYACCESS_FUNCTION(signature)
%fragment("_set_python_exception");
%exception signature {
    try {
%#if EXIV2_TEST_VERSION(0, 27, 4)
        $action
%#else
        throw Exiv2::Error(Exiv2::kerFunctionNotSupported);
%#endif
    }
    catch(std::exception const& e) {
        _set_python_exception();
        SWIG_fail;
    }
}
%enddef // EXV_ENABLE_EASYACCESS_FUNCTION
