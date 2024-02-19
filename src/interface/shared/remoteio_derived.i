// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Replacement for CurlIo missing from linked libexiv2
// First ifdef EXV_USE_CURL detects SWIGging with EXV_USE_CURL set
// Second ifndef EXV_USE_CURL detects compiling with EXV_USE_CURL unset
#ifdef EXV_USE_CURL
%{
#ifndef EXV_USE_CURL
namespace Exiv2 {
    class CurlIo : public RemoteIo {
    public:
        CurlIo(const std::string& url, size_t blockSize=0) {
            throw std::runtime_error(
                "CurlIo not enabled in linked libexiv2");
        };
    };
}
#endif
%}
#endif

