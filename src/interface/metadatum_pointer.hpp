/* python-exiv2 - Python interface to libexiv2
 * http://github.com/jim-easterbrook/python-exiv2
 * Copyright (C) 2025  Jim Easterbrook  jim@jim-easterbrook.me.uk
 *
 * This file is part of python-exiv2.
 *
 * python-exiv2 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * python-exiv2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with python-exiv2.  If not, see <http://www.gnu.org/licenses/>.
 */


#include "exiv2/exiv2.hpp"


std::string metadatum_str(Exiv2::Metadatum* datum) {
    return datum->key() + ": " + datum->print();
};


class MetadatumPointerBase {
protected:
    bool invalidated;
    std::string name;
public:
    MetadatumPointerBase(): invalidated(false) {}
    virtual ~MetadatumPointerBase() {}
    virtual Exiv2::Metadatum* operator*() const = 0;
    std::string __str__() {
        if (invalidated)
            return name + "<deleted data>";
        Exiv2::Metadatum* ptr = **this;
        if (!ptr)
            return name + "<data end>";
        return name + "<" + metadatum_str(ptr) + ">";
    }
    // Provide size() C++ method for buffer size check
    size_t size() {
        if (invalidated)
            return 0;
        Exiv2::Metadatum* ptr = **this;
        if (!ptr)
            return 0;
        return ptr->size();
    }
#if EXIV2_VERSION_HEX < 0x001c0000
    // Provide count() C++ method for index bounds check
    long count() {
        if (invalidated)
            return 0;
        Exiv2::Metadatum* ptr = **this;
        if (!ptr)
            return 0;
        return ptr->count();
    }
#endif
    // Invalidate iterator unilaterally
    void _invalidate() { invalidated = true; }
    // Invalidate iterator if what it points to has been deleted
    bool _invalidate(Exiv2::Metadatum& deleted) {
        if (&deleted == **this)
            invalidated = true;
        return invalidated;
    }
};


template <typename T>
class MetadatumPointer: public MetadatumPointerBase {
public:
    virtual T* operator*() const = 0;
    bool operator==(const T &other) const {
        return &other == **this;
    }
    bool operator!=(const T &other) const {
        return &other != **this;
    }
    // Dereference operator gives access to all datum methods
    T* operator->() const {
        T* ptr = **this;
        if (!ptr)
            throw std::runtime_error(name + " iterator is at end of data");
        return ptr;
    }
};

using Exifdatum_pointer = MetadatumPointer<Exiv2::Exifdatum>;
using Iptcdatum_pointer = MetadatumPointer<Exiv2::Iptcdatum> ;
using Xmpdatum_pointer = MetadatumPointer<Exiv2::Xmpdatum>;


template <typename I, typename T>
class MetadataIterator: public MetadatumPointer<T> {
private:
    I ptr;
    I end;
public:
    MetadataIterator(I ptr, I end): ptr(ptr), end(end) {
        this->name = "iterator";
    }
    MetadataIterator<I, T>* __iter__() { return this; }
    T* __next__() {
        if (this->invalidated)
            throw std::runtime_error(
                "container_type changed size during iteration");
        if (ptr == end)
            return NULL;
        return &(*ptr++);
    }
    T* operator*() const {
        if (this->invalidated)
            throw std::runtime_error("Metadata iterator is invalid");
        if (ptr == end)
            return NULL;
        return &(*ptr);
    }
    // Direct access to ptr and invalidated, for use in input typemaps
    bool _invalidated() const { return this->invalidated; }
    I _ptr() const { return ptr; }
};

using ExifData_iterator =
    MetadataIterator<Exiv2::ExifData::iterator, Exiv2::Exifdatum>;
using IptcData_iterator =
    MetadataIterator<Exiv2::IptcData::iterator, Exiv2::Iptcdatum>;
using XmpData_iterator =
    MetadataIterator<Exiv2::XmpData::iterator, Exiv2::Xmpdatum>;


template <typename T>
class MetadatumReference: public MetadatumPointer<T> {
private:
    T* ptr;
public:
    MetadatumReference(T* ptr): ptr(ptr) {
        this->name = "pointer";
    }
    T* operator*() const {
        if (this->invalidated)
            throw std::runtime_error("Metadatum reference is invalid");
        return ptr;
    }
};

using Exifdatum_reference = MetadatumReference<Exiv2::Exifdatum>;
using Iptcdatum_reference = MetadatumReference<Exiv2::Iptcdatum>;
using Xmpdatum_reference = MetadatumReference<Exiv2::Xmpdatum>;
