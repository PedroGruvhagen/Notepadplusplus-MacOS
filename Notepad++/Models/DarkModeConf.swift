//
//  DarkModeConf.swift
//  Notepad++
//
//  LITERAL TRANSLATION of DarkMode structures
//  Source: PowerEditor/src/Parameters.h lines 775-832
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation
import AppKit

// MARK: - Color Constants (Translation of lines 775-778)

// Line 775: constexpr COLORREF g_cDefaultMainDark = RGB(0xDE, 0xDE, 0xDE);
let g_cDefaultMainDark: UInt32 = 0xDEDEDE

// Line 776: constexpr COLORREF g_cDefaultSecondaryDark = RGB(0x4C, 0xC2, 0xFF);
let g_cDefaultSecondaryDark: UInt32 = 0x4CC2FF

// Line 777: constexpr COLORREF g_cDefaultMainLight = RGB(0x21, 0x21, 0x21);
let g_cDefaultMainLight: UInt32 = 0x212121

// Line 778: constexpr COLORREF g_cDefaultSecondaryLight = RGB(0x00, 0x78, 0xD4);
let g_cDefaultSecondaryLight: UInt32 = 0x0078D4

// MARK: - FluentColor Enum (Translation of lines 780-793)

// Translation of enum class FluentColor from Parameters.h lines 780-793
enum FluentColor: Int, Codable {
    case defaultColor = 0   // Line 782
    case red = 1            // Line 783
    case green = 2          // Line 784
    case blue = 3           // Line 785
    case purple = 4         // Line 786
    case cyan = 5           // Line 787
    case olive = 6          // Line 788
    case yellow = 7         // Line 789
    case accent = 8         // Line 790
    case custom = 9         // Line 791
    case maxValue = 10      // Line 792
}

// MARK: - TbIconInfo Struct (Translation of lines 795-807)

// Translation of struct TbIconInfo from Parameters.h lines 795-807
// Note: toolBarStatusType enum defined in ToolBar.h line 34
// enum toolBarStatusType {TB_SMALL, TB_LARGE, TB_SMALL2, TB_LARGE2, TB_STANDARD};
struct TbIconInfo: Codable {
    // Line 797: toolBarStatusType _tbIconSet = TB_STANDARD;
    var _tbIconSet: Int = 4  // TB_STANDARD (from ToolBar.h: TB_SMALL=0, TB_LARGE=1, TB_SMALL2=2, TB_LARGE2=3, TB_STANDARD=4)

    // Line 800: FluentColor _tbColor = FluentColor::defaultColor;
    var _tbColor: FluentColor = .defaultColor

    // Line 803: COLORREF _tbCustomColor = 0;
    var _tbCustomColor: UInt32 = 0

    // Line 806: bool _tbUseMono = false;
    var _tbUseMono: Bool = false

    init(tbIconSet: Int = 0, tbColor: FluentColor = .defaultColor, tbCustomColor: UInt32 = 0, tbUseMono: Bool = false) {
        self._tbIconSet = tbIconSet
        self._tbColor = tbColor
        self._tbCustomColor = tbCustomColor
        self._tbUseMono = tbUseMono
    }
}

// MARK: - AdvOptDefaults Struct (Translation of lines 809-815)

// Translation of struct AdvOptDefaults final from Parameters.h lines 809-815
struct AdvOptDefaults: Codable {
    // Line 811: std::wstring _xmlFileName;
    var _xmlFileName: String

    // Line 812: TbIconInfo _tbIconInfo{};
    var _tbIconInfo: TbIconInfo

    // Line 813: int _tabIconSet = -1;
    var _tabIconSet: Int

    // Line 814: bool _tabUseTheme = false;
    var _tabUseTheme: Bool

    init(xmlFileName: String = "", tbIconInfo: TbIconInfo = TbIconInfo(), tabIconSet: Int = -1, tabUseTheme: Bool = false) {
        self._xmlFileName = xmlFileName
        self._tbIconInfo = tbIconInfo
        self._tabIconSet = tabIconSet
        self._tabUseTheme = tabUseTheme
    }
}

// MARK: - AdvancedOptions Struct (Translation of lines 817-823)

// Translation of struct AdvancedOptions final from Parameters.h lines 817-823
struct AdvancedOptions: Codable {
    // Line 819: AdvOptDefaults _darkDefaults{ L"DarkModeDefault.xml", {TB_SMALL, FluentColor::defaultColor, 0, false}, 2, false };
    var _darkDefaults: AdvOptDefaults = AdvOptDefaults(
        xmlFileName: "DarkModeDefault.xml",
        tbIconInfo: TbIconInfo(tbIconSet: 0, tbColor: .defaultColor, tbCustomColor: 0, tbUseMono: false), // TB_SMALL = 0
        tabIconSet: 2,
        tabUseTheme: false
    )

    // Line 820: AdvOptDefaults _lightDefaults{ L"", { TB_STANDARD, FluentColor::defaultColor, 0, false }, 0, true };
    var _lightDefaults: AdvOptDefaults = AdvOptDefaults(
        xmlFileName: "",
        tbIconInfo: TbIconInfo(tbIconSet: 4, tbColor: .defaultColor, tbCustomColor: 0, tbUseMono: false), // TB_STANDARD = 4
        tabIconSet: 0,
        tabUseTheme: true
    )

    // Line 822: bool _enableWindowsMode = false;
    var _enableWindowsMode: Bool = false
}

// MARK: - NppDarkMode Namespace Types (Translation of NppDarkMode.h lines 67-76 and 28-42)

// Translation of enum ColorTone from NppDarkMode.h lines 67-76
enum ColorTone: Int, Codable {
    case blackTone = 0      // Line 68
    case redTone = 1        // Line 69
    case greenTone = 2      // Line 70
    case blueTone = 3       // Line 71
    case purpleTone = 4     // Line 72
    case cyanTone = 5       // Line 73
    case oliveTone = 6      // Line 74
    case customizedTone = 32 // Line 75
}

// Translation of struct Colors from NppDarkMode.h lines 28-42
// Default values from NppDarkMode.cpp lines 193-206 (darkColors constant)
struct DarkModeColors: Codable {
    // Line 30: COLORREF background = 0;
    // Default: HEXRGB(0x202020) from NppDarkMode.cpp:194
    var background: UInt32 = 0x202020

    // Line 31: COLORREF softerBackground = 0; // ctrl background color
    // Default: HEXRGB(0x383838) from NppDarkMode.cpp:195
    var softerBackground: UInt32 = 0x383838

    // Line 32: COLORREF hotBackground = 0;
    // Default: HEXRGB(0x454545) from NppDarkMode.cpp:196
    var hotBackground: UInt32 = 0x454545

    // Line 33: COLORREF pureBackground = 0; // dlg background color
    // Default: HEXRGB(0x202020) from NppDarkMode.cpp:197
    var pureBackground: UInt32 = 0x202020

    // Line 34: COLORREF errorBackground = 0;
    // Default: HEXRGB(0xB00000) from NppDarkMode.cpp:198
    var errorBackground: UInt32 = 0xB00000

    // Line 35: COLORREF text = 0;
    // Default: HEXRGB(0xE0E0E0) from NppDarkMode.cpp:199
    var text: UInt32 = 0xE0E0E0

    // Line 36: COLORREF darkerText = 0;
    // Default: HEXRGB(0xC0C0C0) from NppDarkMode.cpp:200
    var darkerText: UInt32 = 0xC0C0C0

    // Line 37: COLORREF disabledText = 0;
    // Default: HEXRGB(0x808080) from NppDarkMode.cpp:201
    var disabledText: UInt32 = 0x808080

    // Line 38: COLORREF linkText = 0;
    // Default: HEXRGB(0xFFFF00) from NppDarkMode.cpp:202
    var linkText: UInt32 = 0xFFFF00

    // Line 39: COLORREF edge = 0;
    // Default: HEXRGB(0x646464) from NppDarkMode.cpp:203
    var edge: UInt32 = 0x646464

    // Line 40: COLORREF hotEdge = 0;
    // Default: HEXRGB(0x9B9B9B) from NppDarkMode.cpp:204
    var hotEdge: UInt32 = 0x9B9B9B

    // Line 41: COLORREF disabledEdge = 0;
    // Default: HEXRGB(0x484848) from NppDarkMode.cpp:205
    var disabledEdge: UInt32 = 0x484848

    // MARK: - Initialization

    // Default constructor matches getDarkModeDefaultColors(blackTone) from NppDarkMode.cpp:845-872
    init() {
        // All properties initialized with darkColors defaults above
    }
}

// MARK: - DarkModeConf Struct (Translation of lines 825-832)

// Translation of struct DarkModeConf final from Parameters.h lines 825-832
struct DarkModeConf: Codable {
    // Line 827: bool _isEnabled = false;
    var _isEnabled: Bool = false

    // Line 828: bool _isEnabledPlugin = true;
    var _isEnabledPlugin: Bool = true

    // Line 829: NppDarkMode::ColorTone _colorTone = NppDarkMode::blackTone;
    var _colorTone: ColorTone = .blackTone

    // Line 830: NppDarkMode::Colors _customColors = NppDarkMode::getDarkModeDefaultColors();
    var _customColors: DarkModeColors = DarkModeColors()

    // Line 831: AdvancedOptions _advOptions{};
    var _advOptions: AdvancedOptions = AdvancedOptions()

    init() {
        // All properties have default values
    }
}
