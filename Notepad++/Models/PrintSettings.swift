//
//  PrintSettings.swift
//  Notepad++
//
//  LITERAL TRANSLATION of PrintSettings struct
//  Source: PowerEditor/src/Parameters.h lines 642-677
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation
import AppKit

// Translation of Windows RECT structure for print margins
// C++ RECT has {left, top, right, bottom} - all are margins, not coordinates
struct PrintMargins: Codable {
    var left: CGFloat = 0
    var top: CGFloat = 0
    var right: CGFloat = 0
    var bottom: CGFloat = 0
}

// Translation of struct PrintSettings final from Parameters.h lines 642-677
struct PrintSettings: Codable {
    // Line 643: bool _printLineNumber = true;
    var _printLineNumber: Bool = true

    // Line 644: int _printOption = SC_PRINT_COLOURONWHITE;
    // SC_PRINT_COLOURONWHITE = 3 (from Scintilla.h line 515)
    var _printOption: Int = 3

    // Line 646-648: Header strings
    var _headerLeft: String = ""
    var _headerMiddle: String = ""
    var _headerRight: String = ""

    // Line 649-651: Header font settings
    var _headerFontName: String = ""
    var _headerFontStyle: Int = 0
    var _headerFontSize: Int = 0

    // Line 653-655: Footer strings
    var _footerLeft: String = ""
    var _footerMiddle: String = ""
    var _footerRight: String = ""

    // Line 656-658: Footer font settings
    var _footerFontName: String = ""
    var _footerFontStyle: Int = 0
    var _footerFontSize: Int = 0

    // Line 660: RECT _marge = {};
    // RECT is a Windows structure {left, top, right, bottom} - margins not coordinates
    var _marge: PrintMargins = PrintMargins()

    // MARK: - Methods (Translation of lines 666-676)

    // Line 666-668: bool isHeaderPresent() const
    func isHeaderPresent() -> Bool {
        return !_headerLeft.isEmpty || !_headerMiddle.isEmpty || !_headerRight.isEmpty
    }

    // Line 670-672: bool isFooterPresent() const
    func isFooterPresent() -> Bool {
        return !_footerLeft.isEmpty || !_footerMiddle.isEmpty || !_footerRight.isEmpty
    }

    // Line 674-676: bool isUserMargePresent() const
    func isUserMargePresent() -> Bool {
        return _marge.left != 0 || _marge.top != 0 || _marge.right != 0 || _marge.bottom != 0
    }

    // MARK: - Initialization

    // Line 662-664: Constructor initializes _marge to all zeros
    init() {
        // All properties have default values
        // _marge is initialized to PrintMargins() (equivalent to C++ {0,0,0,0})
    }
}
