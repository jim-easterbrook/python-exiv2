// python-exiv2 - Python interface to libexiv2
// http://github.com/jim-easterbrook/python-exiv2
// Copyright (C) 2021-25  Jim Easterbrook  jim@jim-easterbrook.me.uk
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
        return INIT_ERROR_RETURN;
    logger = PyObject_CallMethod(module, "getLogger", "(s)", "exiv2");
    Py_DECREF(module);
    if (!logger) {
        PyErr_SetString(PyExc_RuntimeError, "logging.getLogger failed.");
        return INIT_ERROR_RETURN;
    }
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

%fragment("error_code_list", "header", fragment="get_enum_list") {
static PyObject* error_code_list() {
#if EXIV2_VERSION_HEX >= 0x001c0000
    using Exiv2::ErrorCode;
    PyObject* result = _get_enum_list(
        0,
        "kerSuccess",                ErrorCode::kerSuccess,
        "kerGeneralError",           ErrorCode::kerGeneralError,
        "kerErrorMessage",           ErrorCode::kerErrorMessage,
        "kerCallFailed",             ErrorCode::kerCallFailed,
        "kerNotAnImage",             ErrorCode::kerNotAnImage,
        "kerInvalidDataset",         ErrorCode::kerInvalidDataset,
        "kerInvalidRecord",          ErrorCode::kerInvalidRecord,
        "kerInvalidKey",             ErrorCode::kerInvalidKey,
        "kerInvalidTag",             ErrorCode::kerInvalidTag,
        "kerValueNotSet",            ErrorCode::kerValueNotSet,
        "kerDataSourceOpenFailed",   ErrorCode::kerDataSourceOpenFailed,
        "kerFileOpenFailed",         ErrorCode::kerFileOpenFailed,
        "kerFileContainsUnknownImageType",
            ErrorCode::kerFileContainsUnknownImageType,
        "kerMemoryContainsUnknownImageType",
            ErrorCode::kerMemoryContainsUnknownImageType,
        "kerUnsupportedImageType",   ErrorCode::kerUnsupportedImageType,
        "kerFailedToReadImageData",  ErrorCode::kerFailedToReadImageData,
        "kerNotAJpeg",               ErrorCode::kerNotAJpeg,
        "kerFailedToMapFileForReadWrite",
            ErrorCode::kerFailedToMapFileForReadWrite,
        "kerFileRenameFailed",       ErrorCode::kerFileRenameFailed,
        "kerTransferFailed",         ErrorCode::kerTransferFailed,
        "kerMemoryTransferFailed",   ErrorCode::kerMemoryTransferFailed,
        "kerInputDataReadFailed",    ErrorCode::kerInputDataReadFailed,
        "kerImageWriteFailed",       ErrorCode::kerImageWriteFailed,
        "kerNoImageInInputData",     ErrorCode::kerNoImageInInputData,
        "kerInvalidIfdId",           ErrorCode::kerInvalidIfdId,
        "kerValueTooLarge",          ErrorCode::kerValueTooLarge,
        "kerDataAreaValueTooLarge",  ErrorCode::kerDataAreaValueTooLarge,
        "kerOffsetOutOfRange",       ErrorCode::kerOffsetOutOfRange,
        "kerUnsupportedDataAreaOffsetType",
            ErrorCode::kerUnsupportedDataAreaOffsetType,
        "kerInvalidCharset",         ErrorCode::kerInvalidCharset,
        "kerUnsupportedDateFormat",  ErrorCode::kerUnsupportedDateFormat,
        "kerUnsupportedTimeFormat",  ErrorCode::kerUnsupportedTimeFormat,
        "kerWritingImageFormatUnsupported",
            ErrorCode::kerWritingImageFormatUnsupported,
        "kerInvalidSettingForImage", ErrorCode::kerInvalidSettingForImage,
        "kerNotACrwImage",           ErrorCode::kerNotACrwImage,
        "kerFunctionNotSupported",   ErrorCode::kerFunctionNotSupported,
        "kerNoNamespaceInfoForXmpPrefix",
            ErrorCode::kerNoNamespaceInfoForXmpPrefix,
        "kerNoPrefixForNamespace",   ErrorCode::kerNoPrefixForNamespace,
        "kerTooLargeJpegSegment",    ErrorCode::kerTooLargeJpegSegment,
        "kerUnhandledXmpdatum",      ErrorCode::kerUnhandledXmpdatum,
        "kerUnhandledXmpNode",       ErrorCode::kerUnhandledXmpNode,
        "kerXMPToolkitError",        ErrorCode::kerXMPToolkitError,
        "kerDecodeLangAltPropertyFailed",
            ErrorCode::kerDecodeLangAltPropertyFailed,
        "kerDecodeLangAltQualifierFailed",
            ErrorCode::kerDecodeLangAltQualifierFailed,
        "kerEncodeLangAltPropertyFailed",
            ErrorCode::kerEncodeLangAltPropertyFailed,
        "kerPropertyNameIdentificationFailed",
            ErrorCode::kerPropertyNameIdentificationFailed,
        "kerSchemaNamespaceNotRegistered",
            ErrorCode::kerSchemaNamespaceNotRegistered,
        "kerNoNamespaceForPrefix",   ErrorCode::kerNoNamespaceForPrefix,
        "kerAliasesNotSupported",    ErrorCode::kerAliasesNotSupported,
        "kerInvalidXmpText",         ErrorCode::kerInvalidXmpText,
        "kerTooManyTiffDirectoryEntries",
            ErrorCode::kerTooManyTiffDirectoryEntries,
        "kerMultipleTiffArrayElementTagsInDirectory",
            ErrorCode::kerMultipleTiffArrayElementTagsInDirectory,
        "kerWrongTiffArrayElementTagType",
            ErrorCode::kerWrongTiffArrayElementTagType,
        "kerInvalidKeyXmpValue",     ErrorCode::kerInvalidKeyXmpValue,
        "kerInvalidIccProfile",      ErrorCode::kerInvalidIccProfile,
        "kerInvalidXMP",             ErrorCode::kerInvalidXMP,
        "kerTiffDirectoryTooLarge",  ErrorCode::kerTiffDirectoryTooLarge,
        "kerInvalidTypeValue",       ErrorCode::kerInvalidTypeValue,
        "kerInvalidLangAltValue",    ErrorCode::kerInvalidLangAltValue,
        "kerInvalidMalloc",          ErrorCode::kerInvalidMalloc,
        "kerCorruptedMetadata",      ErrorCode::kerCorruptedMetadata,
        "kerArithmeticOverflow",     ErrorCode::kerArithmeticOverflow,
        "kerMallocFailed",           ErrorCode::kerMallocFailed,
        "kerInvalidIconvEncoding",   ErrorCode::kerInvalidIconvEncoding,
        NULL);
%#if EXIV2_TEST_VERSION(0,28,4)
    extend_enum_list(result, "kerFileAccessDisabled",
                     static_cast<long>(ErrorCode::kerFileAccessDisabled));
%#endif // EXIV2_TEST_VERSION
#else // EXIV2_VERSION_HEX >= 0x001c0000
    PyObject* result = _get_enum_list(
        0,
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
        "kerFailedToMapFileForReadWrite",
            Exiv2::kerFailedToMapFileForReadWrite,
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
        "kerNoNamespaceInfoForXmpPrefix",
            Exiv2::kerNoNamespaceInfoForXmpPrefix,
        "kerNoPrefixForNamespace",        Exiv2::kerNoPrefixForNamespace,
        "kerTooLargeJpegSegment",         Exiv2::kerTooLargeJpegSegment,
        "kerUnhandledXmpdatum",           Exiv2::kerUnhandledXmpdatum,
        "kerUnhandledXmpNode",            Exiv2::kerUnhandledXmpNode,
        "kerXMPToolkitError",             Exiv2::kerXMPToolkitError,
        "kerDecodeLangAltPropertyFailed",
            Exiv2::kerDecodeLangAltPropertyFailed,
        "kerDecodeLangAltQualifierFailed",
            Exiv2::kerDecodeLangAltQualifierFailed,
        "kerEncodeLangAltPropertyFailed",
            Exiv2::kerEncodeLangAltPropertyFailed,
        "kerPropertyNameIdentificationFailed",
            Exiv2::kerPropertyNameIdentificationFailed,
        "kerSchemaNamespaceNotRegistered",
            Exiv2::kerSchemaNamespaceNotRegistered,
        "kerNoNamespaceForPrefix",        Exiv2::kerNoNamespaceForPrefix,
        "kerAliasesNotSupported",         Exiv2::kerAliasesNotSupported,
        "kerInvalidXmpText",              Exiv2::kerInvalidXmpText,
        "kerTooManyTiffDirectoryEntries",
            Exiv2::kerTooManyTiffDirectoryEntries,
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
        "kerMallocFailed",                Exiv2::kerMallocFailed,
        NULL);
#endif // EXIV2_VERSION_HEX >= 0x001c0000
    return result;
}
}

%fragment("error_code_list");
DEFINE_ENUM_FROM_FUNC(ErrorCode, "Complete list of all Exiv2 error codes.",
                      error_code_list);

%include "exiv2/error.hpp"
