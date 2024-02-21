# python-exiv2 - Python interface to exiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2024  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))


# -- Project information -----------------------------------------------------

project = 'python-exiv2'
copyright = '2004-2024 Exiv2 authors'
author = 'Jim Easterbrook'

import exiv2

# The full version, including alpha/beta/rc tags
release = '{} (exiv2 {})'.format(exiv2.__version__, exiv2.version())
version = exiv2.__version__

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = ['sphinx.ext.autodoc',
              'sphinx.ext.autosummary',
              'sphinx.ext.inheritance_diagram',
              'sphinx.ext.intersphinx']

autosummary_imported_members = True
autodoc_class_signature = 'separated'
autodoc_docstring_signature = False
autodoc_default_options = {
    'members': True,
    'undoc-members': True,
    'exclude-members': 'this, thisown, __init__, __new__',
    'show-inheritance': True,
    }

intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    }

add_module_names = False

import re

class_re = re.compile(r':class:`(\w+?)`')
percent_re = re.compile(r'%(\w+?)([.,|(\s]|$)')

def process_docstring(app, what, name, obj, options, lines):
    # replace/modify some docstrings
    if name == 'exiv2._version.__version__':
        lines[:] = ['python-exiv2 version as a string', '']
        return
    if name == 'exiv2._version.__version_tuple__':
        lines[:] = ['python-exiv2 version as a tuple of ints', '']
        return
    if 'iterator' in name and not lines:
        parts = name.split('.')
        lines[:] = ['See :meth:`{}.{}`.'.format(parts[2].replace(
            'Data_iterator', 'datum'), parts[3]), '']
        return
    # fixes for particular problems
    if name.endswith('error.LogMsg') or name.endswith('iptc.Iptcdatum'):
        # first line is not indented
        lines[0] = '       ' + lines[0]
    if name.endswith('XmpParser.initialize'):
        # fix broken code block comment parsing by SWIG
        in_code_block = False
        for idx in range(len(lines)):
            if not lines[idx]:
                continue
            if '.. code-block::' in lines[idx]:
                in_code_block = True
                indent = 8 + len(lines[idx]) - len(lines[idx].lstrip())
                indent = (' ' * indent)
                continue
            if ':rtype:' in lines[idx]:
                break
            if in_code_block and lines[idx][0] != ' ':
                lines[idx] = indent + '// ' + lines[idx]
    if name.endswith('ExifThumb.erase'):
        # fix %Thumbnail
        for idx in range(len(lines)):
            lines[idx] = lines[idx].replace(
                'Exif.%Thumbnail.*', '``Exif.Thumbnail.*``')
    if name.endswith('Io.read'):
        # fix size_ member
        for idx in range(len(lines)):
            lines[idx] = lines[idx].replace('DataBuf::size_', 'DataBuf.size\_')
    if name.endswith('XmpData.usePacket'):
        # fix usepacket_ member
        for idx in range(len(lines)):
            lines[idx] = lines[idx].replace('usePacket_', 'usePacket\_')
    # other substitutions
    for idx in range(len(lines)):
        line = lines[idx]
        line = line.replace(':raises: Error',
                            ':raises: :exc:`~exiv2.Exiv2Error` ')
        for match in class_re.finditer(line):
            part_name = match.group(1)
            try:
                obj = getattr(exiv2, part_name)
            except Exception as ex:
                break
            full_name = obj.__module__ + '.' + obj.__qualname__
            line = line.replace('`' + part_name + '`', '`~' + full_name + '`')
        for match in percent_re.finditer(line):
            part_name = match.group(1)
            line = line.replace('%' + part_name, '``' + part_name + '`` ')
        lines[idx] = line
    # remove arbitrary indentation
    remove = None
    for idx in range(len(lines)):
        line = lines[idx]
        active_line = line.lstrip()
        if not active_line:
            lines[idx] = ''
            continue
        indent = len(line) - len(active_line)
        if remove is None:
            remove = indent
        if active_line == '|' or active_line.startswith('*Overload'):
            # reset
            remove = None
        elif indent < remove:
            # unexpected unindentation
            print(name)
            print('unexpected unindentation', idx, line)
            remove = None
        else:
            lines[idx] = line[remove:]
    # convert to Sphinx-compatible reStructuredText
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        if not line:
            idx += 1
            continue
        active_line = line.lstrip()
        indent = len(line) - len(active_line)
        min_indent = ' ' * (indent + 1)
        words = active_line.split()
        if words[0] == '..':
            # Sphinx directive such as '.. code::'
            # Copy until not indented
            while True:
                idx += 1
                if idx >= len(lines) or (
                        lines[idx] and not lines[idx].startswith(min_indent)):
                    break
            continue
        while min_indent and lines[idx+1].startswith(min_indent):
            # contenate indented continuation lines
            lines[idx] += ' ' + lines.pop(idx+1).lstrip()
        line = lines[idx]
        active_line = line.lstrip()
        if active_line == '|':
            # unneeded separator between overloads
            del lines[idx:idx+2]
            idx -= 2
        elif active_line[0] == '|':
            # probably a table
            parts = line.split('|')
            if len(parts) > 3 and parts[0].strip() == '' and parts[-1] == '':
                if idx > 0 and lines[idx-1]:
                    lines.insert(idx, '')
                    idx += 1
                header = ['"{}"'.format(x.strip('*')) for x in parts[1:-1]]
                lines[idx:idx+1] = [
                    parts[0] + '.. csv-table::', parts[0] + '    :delim: |',
                    parts[0] + '    :header: ' + ', '.join(header), '']
                idx += 3
                while lines[idx+1]:
                    idx += 1
                    parts = lines[idx].split('|')
                    lines[idx] = parts[0] + '    ' + '|'.join(parts[1:-1])
        elif words[0] in (':type', ':param', ':rtype:', ':return:', ':raises:',
                          ':ivar'):
            # insert a blank line above
            if idx > 0 and lines[idx-1]:
                lines.insert(idx, '')
                idx += 1
        elif words[0] == '``':
            # convert to a code block
            lines[idx:idx+1] = [lines[idx].replace('``', '.. code::'), '']
            idx += 1
            while lines[idx+1].strip() != '``':
                idx += 1
                lines[idx] = (' ' * 4) + lines[idx]
            del lines[idx+1]
        elif words[0] == '*Overload':
            # ensure next line is blank
            if lines[idx+1]:
                idx += 1
                lines.insert(idx, '')
        elif words[0] == 'WARNING:':
            lines[idx:idx+1] = ['', line.replace('WARNING:', '.. warning::')]
            idx += 1
        elif words[0] == 'Notes:':
            lines[idx:idx+1] = ['', line.replace('Notes:', '.. note::')]
            idx += 1
            while lines[idx+1]:
                idx += 1
                lines[idx] = min_indent + lines[idx].lstrip()
        idx += 1

def setup(app):
    app.connect('autodoc-process-docstring', process_docstring)

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
