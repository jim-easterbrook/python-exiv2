from conans import ConanFile
from conans.tools import os_info
from conans.model.version import Version

class Exiv2Conan(ConanFile):
    settings = 'os', 'compiler', 'build_type', 'arch'
    generators = 'cmake'
    options = {'unitTests': [True, False],
               'xmp': [True, False],
               'iconv': [True, False],
               'webready': [True, False],
              }
    default_options = ('unitTests=False',
                       'xmp=False',
                       'iconv=True',
                       'webready=False',
                      )

    def configure(self):
        self.options['libcurl'].shared = False
        self.options['libcurl'].with_openssl = True
        self.options['gtest'].shared = True

    def requirements(self):
        self.requires('zlib/1.2.11')

        if os_info.is_windows and self.options.iconv:
            self.requires('libiconv/1.15')

        if self.options.unitTests:
            if self.settings.compiler == "Visual Studio" and Version(self.settings.compiler.version.value) <= "12":
                self.requires('gtest/1.8.0')
            else:
                self.requires('gtest/1.8.1')

        if self.options.webready and not os_info.is_macos:
            # Note: This difference in versions is just due to a combination of corner cases in the
            # recipes and the OS & compiler versions used in Travis and AppVeyor. In normal cases we
            # could use any of the versions.Also note that the issue was not with libcurl but with
            # libopenssl (a transitive dependency)
            if os_info.is_windows:
                self.requires('libcurl/7.69.1')
                self.options['libcurl'].with_openssl = False
                self.options['libcurl'].with_winssl = True
            else:
                self.requires('libcurl/7.64.1')

        if self.options.xmp:
            self.requires('XmpSdk/2016.7@piponazo/stable') # from conan-piponazo
        else:
            self.requires('expat/2.2.7')

    def imports(self):
        self.copy('*.dll', dst='conanDlls', src='bin')
        self.copy('*.dylib', dst='bin', src='lib')
