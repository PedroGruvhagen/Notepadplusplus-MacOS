//
//  GlobalOverride.swift
//  Notepad++
//
//  LITERAL TRANSLATION of GlobalOverride struct
//  Source: PowerEditor/src/Parameters.h lines 469-479
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - GlobalOverride Struct (Translation of Parameters.h lines 469-479)

// Translation of struct GlobalOverride final from Parameters.h lines 469-479
struct GlobalOverride: Codable {
    // Line 472: bool enableFg = false;
    var enableFg: Bool = false

    // Line 473: bool enableBg = false;
    var enableBg: Bool = false

    // Line 474: bool enableFont = false;
    var enableFont: Bool = false

    // Line 475: bool enableFontSize = false;
    var enableFontSize: Bool = false

    // Line 476: bool enableBold = false;
    var enableBold: Bool = false

    // Line 477: bool enableItalic = false;
    var enableItalic: Bool = false

    // Line 478: bool enableUnderLine = false;
    var enableUnderLine: Bool = false

    // MARK: - Methods (Translation of line 471)

    // Line 471: bool isEnable() const {return (enableFg || enableBg || enableFont || enableFontSize || enableBold || enableItalic || enableUnderLine);}
    func isEnable() -> Bool {
        return enableFg || enableBg || enableFont || enableFontSize || enableBold || enableItalic || enableUnderLine
    }

    // MARK: - Initialization

    init() {
        // All properties have default values
    }
}
