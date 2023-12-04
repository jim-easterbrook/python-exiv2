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

%{
#include "exiv2/exiv2.hpp"
%}

// EXIV2API prepends every function declaration
#define EXIV2API
// Older versions of libexiv2 define these as well
#define EXV_DLLLOCAL
#define EXV_DLLPUBLIC

#ifndef SWIG_DOXYGEN
%feature("autodoc", "2");
#endif

// Get exception and logger defined in __init__.py
%{
PyObject* PyExc_Exiv2Error = NULL;
PyObject* logger = NULL;
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("exiv2");
    if (module != NULL) {
        PyExc_Exiv2Error = PyObject_GetAttrString(module, "Exiv2Error");
        logger = PyObject_GetAttrString(module, "_logger");
        Py_DECREF(module);
    }
    if (PyExc_Exiv2Error == NULL || logger == NULL)
        return NULL;
}
%}

// Macro to define %exception directives
%define EXCEPTION(method, precheck)
%exception method {
precheck
    try {
        $action
#if EXIV2_VERSION_HEX < 0x001c0000
    } catch(Exiv2::AnyError const& e) {
#else
    } catch(Exiv2::Error const& e) {
#endif
        PyErr_SetString(PyExc_Exiv2Error, e.what());
        SWIG_fail;
    } catch(std::exception const& e) {
        PyErr_SetString(PyExc_RuntimeError, e.what());
        SWIG_fail;
    }
}
%enddef // EXCEPTION

// Catch all C++ exceptions
EXCEPTION(,)

// Macro to convert pointer to start of static list to a Python tuple
%define LIST_POINTER(pattern, item_type, valid_test, conv_func)
%fragment("pointer_to_list"{item_type}, "header") {
static PyObject* %mangle(item_type)_ptr_to_list(const item_type* ptr) {
    const item_type* item = ptr;
    PyObject* list = PyList_New(0);
    while (item->valid_test) {
        PyList_Append(list, SWIG_Python_NewPointerObj(
            NULL, SWIG_as_voidptr(item), $descriptor(item_type*), 0));
        ++item;
    }
    return PyList_AsTuple(list);
};
}
%typemap(out, fragment="pointer_to_list"{item_type}) pattern {
    $result = SWIG_Python_AppendOutput(
        $result, %mangle(item_type)_ptr_to_list($1 conv_func));
}
%enddef // LIST_POINTER

// Macro for input read only byte buffer
%define INPUT_BUFFER_RO(buf_type, len_type)
%typemap(doctype) buf_type "bytes-like object";
%typemap(in) (buf_type, len_type) (Py_buffer _global_view) {
    _global_view.obj = NULL;
    if (PyObject_GetBuffer($input, &_global_view, PyBUF_CONTIG_RO) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "Python buffer interface",
                       $symname, $argnum);
    }
    $1 = ($1_ltype) _global_view.buf;
    $2 = ($2_ltype) _global_view.len;
}
%typemap(freearg) (buf_type, len_type) %{
    if (_global_view.obj) {
        PyBuffer_Release(&_global_view);
    }
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}
%enddef // INPUT_BUFFER_RO

// Macro for output writeable byte buffer
%define OUTPUT_BUFFER_RW(buf_type, count_type)
%typemap(doctype) buf_type "writeable bytes-like object";
%typemap(in) (buf_type) (Py_buffer _global_view) {
    _global_view.obj = NULL;
    if (PyObject_GetBuffer(
            $input, &_global_view, PyBUF_CONTIG | PyBUF_WRITABLE) < 0) {
        PyErr_Clear();
        %argument_fail(SWIG_TypeError, "writable buffer", $symname, $argnum);
    }
    $1 = ($1_ltype) _global_view.buf;
}
%typemap(check) (buf_type, count_type) {
    if ($2 > ($2_ltype) _global_view.len) {
        %argument_fail(SWIG_ValueError, "buffer too small",
                       $symname, $argnum);
    }
}
%typemap(freearg) (buf_type) %{
    if (_global_view.obj) {
        PyBuffer_Release(&_global_view);
    }
%}
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER) buf_type %{
    $1 = PyObject_CheckBuffer($input) ? 1 : 0;
%}
%enddef // OUTPUT_BUFFER_RW

// Macro to convert byte* return value to memoryview
// WARNING: return value does not keep a reference to the data it points to
%define RETURN_VIEW(signature, size_func, flags, doc_method)
%typemap(out) (signature) %{
    $result = PyMemoryView_FromMemory((char*)$1, size_func, flags);
%}
%feature("docstring") doc_method
"Returns a temporary Python memoryview of the object's data.

WARNING: do not resize or delete the object while using the view."
%enddef // RETURN_VIEW

// Macro to keep a reference to "self" when returning a particular type.
%define KEEP_REFERENCE(return_type)
%typemap(ret) return_type %{
    if (PyObject_SetAttrString($result, "_refers_to", self)) {
        SWIG_fail;
    }
%}
%enddef // KEEP_REFERENCE

// Macro for Metadatum subclasses
%define EXTEND_METADATUM(datum_type)
// Turn off exception checking for methods that are guaranteed not to throw
%noexception datum_type::count;
%noexception datum_type::size;
// Keep a reference to any object that returns a reference to a datum.
KEEP_REFERENCE(datum_type&)
// Extend Metadatum to allow getting value as a specific type. The "check"
// typemap stores the wanted type and the "out" typemaps (in value.i) do the
// type conversion.
%typemap(check) Exiv2::TypeId as_type %{
    _global_type_id = $1;
%}
#if EXIV2_VERSION_HEX < 0x001c0000
%extend datum_type {
    Exiv2::Value::AutoPtr getValue(Exiv2::TypeId as_type) {
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        return $self->value();
    }
}
#else   // EXIV2_VERSION_HEX
%extend datum_type {
    Exiv2::Value::UniquePtr getValue(Exiv2::TypeId as_type) {
        return $self->getValue();
    }
    const Exiv2::Value& value(Exiv2::TypeId as_type) {
        return $self->value();
    }
}
#endif  // EXIV2_VERSION_HEX
%enddef // EXTEND_METADATUM

// Macros to wrap data iterators
%define DATA_ITERATOR_CLASSES(name, iterator_type, datum_type)
%feature("python:slot", "tp_str", functype="reprfunc") name##_end::__str__;
%feature("python:slot", "tp_iter", functype="getiterfunc") name##_end::__iter__;
%feature("python:slot", "tp_iternext", functype="iternextfunc")
    name##_end::__next__;
%feature("python:slot", "tp_iter", functype="getiterfunc") name::__iter__;
// Add slots to main class using base class methods
%feature("python:tp_str") name
    "_wrap_" #name "_end___str___reprfunc_closure";
%feature("python:tp_iternext") name
    "_wrap_" #name "_end___next___iternextfunc_closure";
%newobject name::__iter__;
%newobject name##_end::__iter__;
%noexception name##_end::operator==;
%noexception name##_end::operator!=;
%ignore name::name;
%ignore name::size;
%ignore name##_end::name##_end;
%ignore name##_end::operator*;
%feature("docstring") name "
Python wrapper for an " #iterator_type ". It has most of
the methods of " #datum_type " allowing easy access to the
data it points to.
"
%feature("docstring") name##_end "
Python wrapper for an " #iterator_type " that points to
the 'end' value and can not be dereferenced.
"
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(name*)
KEEP_REFERENCE(name##_end*)
// Detect end of iteration
%exception name##_end::__next__ %{
    $action
    if (!result) {
        PyErr_SetNone(PyExc_StopIteration);
        SWIG_fail;
    }
%}
%inline %{
// Base class supports a single fixed pointer that never gets dereferenced
class name##_end {
protected:
    iterator_type ptr;
    iterator_type end;
    iterator_type safe_ptr;
public:
    name##_end(iterator_type ptr, iterator_type end) {
        this->ptr = ptr;
        this->end = end;
        safe_ptr = ptr;
    }
    name##_end* __iter__() { return new name##_end(ptr, end); }
    datum_type* __next__() {
        if (ptr == end) {
            return NULL;
        }
        datum_type* result = &(*safe_ptr);
        ptr++;
        if (ptr != end) {
            safe_ptr = ptr;
        }
        return result;
    }
    iterator_type operator*() const { return ptr; }
    bool operator==(const name##_end &other) const { return *other == ptr; }
    bool operator!=(const name##_end &other) const { return *other != ptr; }
    std::string __str__() {
        if (ptr == end)
            return "iterator<end>";
        return "iterator<" + ptr->key() + ": " + ptr->print() + ">";
    }
};
// Main class always has a dereferencable pointer in safe_ptr, so no extra checks
// are needed.
class name : public name##_end {
public:
    name(iterator_type ptr, iterator_type end) : name##_end(ptr, end) {}
    datum_type* operator->() const { return &(*safe_ptr); }
    name* __iter__() { return new name(safe_ptr, end); }
    // Provide size() C++ method for buffer size check
    size_t size() { return safe_ptr->size(); }
};
%}
%enddef // DATA_ITERATOR_CLASSES

// Declare typemaps for data iterators.
%define DATA_ITERATOR_TYPEMAPS(name, iterator_type)
%typemap(in) iterator_type (int res, name##_end *argp) %{
    res = SWIG_ConvertPtr($input, (void**)&argp, $descriptor(name##_end*), 0);
    if (!SWIG_IsOK(res)) {
        %argument_fail(res, name##_end, $symname, $argnum);
    }
    if (!argp) {
        %argument_nullref(name##_end, $symname, $argnum);
    }
    $1 = **argp;
%};
// assumes arg1 is the base class parent
%typemap(out) iterator_type {
    iterator_type end = arg1->end();
    if ((iterator_type)$1 == end)
        $result = SWIG_NewPointerObj(
            new name##_end($1, end), $descriptor(name##_end*), SWIG_POINTER_OWN);
    else
        $result = SWIG_NewPointerObj(
            new name($1, end), $descriptor(name*), SWIG_POINTER_OWN);
};
// Keep a reference to the data being iterated
KEEP_REFERENCE(iterator_type)
%enddef // DATA_ITERATOR_TYPEMAPS

// Macro to wrap data containers.
%define DATA_CONTAINER(base_class, datum_type, key_type, default_type_func)
// Turn off exception checking for methods that are guaranteed not to throw
%noexception base_class::begin;
%noexception base_class::end;
%noexception base_class::clear;
%noexception base_class::count;
%noexception base_class::empty;
// Add dict-like behaviour
%feature("python:slot", "tp_iter", functype="getiterfunc")
    base_class::begin;
%feature("python:slot", "mp_length", functype="lenfunc")
    base_class::count;
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    base_class::__getitem__;
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    base_class::__setitem__;
%feature("python:slot", "sq_contains", functype="objobjproc")
    base_class::__contains__;
%extend base_class {
    datum_type& __getitem__(const std::string& key) {
        return (*$self)[key];
    }
    PyObject* __setitem__(const std::string& key, Exiv2::Value* value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type_func;
        datum->setValue(value);
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << datum->key() << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, const std::string& value) {
        using namespace Exiv2;
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type_func;
        if (datum->setValue(value) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), TypeInfo::typeName(old_type),
                value.c_str());
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << datum->key() << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key, PyObject* value) {
        using namespace Exiv2;
        // Get equivalent of Python "str(value)"
        PyObject* py_str = PyObject_Str(value);
        if (py_str == NULL)
            return NULL;
        const char* c_str = PyUnicode_AsUTF8(py_str);
        Py_DECREF(py_str);
        datum_type* datum = &(*$self)[key];
        TypeId old_type = datum->typeId();
        if (old_type == invalidTypeId)
            old_type = default_type_func;
        if (datum->setValue(c_str) != 0)
            return PyErr_Format(PyExc_ValueError,
                "%s: cannot set type '%s' to value '%s'",
                datum->key().c_str(), TypeInfo::typeName(old_type), c_str);
        TypeId new_type = datum->typeId();
        if (new_type != old_type) {
            EXV_WARNING << datum->key() << ": changed type from '" <<
                TypeInfo::typeName(old_type) << "' to '" <<
                TypeInfo::typeName(new_type) << "'.\n";
        }
        return SWIG_Py_Void();
    }
    PyObject* __setitem__(const std::string& key) {
        base_class::iterator pos = $self->findKey(key_type(key));
        if (pos == $self->end()) {
            PyErr_SetString(PyExc_KeyError, key.c_str());
            return NULL;
        }
        $self->erase(pos);
        return SWIG_Py_Void();
    }
    bool __contains__(const std::string& key) {
        return $self->findKey(key_type(key)) != $self->end();
    }
}
%enddef // DATA_CONTAINER

// Macros to make enums more Pythonic
// Function to return enum members as Python list
%fragment("enum_helper", "header") {
#include <cstdarg>
static PyObject* _get_enum_list(int dummy, ...) {
    va_list args;
    va_start(args, dummy);
    char* label;
    int value;
    PyObject* result = PyList_New(0);
    label = va_arg(args, char*);
    while (label) {
        value = va_arg(args, int);
        PyList_Append(result, PyTuple_Pack(2,
            PyUnicode_FromString(label), PyLong_FromLong(value)));
        label = va_arg(args, char*);
    }
    va_end(args);
    return result;
};
}
%define ENUM(name, doc, contents...)
%fragment("enum_helper");
%noexception _enum_list_##name;
%inline %{
PyObject* _enum_list_##name() {
    return _get_enum_list(0, contents, NULL);
};
%}
%pythoncode %{
import enum
name = enum.IntEnum('name', _enum_list_##name())
name.__doc__ = doc
%}
%ignore Exiv2::name;
%enddef // ENUM

%define DEPRECATED_ENUM(moved_to, enum_name, doc, contents...)
%fragment("enum_helper");
%noexception _enum_list_##enum_name;
%inline %{
PyObject* _enum_list_##enum_name() {
    return _get_enum_list(0, contents, NULL);
};
%}
%pythoncode %{
import enum

class enum_name##Meta(enum.EnumMeta):
    def __getattribute__(cls, name):
        obj = super().__getattribute__(name)
        if isinstance(obj, enum.Enum):
            import warnings
            warnings.warn(
                "Use 'moved_to.enum_name' instead of 'enum_name'",
                DeprecationWarning)
        return obj

class Deprecated##enum_name(enum.IntEnum, metaclass=enum_name##Meta):
    pass

enum_name = Deprecated##enum_name('enum_name', _enum_list_##enum_name())
enum_name.__doc__ = doc
%}
%ignore Exiv2::enum_name;
%enddef // DEPRECATED_ENUM

// Function to generate Python enum
%fragment("class_enum_helper", "header") {
#include <cstdarg>
static PyObject* _get_enum_object(const char* name, ...) {
    va_list args;
    va_start(args, name);
    char* label;
    int value;
    PyObject* module = NULL;
    PyObject* IntEnum = NULL;
    PyObject* result = NULL;
    PyObject* data = PyList_New(0);
    label = va_arg(args, char*);
    while (label) {
        value = va_arg(args, int);
        if (PyList_Append(data, PyTuple_Pack(2,
                PyUnicode_FromString(label), PyLong_FromLong(value))))
            goto fail;
        label = va_arg(args, char*);
    }
    va_end(args);
    module = PyImport_ImportModule("enum");
    if (!module)
        goto fail;
    IntEnum = PyObject_GetAttrString(module, "IntEnum");
    if (!IntEnum)
        goto fail;
    result = PyObject_CallFunction(IntEnum, "sO", name, data);
fail:
    Py_XDECREF(module);
    Py_XDECREF(IntEnum);
    Py_XDECREF(data);
    return result;
};
}
%define CLASS_ENUM(class, name, doc, contents...)
%fragment("class_enum_helper");
// Add enum to type object during module init
%init %{
{
    PyObject* enum_obj = _get_enum_object("name", contents, NULL);
    if (!enum_obj)
        return NULL;
    if (PyObject_SetAttrString(
            enum_obj, "__doc__", PyUnicode_FromString(doc)))
        return NULL;
    PyTypeObject* type =
        (PyTypeObject *)&SwigPyBuiltin__Exiv2__##class##_type;
    SWIG_Python_SetConstant(type->tp_dict, NULL, "name", enum_obj);
    PyType_Modified(type);
}
%}
%enddef // CLASS_ENUM

// Stuff to handle auto_ptr or unique_ptr
#if EXIV2_VERSION_HEX < 0x001c0000
%define wrap_auto_unique_ptr(pointed_type)
%include "std_auto_ptr.i"
%auto_ptr(pointed_type)
%enddef // wrap_auto_unique_ptr
#elif SWIG_VERSION >= 0x040100
%define wrap_auto_unique_ptr(pointed_type)
%include "std_unique_ptr.i"
%unique_ptr(pointed_type)
%enddef // wrap_auto_unique_ptr
#else
template <typename T>
struct std::unique_ptr {};
%define wrap_auto_unique_ptr(pointed_type)
%typemap(out) std::unique_ptr<pointed_type> %{
    $result = SWIG_NewPointerObj(
        $1.release(), $descriptor(pointed_type *), SWIG_POINTER_OWN);
%}
%template() std::unique_ptr<pointed_type>;
%enddef // wrap_auto_unique_ptr
#endif
