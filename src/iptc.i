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

%module(package="exiv2") iptc

#pragma SWIG nowarn=389     // operator[] ignored (consider using %extend)

%include "preamble.i"

%include "stdint.i"
%include "std_string.i"

%import "datasets.i"
%import "metadatum.i"

GETITEM(Exiv2::IptcData, Exiv2::Iptcdatum)
ITERATOR(Exiv2::IptcData, Exiv2::Iptcdatum, IptcDataIterator)
STR(Exiv2::Iptcdatum, toString)

%feature("python:slot", "mp_ass_subscript",
         functype="objobjargproc") Exiv2::IptcData::__setitem__;

%extend Exiv2::IptcData {
    PyObject* __setitem__(const std::string& key, const Exiv2::Iptcdatum &rhs) {
        using namespace Exiv2;
        IptcKey k = IptcKey(key);
        TypeId type_id = IptcDataSets::dataSetType(k.tag(), k.record());
        if (type_id != rhs.typeId()) {
            EXV_WARNING << key << ": type change from '" <<
                TypeInfo::typeName(type_id) << "' to '" <<
                rhs.typeName() << "'.\n";
        }
        (*($self))[key] = rhs;
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const Exiv2::Value &value) {
        using namespace Exiv2;
        IptcKey k = IptcKey(key);
        TypeId type_id = IptcDataSets::dataSetType(k.tag(), k.record());
        if (type_id != value.typeId()) {
            EXV_WARNING << key << ": type change from '" <<
                TypeInfo::typeName(type_id) << "' to '" <<
                TypeInfo::typeName(value.typeId()) << "'.\n";
        }
        (*($self))[key] = value;
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string &value) {
        (*($self))[key] = value;
        return SWIG_Py_Void();
    }
}

%ignore Exiv2::IptcData::begin() const;
%ignore Exiv2::IptcData::end() const;
%ignore Exiv2::IptcData::findKey(IptcKey const &) const;
%ignore Exiv2::IptcData::findId(uint16_t) const;
%ignore Exiv2::IptcData::findId(uint16_t,uint16_t) const;
%ignore Exiv2::IptcParser::encode;

%include "exiv2/iptc.hpp"
