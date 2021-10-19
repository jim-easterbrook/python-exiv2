
import os
import sys
import exiv2

def main():
    print('libexiv2 version:', exiv2.versionString())
    print('python-exiv2 version:', exiv2.__version__)
    print('python-exiv2 examples:',
          os.path.join(os.path.dirname(__file__), 'examples'))

if __name__ == "__main__":
    sys.exit(main())
