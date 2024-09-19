// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-24  Jim Easterbrook  jim@jim-easterbrook.me.uk
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

%module(package="exiv2") error

#ifndef SWIGIMPORTED
%constant char* __doc__ = "Exiv2 error codes and log messages.";
#endif

%include "shared/preamble.i"
%include "shared/enum.i"
%include "shared/exception.i"

%include "std_except.i"


// Import Exiv2Error from exiv2 module
%fragment("import_exiv2");
%constant PyObject* Exiv2Error = PyObject_GetAttrString(
    exiv2_module, "Exiv2Error");

// Set Python logger as Exiv2 log handler
%fragment("utf8_to_wcp");
%{
static PyObject* logger = NULL;
static void log_to_python(int level, const char* msg) {
    std::string copy = msg;
    if (wcp_to_utf8(&copy))
        copy = msg;
    Py_ssize_t len = copy.size();
    while (len > 0 && copy[len-1] == '\n')
        len--;
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* res = PyObject_CallMethod(
        logger, "log", "(is#)", (level + 1) * 10, copy.data(), len);
    Py_XDECREF(res);
    PyGILState_Release(gstate);
};
%}
%init %{
{
    PyObject *module = PyImport_ImportModule("logging");
    if (!module)
        return NULL;
    logger = PyObject_CallMethod(module, "getLogger", "(s)", "exiv2");
    Py_DECREF(module);
    if (!logger)
        return NULL;
    Exiv2::LogMsg::setHandler(&log_to_python);
}
%}

// Provide Python logger and default logger as attributes of LogMsg
%extend Exiv2::LogMsg {
%constant PyObject* pythonHandler = SWIG_NewFunctionPtrObj(
    (void*)log_to_python, SWIGTYPE_p_f_int_p_q_const__char__void);
%constant PyObject* defaultHandler = SWIG_NewFunctionPtrObj(
    (void*)Exiv2::LogMsg::defaultHandler,
    SWIGTYPE_p_f_int_p_q_const__char__void);
}

// Ignore anything that's unusable from Python
%ignore Exiv2::AnyError;
%ignore Exiv2::Error;
%ignore Exiv2::WError;
%ignore Exiv2::errMsg;
%ignore Exiv2::LogMsg::LogMsg;
%ignore Exiv2::LogMsg::~LogMsg;
%ignore Exiv2::LogMsg::os;
%ignore Exiv2::LogMsg::defaultHandler;
%ignore Exiv2::operator<<;

DEFINE_CLASS_ENUM(LogMsg, Level, "Defined log levels.\n"
"\nTo suppress all log messages, either set the log level to mute or set"
"\nthe log message handler to None.",
    "debug", Exiv2::LogMsg::debug,
    "info",  Exiv2::LogMsg::info,
    "warn",  Exiv2::LogMsg::warn,
    "error", Exiv2::LogMsg::error,
    "mute",  Exiv2::LogMsg::mute);

#if EXIV2_VERSION_HEX >= 0x001c0000
DEFINE_ENUM(ErrorCode, "Complete list of all Exiv2 error codes.",
    "kerSuccess",                Exiv2::ErrorCode::kerSuccess,
    "kerGeneralError",           Exiv2::ErrorCode::kerGeneralError,
    "kerErrorMessage",           Exiv2::ErrorCode::kerErrorMessage,
    "kerCallFailed",             Exiv2::ErrorCode::kerCallFailed,
    "kerNotAnImage",             Exiv2::ErrorCode::kerNotAnImage,
    "kerInvalidDataset",         Exiv2::ErrorCode::kerInvalidDataset,
    "kerInvalidRecord",          Exiv2::ErrorCode::kerInvalidRecord,
    "kerInvalidKey",             Exiv2::ErrorCode::kerInvalidKey,
    "kerInvalidTag",             Exiv2::ErrorCode::kerInvalidTag,
    "kerValueNotSet",            Exiv2::ErrorCode::kerValueNotSet,
    "kerDataSourceOpenFailed",   Exiv2::ErrorCode::kerDataSourceOpenFailed,
    "kerFileOpenFailed",         Exiv2::ErrorCode::kerFileOpenFailed,
    "kerFileContainsUnknownImageType",
        Exiv2::ErrorCode::kerFileContainsUnknownImageType,
    "kerMemoryContainsUnknownImageType",
        Exiv2::ErrorCode::kerMemoryContainsUnknownImageType,
    "kerUnsupportedImageType",   Exiv2::ErrorCode::kerUnsupportedImageType,
    "kerFailedToReadImageData",  Exiv2::ErrorCode::kerFailedToReadImageData,
    "kerNotAJpeg",               Exiv2::ErrorCode::kerNotAJpeg,
    "kerFailedToMapFileForReadWrite",
        Exiv2::ErrorCode::kerFailedToMapFileForReadWrite,
    "kerFileRenameFailed",       Exiv2::ErrorCode::kerFileRenameFailed,
    "kerTransferFailed",         Exiv2::ErrorCode::kerTransferFailed,
    "kerMemoryTransferFailed",   Exiv2::ErrorCode::kerMemoryTransferFailed,
    "kerInputDataReadFailed",    Exiv2::ErrorCode::kerInputDataReadFailed,
    "kerImageWriteFailed",       Exiv2::ErrorCode::kerImageWriteFailed,
    "kerNoImageInInputData",     Exiv2::ErrorCode::kerNoImageInInputData,
    "kerInvalidIfdId",           Exiv2::ErrorCode::kerInvalidIfdId,
    "kerValueTooLarge",          Exiv2::ErrorCode::kerValueTooLarge,
    "kerDataAreaValueTooLarge",  Exiv2::ErrorCode::kerDataAreaValueTooLarge,
    "kerOffsetOutOfRange",       Exiv2::ErrorCode::kerOffsetOutOfRange,
    "kerUnsupportedDataAreaOffsetType",
        Exiv2::ErrorCode::kerUnsupportedDataAreaOffsetType,
    "kerInvalidCharset",         Exiv2::ErrorCode::kerInvalidCharset,
    "kerUnsupportedDateFormat",  Exiv2::ErrorCode::kerUnsupportedDateFormat,
    "kerUnsupportedTimeFormat",  Exiv2::ErrorCode::kerUnsupportedTimeFormat,
    "kerWritingImageFormatUnsupported",
        Exiv2::ErrorCode::kerWritingImageFormatUnsupported,
    "kerInvalidSettingForImage", Exiv2::ErrorCode::kerInvalidSettingForImage,
    "kerNotACrwImage",           Exiv2::ErrorCode::kerNotACrwImage,
    "kerFunctionNotSupported",   Exiv2::ErrorCode::kerFunctionNotSupported,
    "kerNoNamespaceInfoForXmpPrefix",
        Exiv2::ErrorCode::kerNoNamespaceInfoForXmpPrefix,
    "kerNoPrefixForNamespace",   Exiv2::ErrorCode::kerNoPrefixForNamespace,
    "kerTooLargeJpegSegment",    Exiv2::ErrorCode::kerTooLargeJpegSegment,
    "kerUnhandledXmpdatum",      Exiv2::ErrorCode::kerUnhandledXmpdatum,
    "kerUnhandledXmpNode",       Exiv2::ErrorCode::kerUnhandledXmpNode,
    "kerXMPToolkitError",        Exiv2::ErrorCode::kerXMPToolkitError,
    "kerDecodeLangAltPropertyFailed",
        Exiv2::ErrorCode::kerDecodeLangAltPropertyFailed,
    "kerDecodeLangAltQualifierFailed",
        Exiv2::ErrorCode::kerDecodeLangAltQualifierFailed,
    "kerEncodeLangAltPropertyFailed",
        Exiv2::ErrorCode::kerEncodeLangAltPropertyFailed,
    "kerPropertyNameIdentificationFailed",
        Exiv2::ErrorCode::kerPropertyNameIdentificationFailed,
    "kerSchemaNamespaceNotRegistered",
        Exiv2::ErrorCode::kerSchemaNamespaceNotRegistered,
    "kerNoNamespaceForPrefix",   Exiv2::ErrorCode::kerNoNamespaceForPrefix,
    "kerAliasesNotSupported",    Exiv2::ErrorCode::kerAliasesNotSupported,
    "kerInvalidXmpText",         Exiv2::ErrorCode::kerInvalidXmpText,
    "kerTooManyTiffDirectoryEntries",
        Exiv2::ErrorCode::kerTooManyTiffDirectoryEntries,
    "kerMultipleTiffArrayElementTagsInDirectory",
        Exiv2::ErrorCode::kerMultipleTiffArrayElementTagsInDirectory,
    "kerWrongTiffArrayElementTagType",
        Exiv2::ErrorCode::kerWrongTiffArrayElementTagType,
    "kerInvalidKeyXmpValue",     Exiv2::ErrorCode::kerInvalidKeyXmpValue,
    "kerInvalidIccProfile",      Exiv2::ErrorCode::kerInvalidIccProfile,
    "kerInvalidXMP",             Exiv2::ErrorCode::kerInvalidXMP,
    "kerTiffDirectoryTooLarge",  Exiv2::ErrorCode::kerTiffDirectoryTooLarge,
    "kerInvalidTypeValue",       Exiv2::ErrorCode::kerInvalidTypeValue,
    "kerInvalidLangAltValue",    Exiv2::ErrorCode::kerInvalidLangAltValue,
    "kerInvalidMalloc",          Exiv2::ErrorCode::kerInvalidMalloc,
    "kerCorruptedMetadata",      Exiv2::ErrorCode::kerCorruptedMetadata,
    "kerArithmeticOverflow",     Exiv2::ErrorCode::kerArithmeticOverflow,
    "kerMallocFailed",           Exiv2::ErrorCode::kerMallocFailed,
    "kerInvalidIconvEncoding",   Exiv2::ErrorCode::kerInvalidIconvEncoding,
    "kerErrorCount",             Exiv2::ErrorCode::kerErrorCount)
#else
DEFINE_ENUM(ErrorCode, "Complete list of all Exiv2 error codes.",
    "kerGeneralError",                Exiv2::kerGeneralError,
    "kerSuccess",                     Exiv2::kerSuccess,
    "kerErrorMessage",                Exiv2::kerErrorMessage,
    "kerCallFailed",                  Exiv2::kerCallFailed,
    "kerNotAnImage",                  Exiv2::kerNotAnImage,
    "kerInvalidDataset",              Exiv2::kerInvalidDataset,
    "kerInvalidRecord",               Exiv2::kerInvalidRecord,
    "kerInvalidKey",                  Exiv2::kerInvalidKey,
    "kerInvalidTag",                  Exiv2::kerInvalidTag,
    "kerValueNotSet",                 Exiv2::kerValueNotSet,
    "kerDataSourceOpenFailed",        Exiv2::kerDataSourceOpenFailed,
    "kerFileOpenFailed",              Exiv2::kerFileOpenFailed,
    "kerFileContainsUnknownImageType",
        Exiv2::kerFileContainsUnknownImageType,
    "kerMemoryContainsUnknownImageType",
        Exiv2::kerMemoryContainsUnknownImageType,
    "kerUnsupportedImageType",        Exiv2::kerUnsupportedImageType,
    "kerFailedToReadImageData",       Exiv2::kerFailedToReadImageData,
    "kerNotAJpeg",                    Exiv2::kerNotAJpeg,
    "kerFailedToMapFileForReadWrite", Exiv2::kerFailedToMapFileForReadWrite,
    "kerFileRenameFailed",            Exiv2::kerFileRenameFailed,
    "kerTransferFailed",              Exiv2::kerTransferFailed,
    "kerMemoryTransferFailed",        Exiv2::kerMemoryTransferFailed,
    "kerInputDataReadFailed",         Exiv2::kerInputDataReadFailed,
    "kerImageWriteFailed",            Exiv2::kerImageWriteFailed,
    "kerNoImageInInputData",          Exiv2::kerNoImageInInputData,
    "kerInvalidIfdId",                Exiv2::kerInvalidIfdId,
    "kerValueTooLarge",               Exiv2::kerValueTooLarge,
    "kerDataAreaValueTooLarge",       Exiv2::kerDataAreaValueTooLarge,
    "kerOffsetOutOfRange",            Exiv2::kerOffsetOutOfRange,
    "kerUnsupportedDataAreaOffsetType",
        Exiv2::kerUnsupportedDataAreaOffsetType,
    "kerInvalidCharset",              Exiv2::kerInvalidCharset,
    "kerUnsupportedDateFormat",       Exiv2::kerUnsupportedDateFormat,
    "kerUnsupportedTimeFormat",       Exiv2::kerUnsupportedTimeFormat,
    "kerWritingImageFormatUnsupported",
        Exiv2::kerWritingImageFormatUnsupported,
    "kerInvalidSettingForImage",      Exiv2::kerInvalidSettingForImage,
    "kerNotACrwImage",                Exiv2::kerNotACrwImage,
    "kerFunctionNotSupported",        Exiv2::kerFunctionNotSupported,
    "kerNoNamespaceInfoForXmpPrefix", Exiv2::kerNoNamespaceInfoForXmpPrefix,
    "kerNoPrefixForNamespace",        Exiv2::kerNoPrefixForNamespace,
    "kerTooLargeJpegSegment",         Exiv2::kerTooLargeJpegSegment,
    "kerUnhandledXmpdatum",           Exiv2::kerUnhandledXmpdatum,
    "kerUnhandledXmpNode",            Exiv2::kerUnhandledXmpNode,
    "kerXMPToolkitError",             Exiv2::kerXMPToolkitError,
    "kerDecodeLangAltPropertyFailed", Exiv2::kerDecodeLangAltPropertyFailed,
    "kerDecodeLangAltQualifierFailed",
        Exiv2::kerDecodeLangAltQualifierFailed,
    "kerEncodeLangAltPropertyFailed", Exiv2::kerEncodeLangAltPropertyFailed,
    "kerPropertyNameIdentificationFailed",
        Exiv2::kerPropertyNameIdentificationFailed,
    "kerSchemaNamespaceNotRegistered",
        Exiv2::kerSchemaNamespaceNotRegistered,
    "kerNoNamespaceForPrefix",        Exiv2::kerNoNamespaceForPrefix,
    "kerAliasesNotSupported",         Exiv2::kerAliasesNotSupported,
    "kerInvalidXmpText",              Exiv2::kerInvalidXmpText,
    "kerTooManyTiffDirectoryEntries", Exiv2::kerTooManyTiffDirectoryEntries,
    "kerMultipleTiffArrayElementTagsInDirectory",
        Exiv2::kerMultipleTiffArrayElementTagsInDirectory,
    "kerWrongTiffArrayElementTagType",
        Exiv2::kerWrongTiffArrayElementTagType,
    "kerInvalidKeyXmpValue",          Exiv2::kerInvalidKeyXmpValue,
    "kerInvalidIccProfile",           Exiv2::kerInvalidIccProfile,
    "kerInvalidXMP",                  Exiv2::kerInvalidXMP,
    "kerTiffDirectoryTooLarge",       Exiv2::kerTiffDirectoryTooLarge,
    "kerInvalidTypeValue",            Exiv2::kerInvalidTypeValue,
    "kerInvalidMalloc",               Exiv2::kerInvalidMalloc,
    "kerCorruptedMetadata",           Exiv2::kerCorruptedMetadata,
    "kerArithmeticOverflow",          Exiv2::kerArithmeticOverflow,
    "kerMallocFailed",                Exiv2::kerMallocFailed)
#endif // EXIV2_VERSION_HEX

%include "exiv2/error.hpp"
