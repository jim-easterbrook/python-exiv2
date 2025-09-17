// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2024-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


// Add dict-like behaviour to an Exiv2 struct, e.g. PreviewProperties


// Helper functions
%fragment("struct_info_type", "header") {
typedef struct {
    bool aliased = false;
    std::vector< std::string > members;
    std::vector< std::string > aliases;
} struct_info;
}
%fragment("init_struct_info", "header", fragment="struct_info_type") {
static void init_struct_info(struct_info& info, swig_type_info* type) {
    if (!info.members.empty())
        return;
    PyGetSetDef* getset =
        ((SwigPyClientData*)type->clientdata)->pytype->tp_getset;
    while (getset->name) {
        // __dict__ is also in the getset list
        if (getset->name[0] != '_') {
            info.members.push_back(getset->name);
            std::string alias = getset->name;
            if (alias.back() == '_') {
                alias.pop_back();
                info.aliased = true;
            }
            info.aliases.push_back(alias);
        }
        getset++;
    }
};
}
%fragment("get_attr_struct", "header", fragment="struct_info_type") {
static PyObject* get_attr_struct(struct_info& info, bool as_item,
                                 PyObject* obj, PyObject* name) {
    std::string c_name = PyUnicode_AsUTF8(name);
    if (as_item || info.aliased)
        for (size_t i = 0; i < info.members.size(); i++)
            if (info.aliases[i] == c_name)
                return PyObject_GetAttrString(obj, info.members[i].c_str());
    if (as_item)
        return PyErr_Format(PyExc_KeyError, "'%s'", c_name.c_str());
    return PyObject_GenericGetAttr(obj, name);
};
}
%fragment("set_attr_struct", "header", fragment="struct_info_type") {
static int set_attr_struct(struct_info& info, bool as_item,
                           PyObject* obj, PyObject* name, PyObject* value) {
    std::string c_name = PyUnicode_AsUTF8(name);
    if (as_item || info.aliased)
        for (size_t i = 0; i < info.members.size(); i++)
            if (info.aliases[i] == c_name)
                return PyObject_SetAttrString(
                    obj, info.members[i].c_str(), value);
    if (as_item) {
        PyErr_Format(PyExc_KeyError, "'%s'", c_name.c_str());
        return -1;
    }
#if SWIG_VERSION < 0x040400
    if (!value)
        for (size_t i = 0; i < info.members.size(); i++)
            if (info.members[i] == c_name) {
                PyErr_Format(PyExc_TypeError, "%s.%s can not be deleted",
                             Py_TYPE(obj)->tp_name, c_name.c_str());
                return -1;
            }
#endif
    return PyObject_GenericSetAttr(obj, name, value);
};
}
%fragment("keys_struct", "header", fragment="struct_info_type") {
static PyObject* keys_struct(struct_info& info) {
    PyObject* result = PyTuple_New(info.members.size());
    for (size_t i = 0; i < info.members.size(); i++)
        PyTuple_SET_ITEM(
            result, i, PyUnicode_FromString(info.aliases[i].c_str()));
    return result;
};
}
%fragment("values_struct", "header", fragment="struct_info_type") {
static PyObject* values_struct(struct_info& info, PyObject* obj) {
    PyObject* result = PyTuple_New(info.members.size());
    for (size_t i = 0; i < info.members.size(); i++)
        PyTuple_SET_ITEM(
            result, i, PyObject_GetAttrString(obj, info.members[i].c_str()));
    return result;
};
}
%fragment("items_struct", "header", fragment="struct_info_type") {
static PyObject* items_struct(struct_info& info, PyObject* obj) {
    PyObject* result = PyTuple_New(info.members.size());
    for (size_t i = 0; i < info.members.size(); i++)
        PyTuple_SET_ITEM(result, i, Py_BuildValue(
            "(sN)", info.aliases[i].c_str(),
            PyObject_GetAttrString(obj, info.members[i].c_str())));
    return result;
};
}


%define STRUCT_DICT(struct_type, mutable, strip_underscore)
// Type slots
%feature("python:slot", "tp_iter", functype="getiterfunc")
    struct_type::__iter__;
// These functions don't throw exceptions
%noexception struct_type::__iter__;
%noexception struct_type::keys;
%noexception struct_type::values;
%noexception struct_type::items;
// Typemaps for slot functions
%typemap(default) PyObject* value {$1 = NULL;}
// Document functions
%feature("docstring") struct_type::items "Get structure members.
:rtype: tuple of (str, value) tuple
:return: structure member (name, value) pairs."
%feature("docstring") struct_type::keys "Get structure member names.

Return the names used to access members as attributes (``object.name``)
or with dict-like indexing (``object['name']``). Attribute access is
preferred as it is more efficient."
#if #strip_underscore == "true"
"

Although the exiv2 C++ structure member names end with underscores, the
Python interface uses names without underscores."
#endif
"
:rtype: tuple of str
:return: structure member names.
"
%feature("docstring") struct_type::values "Get structure member values.
:rtype: tuple of value
:return: structure member values."
// Add functions
%extend struct_type {
    %fragment("struct_info"{struct_type});
    %fragment("keys_struct");
    %fragment("values_struct");
    %fragment("items_struct");
    PyObject* keys() {
        init_info_%mangle(struct_type)();
        return keys_struct(info_%mangle(struct_type));
    }
    PyObject* values(PyObject* py_self) {
        init_info_%mangle(struct_type)();
        return values_struct(info_%mangle(struct_type), py_self);
    }
    PyObject* items(PyObject* py_self) {
        init_info_%mangle(struct_type)();
        return items_struct(info_%mangle(struct_type), py_self);
    }
    static PyObject* __iter__() {
        // Deprecated since 2025-09-11
        PyErr_WarnEx(PyExc_DeprecationWarning,
             "Please iterate over keys() function output", 1);
        init_info_%mangle(struct_type)();
        PyObject* seq = keys_struct(info_%mangle(struct_type));
        PyObject* result = PySeqIter_New(seq);
        Py_DECREF(seq);
        return result;
    }
}
%fragment("struct_info"{struct_type}, "header",
          fragment="init_struct_info") {
static struct_info info_%mangle(struct_type);
static void init_info_%mangle(struct_type)() {
    init_struct_info(info_%mangle(struct_type), $descriptor(struct_type*));
};
}
%fragment("get_item"{struct_type}, "header",
          fragment="struct_info"{struct_type}, fragment="get_attr_struct") {
static PyObject* get_item_%mangle(struct_type)(PyObject* obj,
                                               PyObject* key) {
    init_info_%mangle(struct_type)();
    return get_attr_struct(info_%mangle(struct_type), true, obj, key);
};
}
%fragment("get_attr"{struct_type}, "header",
          fragment="struct_info"{struct_type}, fragment="get_attr_struct") {
static PyObject* get_attr_%mangle(struct_type)(PyObject* obj,
                                               PyObject* name) {
    init_info_%mangle(struct_type)();
    return get_attr_struct(info_%mangle(struct_type), false, obj, name);
};
}
%fragment("set_item"{struct_type}, "header",
          fragment="struct_info"{struct_type}, fragment="set_attr_struct") {
static int set_item_%mangle(struct_type)(
        PyObject* obj, PyObject* key, PyObject* value) {
    init_info_%mangle(struct_type)();
    return set_attr_struct(info_%mangle(struct_type), true, obj, key, value);
};
}
%fragment("set_attr"{struct_type}, "header",
          fragment="struct_info"{struct_type}, fragment="set_attr_struct") {
static int set_attr_%mangle(struct_type)(
        PyObject* obj, PyObject* name, PyObject* value) {
    init_info_%mangle(struct_type)();
    return set_attr_struct(
        info_%mangle(struct_type), false, obj, name, value);
};
}
%fragment("get_item"{struct_type});
%feature("python:mp_subscript") struct_type
    QUOTE(get_item_%mangle(struct_type));
#if #strip_underscore == "true"
%fragment("get_attr"{struct_type});
%feature("python:tp_getattro") struct_type
    QUOTE(get_attr_%mangle(struct_type));
#endif
#if #mutable == "true"
%fragment("set_item"{struct_type});
%feature("python:mp_ass_subscript") struct_type
    QUOTE(set_item_%mangle(struct_type));
#if #strip_underscore == "true" || SWIG_VERSION < 0x040400
%fragment("set_attr"{struct_type});
%feature("python:tp_setattro") struct_type
    QUOTE(set_attr_%mangle(struct_type));
#endif
#endif // mutable
%enddef // STRUCT_DICT
