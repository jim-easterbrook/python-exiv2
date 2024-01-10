// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Import exiv2 package
%fragment("_import_exiv2_decl", "header") {
static PyObject* exiv2_module = NULL;
}
%fragment("import_exiv2", "init", fragment="_import_exiv2_decl") {
{
    exiv2_module = PyImport_ImportModule("exiv2");
    if (!exiv2_module)
        return NULL;
}
}

// Get the current (or default if not set) type id of a datum
%fragment("get_type_id"{Exiv2::Exifdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Exifdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::ExifKey(datum->key()).defaultTypeId();
};
}
%fragment("get_type_id"{Exiv2::Iptcdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Iptcdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::IptcDataSets::dataSetType(datum->tag(), datum->record());
};
}
%fragment("get_type_id"{Exiv2::Xmpdatum}, "header") {
static Exiv2::TypeId get_type_id(Exiv2::Xmpdatum* datum) {
    Exiv2::TypeId type_id = datum->typeId();
    if (type_id != Exiv2::invalidTypeId)
        return type_id;
    return Exiv2::XmpProperties::propertyType(Exiv2::XmpKey(datum->key()));
};
}

// Convert exiv2 type id to the appropriate value class type info
%fragment("get_type_object", "header") {
static swig_type_info* get_type_object(Exiv2::TypeId type_id) {
    switch(type_id) {
        case Exiv2::asciiString:
            return $descriptor(Exiv2::AsciiValue*);
        case Exiv2::unsignedShort:
            return $descriptor(Exiv2::ValueType<uint16_t>*);
        case Exiv2::unsignedLong:
        case Exiv2::tiffIfd:
            return $descriptor(Exiv2::ValueType<uint32_t>*);
        case Exiv2::unsignedRational:
            return $descriptor(Exiv2::ValueType<Exiv2::URational>*);
        case Exiv2::signedShort:
            return $descriptor(Exiv2::ValueType<int16_t>*);
        case Exiv2::signedLong:
            return $descriptor(Exiv2::ValueType<int32_t>*);
        case Exiv2::signedRational:
            return $descriptor(Exiv2::ValueType<Exiv2::Rational>*);
        case Exiv2::tiffFloat:
            return $descriptor(Exiv2::ValueType<float>*);
        case Exiv2::tiffDouble:
            return $descriptor(Exiv2::ValueType<double>*);
        case Exiv2::string:
            return $descriptor(Exiv2::StringValue*);
        case Exiv2::date:
            return $descriptor(Exiv2::DateValue*);
        case Exiv2::time:
            return $descriptor(Exiv2::TimeValue*);
        case Exiv2::comment:
            return $descriptor(Exiv2::CommentValue*);
        case Exiv2::xmpText:
            return $descriptor(Exiv2::XmpTextValue*);
        case Exiv2::xmpAlt:
        case Exiv2::xmpBag:
        case Exiv2::xmpSeq:
            return $descriptor(Exiv2::XmpArrayValue*);
        case Exiv2::langAlt:
            return $descriptor(Exiv2::LangAltValue*);
        default:
            return $descriptor(Exiv2::DataValue*);
    }
};
}
