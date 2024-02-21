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


// Add dict-like behaviour to an Exiv2 struct, e.g. PreviewProperties

// Helper functions
%fragment("getset_functions", "header") {
static PyObject* list_getset(
        PyObject* obj, PyObject* (*conv)(PyObject*, PyGetSetDef*)) {
    PyGetSetDef* getset = obj->ob_type->tp_getset;
    PyObject* result = PyList_New(0);
    PyObject* item = NULL;
    while (getset->name) {
        if (getset->name[0] != '_') {
            item = (*conv)(obj, getset);
            PyList_Append(result, item);
            Py_DECREF(item);
        }
        getset++;
    }
    return result;
};
static PyGetSetDef* find_getset(PyObject* obj, const char* name) {
    size_t len = strlen(name);
    PyGetSetDef* getset = obj->ob_type->tp_getset;
    while (getset->name) {
        size_t cmp_len = strlen(getset->name);
        if (getset->name[cmp_len-1] == '_')
            cmp_len--;
        if ((cmp_len == len) && (strncmp(getset->name, name, len) == 0))
            return getset;
        getset++;
    }
    PyErr_Format(
        PyExc_KeyError, "'%s' not in '%s'", name, obj->ob_type->tp_name);
    return NULL;
};
static PyObject* getset_to_item(PyObject* obj, PyGetSetDef* getset) {
    size_t len = strlen(getset->name);
    if (getset->name[len-1] == '_')
        len--;
    return Py_BuildValue("(s#N)", getset->name, len,
        getset->get(obj, getset->closure));
};
static PyObject* getset_to_key(PyObject* obj, PyGetSetDef* getset) {
    size_t len = strlen(getset->name);
    if (getset->name[len-1] == '_')
        len--;
    return Py_BuildValue("s#", getset->name, len);
};
static PyObject* getset_to_value(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("N", getset->get(obj, getset->closure));
};
}

// Macro definition
%define STRUCT_DICT(struct_type)
// Type slots
%feature("python:slot", "tp_iter", functype="getiterfunc")
    struct_type::__iter__;
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    struct_type::__getitem__;
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    struct_type::__setitem__;
// Typemaps for slot functions
%typemap(in, numinputs=0) PyObject* py_self {$1 = self;}
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
    %fragment("getset_functions");
    PyObject* items(PyObject* py_self) {
        return list_getset(py_self, getset_to_item);
    }
    PyObject* keys(PyObject* py_self) {
        return list_getset(py_self, getset_to_key);
    }
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
    PyObject* __getitem__(PyObject* py_self, const std::string& key) {
        PyGetSetDef* getset = find_getset(py_self, key.c_str());
        if (!getset)
            return NULL;
        return getset->get(py_self, getset->closure);
    }
    PyObject* __setitem__(PyObject* py_self, const std::string& key,
                          PyObject* value) {
        PyGetSetDef* getset = find_getset(py_self, key.c_str());
        if (!getset)
            return NULL;
        if (!value)
            return PyErr_Format(PyExc_TypeError,
                "%s['%s'] can not be deleted", py_self->ob_type->tp_name,
                key.c_str());
        if (!getset->set)
            return PyErr_Format(PyExc_TypeError, "%s['%s'] is read-only",
                                py_self->ob_type->tp_name, key.c_str());
        if (getset->set(py_self, value, getset->closure) != 0)
            return NULL;
        return SWIG_Py_Void();
    }
}
%enddef // STRUCT_DICT
