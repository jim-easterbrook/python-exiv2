// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2023-26  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
%fragment("pointer_store", "header", fragment="private_data",
          fragment="Python_313_functions") {
static int _process_list(PyObject* list, bool purge_only,
                         Exiv2::container_type::iterator* beg,
                         Exiv2::container_type::iterator* end) {
    PyObject* py_ptr = NULL;
    datum_type##_pointer* cpp_ptr = NULL;
    PyObject* list_item = NULL;
    int result = 0;
    Py_BEGIN_CRITICAL_SECTION(list);
    for (Py_ssize_t idx = PyList_Size(list); idx > 0; idx--) {
        list_item = PyList_GetItemRef(list, idx-1);
        result = PyWeakref_GetRef(list_item, &py_ptr);
        Py_DECREF(list_item);
        if (result < 0)
            break;
        if (py_ptr)
            Py_DECREF(py_ptr);
        else
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
        result = PyList_SetSlice(list, idx-1, idx, NULL);
        if (result < 0)
            break;
        continue;
    }
    Py_END_CRITICAL_SECTION();
    return result;
};
static int invalidate_pointers(PyObject* py_self) {
    PyObject* list = NULL;
    int result = private_store_get(py_self, "pointers", &list);
    if (list) {
        result = _process_list(list, false, NULL, NULL);
        Py_DECREF(list);
    }
    return result;
};
static int invalidate_pointers(PyObject* py_self,
                               Exiv2::container_type::iterator pos) {
    PyObject* list = NULL;
    int result = private_store_get(py_self, "pointers", &list);
    if (list) {
        Exiv2::container_type::iterator end = pos;
        end++;
        result = _process_list(list, false, &pos, &end);
        Py_DECREF(list);
    }
    return result;
};
static int invalidate_pointers(PyObject* py_self,
                               Exiv2::container_type::iterator beg,
                               Exiv2::container_type::iterator end) {
    PyObject* list = NULL;
    int result = private_store_get(py_self, "pointers", &list);
    if (list) {
        result = _process_list(list, false, &beg, &end);
        Py_DECREF(list);
    }
    return result;
};
static int store_pointer(PyObject* py_self, PyObject* py_ptr) {
    PyObject* ref = PyWeakref_NewRef(py_ptr, NULL);
    if (!ref)
        return -1;
    PyObject* list = NULL;
    int result = 0;
    Py_BEGIN_CRITICAL_SECTION(py_self);
    result = private_store_get(py_self, "pointers", &list);
    if (list)
        result = _process_list(list, true, NULL, NULL);
    else {
        list = PyList_New(0);
        if (list)
            result = private_store_set(py_self, "pointers", list);
        else
            result = -1;
    }
    Py_END_CRITICAL_SECTION();
    if (list) {
        result = PyList_Append(list, ref);
        Py_DECREF(list);
    }
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
    if (invalidate_pointers(self) < 0) {
        Py_DECREF($result);
        SWIG_fail;
    }
}
// erase() and eraseFamily() invalidate some pointers
%typemap(check, fragment="pointer_store")
        Exiv2::container_type::iterator pos {
    if (invalidate_pointers(self, $1) < 0) {
        SWIG_fail;
    }
}
%typemap(check, fragment="pointer_store")
        (Exiv2::container_type::iterator beg,
         Exiv2::container_type::iterator end) {
    if (invalidate_pointers(self, $1, $2) < 0) {
        SWIG_fail;
    }
}
%typemap(check, fragment="pointer_store")
        Exiv2::container_type::iterator& pos {
    if (invalidate_pointers(self, *$1, arg1->end()) < 0) {
        SWIG_fail;
    }
}
#endif // SWIG_VERSION

%enddef // POINTER_STORE
