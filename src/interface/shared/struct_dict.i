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
%fragment("getset_functions", "header") {
static PyObject* list_getset(
        PyObject* obj, PyObject* (*conv)(PyObject*, PyGetSetDef*)) {
    PyGetSetDef* getset = Py_TYPE(obj)->tp_getset;
    PyObject* result = PyList_New(0);
    PyObject* item = NULL;
    while (getset->name) {
        // __dict__ is also in the getset list
        if (getset->name[0] != '_') {
            item = (*conv)(obj, getset);
            PyList_Append(result, item);
            Py_DECREF(item);
        }
        getset++;
    }
    return result;
};
static PyGetSetDef* find_getset(PyObject* obj, PyObject* name,
                                bool strip, bool required) {
    if (!PyUnicode_Check(name))
        return NULL;
    Py_ssize_t size = 0;
    const char* c_name = PyUnicode_AsUTF8AndSize(name, &size);
    bool truncate = strip && size > 0 && c_name[size - 1] != '_';
    PyGetSetDef* getset = Py_TYPE(obj)->tp_getset;
    size_t len = 0;
    while (getset->name) {
        len = strlen(getset->name);
        if (truncate && getset->name[len - 1] == '_')
            len--;
        if (len == (size_t) size && strncmp(getset->name, c_name, len) == 0)
            return getset;
        getset++;
    }
    if (required)
        PyErr_Format(PyExc_AttributeError,
            "'%s' object has no attribute '%U'",
            Py_TYPE(obj)->tp_name, name);
    return NULL;
};
static int getset_set(PyObject* obj, PyObject* name, PyObject* value,
                      bool strip, bool required) {
    PyGetSetDef* getset = find_getset(obj, name, strip, required);
    if (getset) {
#if SWIG_VERSION < 0x040400
        if (!value) {
            PyErr_Format(PyExc_TypeError,
                "%s.%s can not be deleted", Py_TYPE(obj)->tp_name, getset->name);
            return -1;
        }
#endif // SWIG_VERSION
        return getset->set(obj, value, getset->closure);
    }
    if (required)
        return -1;
    return PyObject_GenericSetAttr(obj, name, value);
};
static PyObject* getset_to_value(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("N", getset->get(obj, getset->closure));
};
static PyObject* getset_to_item_strip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("(s#N)", getset->name, strlen(getset->name) - 1,
        getset->get(obj, getset->closure));
};
static PyObject* getset_to_item_nostrip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("(sN)", getset->name,
        getset->get(obj, getset->closure));
};
static PyObject* getset_to_key_strip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("s#", getset->name, strlen(getset->name) - 1);
};
static PyObject* getset_to_key_nostrip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("s", getset->name);
};
static int set_attr_strip(PyObject* obj, PyObject* name, PyObject* value) {
   return getset_set(obj, name, value, true, false);
};
#if SWIG_VERSION < 0x040400
static int set_attr_nostrip(PyObject* obj, PyObject* name, PyObject* value) {
    return getset_set(obj, name, value, false, false);
};
#endif // SWIG_VERSION
static PyObject* get_attr_strip(PyObject* obj, PyObject* name) {
    PyGetSetDef* getset = find_getset(obj, name, true, false);
    if (getset)
        return getset_to_value(obj, getset);
    return PyObject_GenericGetAttr(obj, name);
};
}

// Macro definition
%define STRUCT_DICT(struct_type, mutable, strip_underscore)
%fragment("getset_functions");
// Type slots
%feature("python:slot", "tp_iter", functype="getiterfunc")
    struct_type::__iter__;
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    struct_type::__getitem__;
// Typemaps for slot functions
%typemap(default) PyObject* value {$1 = NULL;}
// Document functions
%feature("docstring") struct_type::items "Get structure members.
:rtype: list of (str, value) tuple
:return: structure member (name, value) pairs (with any trailing
    underscores removed from names)."
%feature("docstring") struct_type::keys "Get structure member names.
:rtype: list of str
:return: structure member names (with any trailing underscores
    removed)."
%feature("docstring") struct_type::values "Get structure member values.
:rtype: list of value
:return: structure member values."
// Add functions
%extend struct_type {
#if #strip_underscore == "true"
    PyObject* items(PyObject* py_self) {
        return list_getset(py_self, getset_to_item_strip);
    }
    PyObject* keys(PyObject* py_self) {
        return list_getset(py_self, getset_to_key_strip);
    }
#else
    PyObject* items(PyObject* py_self) {
        return list_getset(py_self, getset_to_item_nostrip);
    }
    PyObject* keys(PyObject* py_self) {
        return list_getset(py_self, getset_to_key_nostrip);
    }
#endif // strip_underscore
    PyObject* values(PyObject* py_self) {
        return list_getset(py_self, getset_to_value);
    }
    PyObject* __iter__(PyObject* py_self) {
        PyObject* seq =
            %mangle(struct_type::keys)($self, py_self);
        PyObject* result = PySeqIter_New(seq);
        Py_DECREF(seq);
        return result;
    }
    PyObject* __getitem__(PyObject* py_self, PyObject* key) {
        PyGetSetDef* getset = find_getset(
            py_self, key, strip_underscore, true);
        if (!getset)
            return NULL;
        return getset_to_value(py_self, getset);
    }
}
#if #strip_underscore == "true"
%feature("python:tp_getattro") struct_type "get_attr_strip";
#endif // strip_underscore
#if #mutable == "true"
#if #strip_underscore == "true"
%feature("python:tp_setattro") struct_type "set_attr_strip";
#else // strip_underscore
#if SWIG_VERSION < 0x040400
%feature("python:tp_setattro") struct_type "set_attr_nostrip";
#endif // SWIG_VERSION
#endif // strip_underscore
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    struct_type::__setitem__;
%extend struct_type {
    PyObject* __setitem__(PyObject* py_self, PyObject* key,
                          PyObject* value) {
        if (getset_set(py_self, key, value, strip_underscore, true))
            return NULL;
        return SWIG_Py_Void();
    }
}
#endif // mutable
%enddef // STRUCT_DICT
