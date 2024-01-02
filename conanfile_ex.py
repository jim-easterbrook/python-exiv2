# python-exiv2 - Python interface to libexiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copy this file to exiv2 source directory, then run Conan to install
# dependencies. For example:
#
# cd exiv2-0.27.7-Source
# copy ..\python-exiv2\conanfile_ex.py
# conan install conanfile_ex.py -of build-msvc -if build-msvc
# -o unitTests=False -o iconv=True -o webready=True -b missing

from conanfile import Exiv2Conan

class Exiv2ConanEx(Exiv2Conan):
    def requirements(self):
        super(Exiv2ConanEx, self).requirements()
        self.requires('libgettext/0.21')
