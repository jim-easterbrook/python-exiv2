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


// Macro to declare a variable to store an imported object
%define DECLARE_IMPORT(full_name)
%fragment("declare_import"{full_name}, "header") {
static PyObject* Python_%mangle(full_name) = NULL;
}
%enddef // DECLARE_IMPORT


// Macro to import an object defined in a python-exiv2 module
%define IMPORT_MODULE_OBJECT(module, name)
DECLARE_IMPORT(Exiv2::name)
%fragment("import_module_object"{Exiv2::name}, "init",
          fragment="declare_import"{Exiv2::name}) {
{
    if (strcmp(SWIG_name, #module)) {
        PyObject* mod = PyImport_ImportModule("exiv2." #module);
        if (!mod)
            return INIT_ERROR_RETURN;
        Python_%mangle(Exiv2::name) = PyObject_GetAttrString(mod, #name);
        Py_DECREF(mod);
        if (!Python_%mangle(Exiv2::name))
            return INIT_ERROR_RETURN;
    }
}
}
%enddef // IMPORT_MODULE_OBJECT

// Macro to import an object defined in a python-exiv2 class
%define IMPORT_CLASS_OBJECT(module, class, name)
DECLARE_IMPORT(Exiv2::class::name)
%fragment("import_class_object"{Exiv2::class::name}, "init",
          fragment="declare_import"{Exiv2::class::name}) {
{
    if (strcmp(SWIG_name, #module)) {
        PyObject* mod = PyImport_ImportModule("exiv2.module");
        if (!mod)
            return INIT_ERROR_RETURN;
        PyObject* parent = PyObject_GetAttrString(mod, "class");
        Py_DECREF(mod);
        if (!parent)
            return INIT_ERROR_RETURN;
        Python_%mangle(Exiv2::class::name) = PyObject_GetAttrString(
            parent, "name");
        Py_DECREF(parent);
        if (!Python_%mangle(Exiv2::class::name))
            return INIT_ERROR_RETURN;
    }
}
}
%enddef // IMPORT_CLASS_OBJECT
