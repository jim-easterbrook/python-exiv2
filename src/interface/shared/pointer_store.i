// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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


%include "shared/private_data.i"


// Macro to store weak references to pointers and invalidate the
// pointers when data is deleted
%define POINTER_STORE(container_type, datum_type)

#if SWIG_VERSION >= 0x040400
// Functions to store weak references to pointers (swig >= v4.4)
%fragment("pointer_store", "header", fragment="private_data") {
static void _process_list(PyObject* list, bool purge_only,
                          Exiv2::container_type::iterator* beg,
                          Exiv2::container_type::iterator* end) {
    PyObject* py_ptr = NULL;
    datum_type##_pointer* cpp_ptr = NULL;
    for (Py_ssize_t idx = PyList_Size(list); idx > 0; idx--) {
        py_ptr = PyWeakref_GetObject(PyList_GetItem(list, idx-1));
        if (py_ptr == Py_None)
            goto forget;
        if (purge_only)
            continue;
        if (SWIG_IsOK(SWIG_ConvertPtr(py_ptr, (void**)&cpp_ptr,
                $descriptor(datum_type##_pointer*), 0))) {
            if (!beg) {
                cpp_ptr->_invalidate();
                goto forget;
            }
            for (Exiv2::container_type::iterator it=*beg; it!=*end; it++)
                if (cpp_ptr->_invalidate(*it))
                    goto forget;
        }
        continue;
forget:
        PyList_SetSlice(list, idx-1, idx, NULL);
        continue;
    }
};
static void purge_pointers(PyObject* list) {
    _process_list(list, true, NULL, NULL);
};
static void invalidate_pointers(PyObject* py_self) {
    PyObject* list = private_store_get(py_self, "pointers");
    if (list)
        _process_list(list, false, NULL, NULL);
};
static void invalidate_pointers(PyObject* py_self,
                                Exiv2::container_type::iterator pos) {
    PyObject* list = private_store_get(py_self, "pointers");
    if (list) {
        Exiv2::container_type::iterator end = pos;
        end++;
        _process_list(list, false, &pos, &end);
    }
};
static void invalidate_pointers(PyObject* py_self,
                                Exiv2::container_type::iterator beg,
                                Exiv2::container_type::iterator end) {
    PyObject* list = private_store_get(py_self, "pointers");
    if (list)
        _process_list(list, false, &beg, &end);
};
static int store_pointer(PyObject* py_self, PyObject* py_ptr) {
    PyObject* list = private_store_get(py_self, "pointers");
    if (list)
        purge_pointers(list);
    else {
        list = PyList_New(0);
        if (!list)
            return -1;
        int error = private_store_set(py_self, "pointers", list);
        Py_DECREF(list);
        if (error)
            return -1;
    }
    PyObject* ref = PyWeakref_NewRef(py_ptr, NULL);
    if (!ref)
        return -1;
    int result = PyList_Append(list, ref);
    Py_DECREF(ref);
    return result;
};
}
#endif

#if SWIG_VERSION < 0x040400
// erase() and eraseFamily() invalidate the iterator passed to them
%typemap(check) (Exiv2::container_type::iterator pos),
                (Exiv2::container_type::iterator beg) {
    argp$argnum->_invalidate();
}
%typemap(check) Exiv2::container_type::iterator& {
    argp$argnum->_invalidate();
}
#endif

#if SWIG_VERSION >= 0x040400
// clear() invalidates all pointers
%typemap(ret, fragment="pointer_store") void clear {
    invalidate_pointers(self);
}
// erase() and eraseFamily() invalidate some pointers
%typemap(check, fragment="pointer_store")
        Exiv2::container_type::iterator pos {
    invalidate_pointers(self, $1);
}
%typemap(check, fragment="pointer_store")
        (Exiv2::container_type::iterator beg,
         Exiv2::container_type::iterator end) {
    invalidate_pointers(self, $1, $2);
}
%typemap(check, fragment="pointer_store")
        Exiv2::container_type::iterator& pos {
    invalidate_pointers(self, *$1, arg1->end());
}
#endif // SWIG_VERSION

%enddef // POINTER_STORE
