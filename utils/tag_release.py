#  Photini - a simple photo metadata editor.
#  http://github.com/jim-easterbrook/Photini
#  Copyright (C) 2020  Jim Easterbrook  jim@jim-easterbrook.me.uk
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see
#  <http://www.gnu.org/licenses/>.

from datetime import date
import re
import sys

# requires GitPython - 'sudo pip install gitpython'
import git


def main(argv=None):
    with open('README.rst') as rst:
        py_exiv2_version = rst.readline().split()[-1]
    message = 'python-exiv2-' + py_exiv2_version + '\n\n'
    with open('CHANGELOG.txt') as cl:
        while not cl.readline().startswith('Changes'):
            pass
        while True:
            line = cl.readline().strip()
            if not line:
                break
            message += line + '\n'
    repo = git.Repo()
    tag = repo.create_tag(py_exiv2_version, message=message)
    remote = repo.remotes.origin
    remote.push(tags=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
