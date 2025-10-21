# python-exiv2 - Python interface to exiv2
# http://github.com/jim-easterbrook/python-exiv2
# Copyright (C) 2025  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
# This file is part of python-exiv2.
#
# python-exiv2 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# python-exiv2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with python-exiv2.  If not, see <http://www.gnu.org/licenses/>.

import os
import pprint
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET


def get_version(incl_dir):
    with open(os.path.join(incl_dir, 'exv_conf.h')) as cnf:
        for line in cnf.readlines():
            words = line.split()
            if len(words) < 3:
                continue
            if words[0] == '#define' and words[1] == 'EXV_PACKAGE_VERSION':
                version = [int(x) for x in eval(words[2]).split('.')]
                return tuple(version + [0, 0])
    return 0, 0, 0, 0


def get_description(node):
    brief = []
    for para in node.find('briefdescription').iterfind('para'):
        brief.append(''.join(para.itertext()))
    detailed = []
    for para in node.find('detaileddescription').iterfind('para'):
        detailed.append(''.join(para.itertext()))
    return '\n\n'.join(brief + detailed)


def main():
    # get source directory to process
    if len(sys.argv) != 2:
        print('Usage: %s path' % sys.argv[0])
        return 1
    incl_dir = os.path.normpath(sys.argv[1])
    if os.path.basename(incl_dir) != 'exiv2':
        incl_dir = os.path.join(incl_dir, 'exiv2')
    if not os.path.isdir(incl_dir):
        print('Directory %s not found' % incl_dir)
        return 2
    # get exiv2 version
    exiv2_version = get_version(incl_dir)
    with tempfile.TemporaryDirectory() as tmp_dir:
        # create temporary Doxygen file
        doxyfile = os.path.join(tmp_dir, 'doxyfile')
        with open(doxyfile, 'w') as df:
            df.write(f'''OUTPUT_DIRECTORY = {tmp_dir}
QUIET = YES
WARNINGS = NO
WARN_IF_UNDOCUMENTED = NO
WARN_IF_DOC_ERROR = NO
INPUT = {incl_dir}
GENERATE_XML = YES
XML_PROGRAMLISTING = NO
GENERATE_HTML = NO
GENERATE_LATEX = NO
''')
        # run doxygen
        subprocess.run(['doxygen', doxyfile], check=True)
        # read doxygen output
        enum_data = {}
        xml_dir = os.path.join(tmp_dir, 'xml')
        for file in os.listdir(xml_dir):
            if not (file.startswith('class') or file.startswith('namespace')):
                continue
            tree = ET.parse(os.path.join(xml_dir, file))
            parent_map = {c:p for p in tree.iter() for c in p}
            root = tree.getroot().find('compounddef')
            root_name = root.findtext('compoundname')
            # look for Exiv2::ImageType namespace (libexiv2 < 0.28)
            if root_name == 'Exiv2::ImageType':
                name = root_name
                enum_data[name] = {
                    'doc': get_description(root),
                    'strong': True,
                    'values': {},
                    }
                for value in root.iter('memberdef'):
                    if value.get('kind') != 'variable':
                        continue
                    enum_data[name]['values'][value.findtext('name')] = {
                        'doc': get_description(value)}
                continue
            # look for members of enums
            for child in root.iter('memberdef'):
                if child.get('kind') != 'enum':
                    continue
                name = child.findtext('name')
                if name not in ('AccessMode', 'ByteOrder', 'CharsetId',
                                'ErrorCode', 'IfdId', 'ImageType', 'Level',
                                'MetadataId', 'Position', 'SectionId', 'TypeId',
                                'XmpArrayType', 'XmpCategory', 'XmpStruct'):
                    continue
                parent = parent_map[parent_map[child]]
                name = root_name + '::' + name
                enum_data[name] = {
                    'doc': get_description(child),
                    'strong': child.get('strong') == 'yes',
                    'values': {},
                    }
                for value in child.iterfind('enumvalue'):
                    enum_data[name]['values'][value.findtext('name')] = {
                        'doc': get_description(value)}
    # create output dir
    output_dir = os.path.join(
        'src', 'interface', '{}_{}_{}'.format(*exiv2_version))
    os.makedirs(output_dir, exist_ok=True)
    # save result
    with open(os.path.join(output_dir, 'enum_members.i'), 'w') as df:
        df.write('''/* This file was generated by utils/extract_enums.py
 * Do not make changes to this file.
 */
''')
        for key, data in enum_data.items():
            df.write(f'''%fragment("_get_enum_data"{{{key}}}, "header",
    fragment="_get_enum_data") {{
static PyObject* _get_enum_data_%mangle({key})() {{
    return _get_enum_data("{key}",''')
            root = key
            if not data['strong']:
                root = '::'.join(root.split('::')[:-1])
            for name in data['values']:
                df.write(f'\n        "{name}", {root}::{name},')
            df.write('''
        NULL);
};
}
''')
    # purge data of nearly everything but non-empty doc strings
    for data in enum_data.values():
        del data['strong']
        data['values'] = dict(
            (k, v['doc']) for (k, v) in data['values'].items() if v['doc'])
    # create output dir
    output_dir = os.path.join('src', 'swig-{}_{}_{}'.format(*exiv2_version))
    os.makedirs(output_dir, exist_ok=True)
    # save result
    with open(os.path.join(output_dir, '_enum_data.py'), 'w') as df:
        df.write('''# This file was generated by utils/extract_enums.py
# Do not make changes to this file.

enum_data = ''')
        df.write(pprint.pformat(enum_data, width=75))
    return 0


if __name__ == "__main__":
    sys.exit(main())
