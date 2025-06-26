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
        if (getset->name[0] != '_') {
            item = (*conv)(obj, getset);
            PyList_Append(result, item);
            Py_DECREF(item);
        }
        getset++;
    }
    return result;
};
static PyObject* getset_to_value(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("N", getset->get(obj, getset->closure));
};
}
%fragment("getset_functions_strip", "header",
          fragment="getset_functions") {
static PyObject* getset_to_item_strip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("(s#N)", getset->name, strlen(getset->name) - 1,
        getset->get(obj, getset->closure));
};
static PyObject* getset_to_key_strip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("s#", getset->name, strlen(getset->name) - 1);
};
}
%fragment("getset_functions_nostrip", "header",
          fragment="getset_functions") {
static PyObject* getset_to_item_nostrip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("(sN)", getset->name,
        getset->get(obj, getset->closure));
};
static PyObject* getset_to_key_nostrip(PyObject* obj, PyGetSetDef* getset) {
    return Py_BuildValue("s", getset->name);
};
}
%fragment("set_attr_no_delete", "header") {
static int set_attr_no_delete(
        PyObject* obj, PyObject* name, PyObject* value) {
    if ((!value) && PyUnicode_Check(name)) {
        const char* c_name = PyUnicode_AsUTF8(name);
        PyGetSetDef* getset = Py_TYPE(obj)->tp_getset;
        while (getset->name) {
            if (strcmp(getset->name, c_name) == 0) {
                PyErr_Format(PyExc_TypeError,
                    "%s.%s can not be deleted",
                    Py_TYPE(obj)->tp_name, c_name);
                return -1;
            }
            getset++;
        }
    }
    return PyObject_GenericSetAttr(obj, name, value);
};
}

// Macro definition
%define STRUCT_DICT(struct_type, mutable, strip_underscore)
// Type slots
%feature("python:slot", "tp_iter", functype="getiterfunc")
    struct_type::__iter__;
%feature("python:slot", "mp_subscript", functype="binaryfunc")
    struct_type::__getitem__;
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
#if #strip_underscore == "true"
    %fragment("getset_functions_strip");
    PyObject* items(PyObject* py_self) {
        return list_getset(py_self, getset_to_item_strip);
    }
    PyObject* keys(PyObject* py_self) {
        return list_getset(py_self, getset_to_key_strip);
    }
#else
    %fragment("getset_functions_nostrip");
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
    PyObject* __getitem__(PyObject* py_self, const std::string& key) {
#if #strip_underscore == "true"
        return PyObject_GetAttrString(py_self, (key + '_').c_str());
#else
        return PyObject_GetAttrString(py_self, key.c_str());
#endif // strip_underscore
    }
}
#if #mutable == "true"
%fragment("set_attr_no_delete");
%feature("python:tp_setattro") struct_type "set_attr_no_delete";
%feature("python:slot", "mp_ass_subscript", functype="objobjargproc")
    struct_type::__setitem__;
%extend struct_type {
    PyObject* __setitem__(PyObject* py_self, const std::string& key,
                          PyObject* value) {
        if (!value)
            return PyErr_Format(PyExc_TypeError,
                "%s['%s'] can not be deleted", Py_TYPE(py_self)->tp_name,
                key.c_str());
#if #strip_underscore == "true"
        int error = PyObject_SetAttrString(
            py_self, (key + '_').c_str(), value);
#else
        int error = PyObject_SetAttrString(py_self, key.c_str(), value);
#endif // strip_underscore
        if (error)
            return NULL;
        return SWIG_Py_Void();
    }
}
#endif // mutable
%enddef // STRUCT_DICT
