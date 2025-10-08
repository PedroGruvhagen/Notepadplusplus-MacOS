//
//  ScintillaViewParams.swift
//  Notepad++
//
//  LITERAL TRANSLATION of ScintillaViewParams struct
//  Source: PowerEditor/src/Parameters.h lines 1021-1085
//  Supporting enums: PowerEditor/src/ScintillaComponent/ScintillaRef.h lines 20-23
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Supporting Enums (Translation of ScintillaRef.h lines 20-23)

// Translation of enum changeHistoryState from ScintillaRef.h line 20
enum ChangeHistoryState: Int, Codable {
    case disable = 0            // Line 20
    case margin = 1             // Line 20
    case indicator = 2          // Line 20
    case marginIndicator = 3    // Line 20
}

// Translation of enum folderStyle from ScintillaRef.h line 21
enum FolderStyle: Int, Codable {
    case FOLDER_TYPE = 0            // Line 21
    case FOLDER_STYLE_SIMPLE = 1    // Line 21
    case FOLDER_STYLE_ARROW = 2     // Line 21
    case FOLDER_STYLE_CIRCLE = 3    // Line 21
    case FOLDER_STYLE_BOX = 4       // Line 21
    case FOLDER_STYLE_NONE = 5      // Line 21
}

// Translation of enum lineWrapMethod from ScintillaRef.h line 22
enum LineWrapMethod: Int, Codable {
    case LINEWRAP_DEFAULT = 0   // Line 22
    case LINEWRAP_ALIGNED = 1   // Line 22
    case LINEWRAP_INDENT = 2    // Line 22
}

// Translation of enum lineHiliteMode from ScintillaRef.h line 23
enum LineHiliteMode: Int, Codable {
    case LINEHILITE_NONE = 0    // Line 23
    case LINEHILITE_HILITE = 1  // Line 23
    case LINEHILITE_FRAME = 2   // Line 23
}

// MARK: - ScintillaViewParams Struct (Translation of Parameters.h lines 1021-1085)

// Translation of struct ScintillaViewParams from Parameters.h lines 1021-1085
struct ScintillaViewParams: Codable {
    // Line 1023: bool _lineNumberMarginShow = true;
    var _lineNumberMarginShow: Bool = true

    // Line 1024: bool _lineNumberMarginDynamicWidth = true;
    var _lineNumberMarginDynamicWidth: Bool = true

    // Line 1025: bool _bookMarkMarginShow = true;
    var _bookMarkMarginShow: Bool = true

    // Line 1027: bool _isChangeHistoryMarginEnabled = true;
    var _isChangeHistoryMarginEnabled: Bool = true

    // Line 1028: bool _isChangeHistoryIndicatorEnabled = false;
    var _isChangeHistoryIndicatorEnabled: Bool = false

    // Line 1029: changeHistoryState _isChangeHistoryEnabled4NextSession = changeHistoryState::margin;
    var _isChangeHistoryEnabled4NextSession: ChangeHistoryState = .margin

    // Line 1031: folderStyle _folderStyle = FOLDER_STYLE_BOX;
    var _folderStyle: FolderStyle = .FOLDER_STYLE_BOX

    // Line 1032: lineWrapMethod _lineWrapMethod = LINEWRAP_ALIGNED;
    var _lineWrapMethod: LineWrapMethod = .LINEWRAP_ALIGNED

    // Line 1033: bool _foldMarginShow = true;
    var _foldMarginShow: Bool = true

    // Line 1034: bool _indentGuideLineShow = true;
    var _indentGuideLineShow: Bool = true

    // Line 1035: lineHiliteMode _currentLineHiliteMode = LINEHILITE_HILITE;
    var _currentLineHiliteMode: LineHiliteMode = .LINEHILITE_HILITE

    // Line 1036: unsigned char _currentLineFrameWidth = 1; // 1-6 pixel
    var _currentLineFrameWidth: UInt8 = 1

    // Line 1037: bool _wrapSymbolShow = false;
    var _wrapSymbolShow: Bool = false

    // Line 1038: bool _doWrap = false;
    var _doWrap: Bool = false

    // Line 1039: bool _isEdgeBgMode = false;
    var _isEdgeBgMode: Bool = false

    // Line 1041: std::vector<size_t> _edgeMultiColumnPos;
    var _edgeMultiColumnPos: [Int] = []

    // Line 1042: intptr_t _zoom = 0;
    var _zoom: Int = 0

    // Line 1043: intptr_t _zoom2 = 0;
    var _zoom2: Int = 0

    // Line 1044: bool _whiteSpaceShow = false;
    var _whiteSpaceShow: Bool = false

    // Line 1045: bool _eolShow = false;
    var _eolShow: Bool = false

    // Line 1046-1047: enum crlfMode and _eolMode
    // Translation of nested enum from Parameters.h lines 1046-1047
    enum CrlfMode: Int, Codable {
        case plainText = 0                          // Line 1046
        case roundedRectangleText = 1               // Line 1046
        case plainTextCustomColor = 2               // Line 1046
        case roundedRectangleTextCustomColor = 3    // Line 1046
    }
    var _eolMode: CrlfMode = .roundedRectangleText

    // Line 1048: bool _npcShow = false;
    var _npcShow: Bool = false

    // Line 1049-1050: enum npcMode and _npcMode
    // Translation of nested enum from Parameters.h lines 1049-1050
    enum NpcMode: Int, Codable {
        case identity = 0       // Line 1049
        case abbreviation = 1   // Line 1049
        case codepoint = 2      // Line 1049
    }
    var _npcMode: NpcMode = .abbreviation

    // Line 1051: bool _npcCustomColor = false;
    var _npcCustomColor: Bool = false

    // Line 1052: bool _npcIncludeCcUniEol = false;
    var _npcIncludeCcUniEol: Bool = false

    // Line 1053: bool _ccUniEolShow = true;
    var _ccUniEolShow: Bool = true

    // Line 1054: bool _npcNoInputC0 = true;
    var _npcNoInputC0: Bool = true

    // Line 1056: int _borderWidth = 2;
    var _borderWidth: Int = 2

    // Line 1057: bool _virtualSpace = false;
    var _virtualSpace: Bool = false

    // Line 1058: bool _scrollBeyondLastLine = true;
    var _scrollBeyondLastLine: Bool = true

    // Line 1059: bool _rightClickKeepsSelection = false;
    var _rightClickKeepsSelection: Bool = false

    // Line 1060: bool _selectedTextForegroundSingleColor = false;
    var _selectedTextForegroundSingleColor: Bool = false

    // Line 1061: bool _disableAdvancedScrolling = false;
    var _disableAdvancedScrolling: Bool = false

    // Line 1062: bool _doSmoothFont = false;
    var _doSmoothFont: Bool = false

    // Line 1063: bool _showBorderEdge = true;
    var _showBorderEdge: Bool = true

    // Line 1065: unsigned char _paddingLeft = 0; // 0-9 pixel
    var _paddingLeft: UInt8 = 0

    // Line 1066: unsigned char _paddingRight = 0; // 0-9 pixel
    var _paddingRight: UInt8 = 0

    // Line 1070: unsigned char _distractionFreeDivPart = 4; // 3-9 parts
    var _distractionFreeDivPart: UInt8 = 4

    // Line 1081: bool _lineCopyCutWithoutSelection = true;
    var _lineCopyCutWithoutSelection: Bool = true

    // Line 1083: bool _multiSelection = true;
    var _multiSelection: Bool = true

    // Line 1084: bool _columnSel2MultiEdit = true;
    var _columnSel2MultiEdit: Bool = true

    // MARK: - Methods (Translation of lines 1072-1079)

    // Line 1072-1079: int getDistractionFreePadding(int editViewWidth) const
    func getDistractionFreePadding(editViewWidth: Int) -> Int {
        let defaultDiviser = 4
        let diviser = _distractionFreeDivPart > 2 ? Int(_distractionFreeDivPart) : defaultDiviser
        var paddingLen = editViewWidth / diviser
        if paddingLen <= 0 {
            paddingLen = editViewWidth / defaultDiviser
        }
        return paddingLen
    }

    // MARK: - Initialization

    // Default initializer - C++ has implicit default constructor
    init() {
        // All properties have default values
    }
}
