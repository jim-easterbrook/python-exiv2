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

%module(package="exiv2") tags

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exif key class and data attributes.";
#endif

%include "shared/preamble.i"
%include "shared/enum.i"
%include "shared/exception.i"
%include "shared/static_list.i"
%include "shared/struct_dict.i"
%include "shared/unique_ptr.i"

%import "metadatum.i";

IMPORT_ENUM(TypeId)

// Catch some C++ exceptions
%exception;
EXCEPTION(Exiv2::ExifKey::ExifKey)
EXCEPTION(Exiv2::ExifKey::clone)

EXTEND_KEY(Exiv2::ExifKey);

// Add Exif specific enums
#if EXIV2_VERSION_HEX >= 0x001c0000
DEFINE_ENUM(IfdId, "Type to specify the IFD to which a metadata belongs.\n"
"\nMaker note IFDs have been omitted from this enum.",
        "ifdIdNotSet", Exiv2::IfdId::ifdIdNotSet,
        "ifd0Id",      Exiv2::IfdId::ifd0Id,
        "ifd1Id",      Exiv2::IfdId::ifd1Id,
        "ifd2Id",      Exiv2::IfdId::ifd2Id,
        "ifd3Id",      Exiv2::IfdId::ifd3Id,
        "exifId",      Exiv2::IfdId::exifId,
        "gpsId",       Exiv2::IfdId::gpsId,
        "iopId",       Exiv2::IfdId::iopId,
        "mpfId",       Exiv2::IfdId::mpfId,
        "subImage1Id", Exiv2::IfdId::subImage1Id,
        "subImage2Id", Exiv2::IfdId::subImage2Id,
        "subImage3Id", Exiv2::IfdId::subImage3Id,
        "subImage4Id", Exiv2::IfdId::subImage4Id,
        "subImage5Id", Exiv2::IfdId::subImage5Id,
        "subImage6Id", Exiv2::IfdId::subImage6Id,
        "subImage7Id", Exiv2::IfdId::subImage7Id,
        "subImage8Id", Exiv2::IfdId::subImage8Id,
        "subImage9Id", Exiv2::IfdId::subImage9Id,
        "subThumb1Id", Exiv2::IfdId::subThumb1Id,
        "lastId",      Exiv2::IfdId::lastId,
        "ignoreId",    Exiv2::IfdId::ignoreId);

DEFINE_ENUM(SectionId, "Section identifiers to logically group tags.\n"
"\nA section consists of nothing more than a name, based on the"
"\nExif standard.",
        "sectionIfNotSet", Exiv2::SectionId::sectionIdNotSet,
        "imgStruct",       Exiv2::SectionId::imgStruct,
        "recOffset",       Exiv2::SectionId::recOffset,
        "imgCharacter",    Exiv2::SectionId::imgCharacter,
        "otherTags",       Exiv2::SectionId::otherTags,
        "exifFormat",      Exiv2::SectionId::exifFormat,
        "exifVersion",     Exiv2::SectionId::exifVersion,
        "imgConfig",       Exiv2::SectionId::imgConfig,
        "userInfo",        Exiv2::SectionId::userInfo,
        "relatedFile",     Exiv2::SectionId::relatedFile,
        "dateTime",        Exiv2::SectionId::dateTime,
        "captureCond",     Exiv2::SectionId::captureCond,
        "gpsTags",         Exiv2::SectionId::gpsTags,
        "iopTags",         Exiv2::SectionId::iopTags,
        "mpfTags",         Exiv2::SectionId::mpfTags,
        "makerTags",       Exiv2::SectionId::makerTags,
        "dngTags",         Exiv2::SectionId::dngTags,
        "panaRaw",         Exiv2::SectionId::panaRaw,
        "tiffEp",          Exiv2::SectionId::tiffEp,
        "tiffPm6",         Exiv2::SectionId::tiffPm6,
        "adobeOpi",        Exiv2::SectionId::adobeOpi,
        "lastSectionId",   Exiv2::SectionId::lastSectionId);
#endif // EXIV2_VERSION_HEX

// Convert ExifTags::groupList() result to a Python list of GroupInfo objects
LIST_POINTER(const Exiv2::GroupInfo*, Exiv2::GroupInfo, tagList_)
// Convert ExifTags::tagList() result to a Python list of TagInfo objects
LIST_POINTER(const Exiv2::TagInfo*, Exiv2::TagInfo, tag_ != 0xFFFF)

// Give Exiv2::GroupInfo dict-like behaviour
STRUCT_DICT(Exiv2::GroupInfo)

// Give Exiv2::TagInfo dict-like behaviour
STRUCT_DICT(Exiv2::TagInfo)

// Wrapper class for TagListFct function pointer
#ifndef SWIGIMPORTED
%ignore _TagListFct::_TagListFct;
%feature("python:slot", "tp_call", functype="ternarycallfunc")
    _TagListFct::__call__;
%noexception _TagListFct::~_TagListFct;
%noexception _TagListFct::__call__;
%inline %{
class _TagListFct {
private:
    Exiv2::TagListFct func;
public:
    _TagListFct(Exiv2::TagListFct func) : func(func) {}
    const Exiv2::TagInfo* __call__() {
        return (*func)();
    }
};
%}
%fragment("new_TagListFct", "header") {
    static PyObject* new_TagListFct(Exiv2::TagListFct func) {
        return SWIG_Python_NewPointerObj(NULL, new _TagListFct(func),
            $descriptor(_TagListFct*), SWIG_POINTER_OWN);
    }
}
#endif // SWIGIMPORTED

// Wrap TagListFct return values
%typemap(out, fragment="new_TagListFct") Exiv2::TagListFct {
    $result = new_TagListFct($1);
}

// Structs are all static data
%ignore Exiv2::GroupInfo::GroupInfo;
%ignore Exiv2::GroupInfo::~GroupInfo;
%ignore Exiv2::TagInfo::TagInfo;
%ignore Exiv2::TagInfo::~TagInfo;
%ignore Exiv2::ExifTags::~ExifTags;

// Ignore stuff that Python can't use or doesn't need
%ignore Exiv2::GroupInfo::operator==;
%ignore Exiv2::GroupInfo::GroupName;
%ignore Exiv2::ExifTags::taglist;
%ignore Exiv2::TagInfo::printFct_;

// Ignore unneeded key constructor
%ignore Exiv2::ExifKey::ExifKey(const TagInfo&);

// ExifKey::ifdId is documented as internal use only
%ignore Exiv2::ExifKey::ifdId;

%immutable;
%include "exiv2/tags.hpp"
%mutable;
