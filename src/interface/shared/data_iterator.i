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


%include "shared/keep_reference.i"
%include "shared/private_data.i"


// Macro to wrap data iterators
%define DATA_ITERATOR(container_type, datum_type)
// Creating a new iterator keeps a reference to the current one
KEEP_REFERENCE(container_type##_iterator*)

#if SWIG_VERSION < 0x040400
// erase() invalidates the iterator
%typemap(in) (Exiv2::container_type::iterator pos)
        (container_type##_iterator *argp=NULL),
             (Exiv2::container_type::iterator beg)
        (container_type##_iterator *argp=NULL) {
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    $1 = argp->_ptr();
    argp->_invalidate();
}
#endif
// XmpData::eraseFamily takes an iterator reference (and invalidates it)
%typemap(in) Exiv2::container_type::iterator&
        (Exiv2::container_type::iterator it,
         container_type##_iterator* argp = NULL) {
    {
        container_type##_iterator* arg$argnum = NULL;
        $typemap(in, container_type##_iterator*)
        argp = arg$argnum;
    }
    it = argp->_ptr();
    $1 = &it;
#if SWIG_VERSION < 0x040400
    argp->_invalidate();
#endif
}

#if SWIG_VERSION >= 0x040400
// Functions to store weak references to iterators (swig >= v4.4)
%fragment("iterator_store", "header", fragment="private_data") {
static void _process_list(PyObject* list, bool invalidate_all,
                          Exiv2::container_type::iterator* beg,
                          Exiv2::container_type::iterator* end) {
    PyObject* py_it = NULL;
    container_type##_iterator* cpp_it = NULL;
    for (Py_ssize_t idx = PyList_Size(list); idx > 0; idx--) {
        py_it = PyWeakref_GetObject(PyList_GetItem(list, idx-1));
        if (py_it == Py_None)
            goto forget;
        if (!(invalidate_all || beg))
            continue;
        if (SWIG_IsOK(SWIG_ConvertPtr(
                py_it, (void**)&cpp_it,
                $descriptor(container_type##_iterator*), 0))) {
            if (invalidate_all) {
                cpp_it->_invalidate();
                goto forget;
            }
            for (Exiv2::container_type::iterator it=*beg; it!=*end; it++)
                if (cpp_it->_invalidate(it))
                    goto forget;
        }
        continue;
forget:
        PyList_SetSlice(list, idx-1, idx, NULL);
        continue;
    }
};
static void purge_iterators(PyObject* list) {
    _process_list(list, false, NULL, NULL);
};
static void invalidate_iterators(PyObject* py_self) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list)
        _process_list(list, true, NULL, NULL);
};
static void invalidate_iterators(PyObject* py_self,
                                 Exiv2::container_type::iterator pos) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list) {
        Exiv2::container_type::iterator end = pos;
        end++;
        _process_list(list, false, &pos, &end);
    }
};
static void invalidate_iterators(PyObject* py_self,
                                 Exiv2::container_type::iterator beg,
                                 Exiv2::container_type::iterator end) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list)
        _process_list(list, false, &beg, &end);
};
static int store_iterator(PyObject* py_self, PyObject* iterator) {
    PyObject* list = private_store_get(py_self, "iterators");
    if (list)
        purge_iterators(list);
    else {
        list = PyList_New(0);
        if (!list)
            return -1;
        int error = private_store_set(py_self, "iterators", list);
        Py_DECREF(list);
        if (error)
            return -1;
    }
    PyObject* ref = PyWeakref_NewRef(iterator, NULL);
    if (!ref)
        return -1;
    int result = PyList_Append(list, ref);
    Py_DECREF(ref);
    return result;
};
}
#endif

#if SWIG_VERSION >= 0x040400
// clear() invalidates all iterators
%typemap(ret, fragment="iterator_store") void clear {
    invalidate_iterators(self);
}
// erase() and eraseFamily() invalidate some iterators
%typemap(check, fragment="iterator_store")
        Exiv2::container_type::iterator pos {
    invalidate_iterators(self, $1);
}
%typemap(check, fragment="iterator_store")
        (Exiv2::container_type::iterator beg,
         Exiv2::container_type::iterator end) {
    invalidate_iterators(self, $1, $2);
}
%typemap(check, fragment="iterator_store")
        Exiv2::container_type::iterator& pos {
    invalidate_iterators(self, *$1, arg1->end());
}
#endif // SWIG_VERSION

// Keep a reference to the data being iterated
KEEP_REFERENCE(Exiv2::container_type::iterator)

%enddef // DATA_ITERATOR
