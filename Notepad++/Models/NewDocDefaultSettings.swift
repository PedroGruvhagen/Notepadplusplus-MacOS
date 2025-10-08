//
//  NewDocDefaultSettings.swift
//  Notepad++
//
//  LITERAL TRANSLATION of NewDocDefaultSettings struct
//  Source: PowerEditor/src/Parameters.h lines 612-621
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Supporting Enums

// Translation of enum class EolType from Parameters.h lines 84-93
enum EolType: UInt8, Codable {
    case windows = 0    // Line 86
    case macos = 1      // Line 87
    case unix = 2       // Line 88
    case unknown = 3    // Line 91 - cannot be the first value for legacy code

    // Line 92: osdefault = windows
    static let osdefault: EolType = .windows
}

// Translation of enum UniMode from Parameters.h lines 105-113
enum UniMode: Int, Codable {
    case uni8Bit = 0        // Line 106 - ANSI
    case uniUTF8 = 1        // Line 107 - UTF-8 with BOM
    case uni16BE = 2        // Line 108 - UTF-16 Big Endian with BOM
    case uni16LE = 3        // Line 109 - UTF-16 Little Endian with BOM
    case uniCookie = 4      // Line 110 - UTF-8 without BOM
    case uni7Bit = 5        // Line 111
    case uni16BE_NoBOM = 6  // Line 112 - UTF-16 Big Endian without BOM
    case uni16LE_NoBOM = 7  // Line 113 - UTF-16 Little Endian without BOM
}

// Translation of enum LangType from Notepad_plus_msgs.h lines 26-43
// This is a massive enum with 90+ language types
enum LangType: Int, Codable {
    case L_TEXT = 0
    case L_PHP = 1
    case L_C = 2
    case L_CPP = 3
    case L_CS = 4
    case L_OBJC = 5
    case L_JAVA = 6
    case L_RC = 7
    case L_HTML = 8
    case L_XML = 9
    case L_MAKEFILE = 10
    case L_PASCAL = 11
    case L_BATCH = 12
    case L_INI = 13
    case L_ASCII = 14
    case L_USER = 15
    case L_ASP = 16
    case L_SQL = 17
    case L_VB = 18
    case L_JS_EMBEDDED = 19  // Don't use - use L_JAVASCRIPT instead
    case L_CSS = 20
    case L_PERL = 21
    case L_PYTHON = 22
    case L_LUA = 23
    case L_TEX = 24
    case L_FORTRAN = 25
    case L_BASH = 26
    case L_FLASH = 27
    case L_NSIS = 28
    case L_TCL = 29
    case L_LISP = 30
    case L_SCHEME = 31
    case L_ASM = 32
    case L_DIFF = 33
    case L_PROPS = 34
    case L_PS = 35
    case L_RUBY = 36
    case L_SMALLTALK = 37
    case L_VHDL = 38
    case L_KIX = 39
    case L_AU3 = 40
    case L_CAML = 41
    case L_ADA = 42
    case L_VERILOG = 43
    case L_MATLAB = 44
    case L_HASKELL = 45
    case L_INNO = 46
    case L_SEARCHRESULT = 47
    case L_CMAKE = 48
    case L_YAML = 49
    case L_COBOL = 50
    case L_GUI4CLI = 51
    case L_D = 52
    case L_POWERSHELL = 53
    case L_R = 54
    case L_JSP = 55
    case L_COFFEESCRIPT = 56
    case L_JSON = 57
    case L_JAVASCRIPT = 58
    case L_FORTRAN_77 = 59
    case L_BAANC = 60
    case L_SREC = 61
    case L_IHEX = 62
    case L_TEHEX = 63
    case L_SWIFT = 64
    case L_ASN1 = 65
    case L_AVS = 66
    case L_BLITZBASIC = 67
    case L_PUREBASIC = 68
    case L_FREEBASIC = 69
    case L_CSOUND = 70
    case L_ERLANG = 71
    case L_ESCRIPT = 72
    case L_FORTH = 73
    case L_LATEX = 74
    case L_MMIXAL = 75
    case L_NIM = 76
    case L_NNCRONTAB = 77
    case L_OSCRIPT = 78
    case L_REBOL = 79
    case L_REGISTRY = 80
    case L_RUST = 81
    case L_SPICE = 82
    case L_TXT2TAGS = 83
    case L_VISUALPROLOG = 84
    case L_TYPESCRIPT = 85
    case L_JSON5 = 86
    case L_MSSQL = 87
    case L_GDSCRIPT = 88
    case L_HOLLYWOOD = 89
    case L_GOLANG = 90
    case L_RAKU = 91
    case L_TOML = 92
    case L_SAS = 93
    case L_ERRORLIST = 94
    case L_EXTERNAL = 95  // The end of enumerated language type, always at the end
}

// MARK: - NewDocDefaultSettings Struct (Translation of Parameters.h lines 612-621)

// Translation of struct NewDocDefaultSettings final from Parameters.h lines 612-621
struct NewDocDefaultSettings: Codable {
    // Line 614: EolType _format = EolType::osdefault;
    var _format: EolType = .osdefault

    // Line 615: UniMode _unicodeMode = uniCookie;
    var _unicodeMode: UniMode = .uniCookie

    // Line 616: bool _openAnsiAsUtf8 = true;
    var _openAnsiAsUtf8: Bool = true

    // Line 617: LangType _lang = L_TEXT;
    var _lang: LangType = .L_TEXT

    // Line 618: int _codepage = -1; // -1 when not using
    var _codepage: Int = -1

    // Line 619: bool _addNewDocumentOnStartup = false;
    var _addNewDocumentOnStartup: Bool = false

    // Line 620: bool _useContentAsTabName = false;
    var _useContentAsTabName: Bool = false

    // MARK: - Initialization

    // Default initializer - C++ has implicit default constructor
    init() {
        // All properties have default values
    }
}
