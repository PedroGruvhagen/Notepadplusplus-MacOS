//
//  DockingManagerData.swift
//  Notepad++
//
//  LITERAL TRANSLATION of DockingManagerData and related structures
//  Source: PowerEditor/src/Parameters.h lines 354-431
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation
import CoreGraphics

// MARK: - Constants (Translation of Parameters.h lines 354, 400)

// Line 354: #define FWI_PANEL_WH_DEFAULT 100
let FWI_PANEL_WH_DEFAULT: Int = 100

// Line 400: #define DMD_PANEL_WH_DEFAULT 200
let DMD_PANEL_WH_DEFAULT: Int = 200

// HIGH_CAPTION is a Windows system constant (SM_CYCAPTION)
// On Windows, GetSystemMetrics(SM_CYCAPTION) typically returns 23 pixels for caption height
// For macOS translation, we use a reasonable default
let HIGH_CAPTION: Int = 23

// MARK: - FloatingWindowInfo Struct (Translation of Parameters.h lines 355-368)

// Translation of struct FloatingWindowInfo from Parameters.h lines 355-368
struct FloatingWindowInfo: Codable {
    // Line 357: int _cont = 0;
    var _cont: Int = 0

    // Line 358: RECT _pos = { 0, 0, FWI_PANEL_WH_DEFAULT, FWI_PANEL_WH_DEFAULT };
    // Windows RECT structure: {left, top, right, bottom}
    var _pos: CGRect = CGRect(x: 0, y: 0, width: CGFloat(FWI_PANEL_WH_DEFAULT), height: CGFloat(FWI_PANEL_WH_DEFAULT))

    // MARK: - Initialization

    // Default constructor (C++ has implicit default)
    init() {
        // All properties have default values
    }

    // Line 360-367: FloatingWindowInfo(int cont, int x, int y, int w, int h)
    init(cont: Int, x: Int, y: Int, w: Int, h: Int) {
        self._cont = cont
        // C++ RECT: left = x, top = y, right = w, bottom = h (absolute coordinates)
        // Convert to CGRect: origin = (x, y), size = (right-left, bottom-top)
        self._pos = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w - x), height: CGFloat(h - y))
    }
}

// MARK: - PluginDlgDockingInfo Struct (Translation of Parameters.h lines 371-388)

// Translation of struct PluginDlgDockingInfo final from Parameters.h lines 371-388
struct PluginDlgDockingInfo: Codable, Equatable {
    // Line 373: std::wstring _name;
    var _name: String = ""

    // Line 374: int _internalID = -1;
    var _internalID: Int = -1

    // Line 376: int _currContainer = -1;
    var _currContainer: Int = -1

    // Line 377: int _prevContainer = -1;
    var _prevContainer: Int = -1

    // Line 378: bool _isVisible = false;
    var _isVisible: Bool = false

    // MARK: - Initialization

    // Default constructor
    init() {
        // All properties have default values
    }

    // Line 380-382: PluginDlgDockingInfo(const wchar_t* pluginName, int id, int curr, int prev, bool isVis)
    init(pluginName: String, id: Int, curr: Int, prev: Int, isVis: Bool) {
        self._name = pluginName
        self._internalID = id
        self._currContainer = curr
        self._prevContainer = prev
        self._isVisible = isVis
    }

    // MARK: - Operators (Translation of lines 384-387)

    // Line 384-387: bool operator == (const PluginDlgDockingInfo& rhs) const
    static func == (lhs: PluginDlgDockingInfo, rhs: PluginDlgDockingInfo) -> Bool {
        return lhs._internalID == rhs._internalID && lhs._name == rhs._name
    }
}

// MARK: - ContainerTabInfo Struct (Translation of Parameters.h lines 391-397)

// Translation of struct ContainerTabInfo final from Parameters.h lines 391-397
struct ContainerTabInfo: Codable {
    // Line 393: int _cont = 0;
    var _cont: Int = 0

    // Line 394: int _activeTab = 0;
    var _activeTab: Int = 0

    // MARK: - Initialization

    // Default constructor
    init() {
        // All properties have default values
    }

    // Line 396: ContainerTabInfo(int cont, int activeTab)
    init(cont: Int, activeTab: Int) {
        self._cont = cont
        self._activeTab = activeTab
    }
}

// MARK: - DockingManagerData Struct (Translation of Parameters.h lines 401-431)

// Translation of struct DockingManagerData final from Parameters.h lines 401-431
struct DockingManagerData: Codable {
    // Line 403: int _leftWidth = DMD_PANEL_WH_DEFAULT;
    var _leftWidth: Int = DMD_PANEL_WH_DEFAULT

    // Line 404: int _rightWidth = DMD_PANEL_WH_DEFAULT;
    var _rightWidth: Int = DMD_PANEL_WH_DEFAULT

    // Line 405: int _topHeight = DMD_PANEL_WH_DEFAULT;
    var _topHeight: Int = DMD_PANEL_WH_DEFAULT

    // Line 406: int _bottomHeight = DMD_PANEL_WH_DEFAULT;
    var _bottomHeight: Int = DMD_PANEL_WH_DEFAULT

    // Line 408-409: will be updated at runtime (Notepad_plus::init & DockingManager::runProc DMM_MOVE_SPLITTER)
    // LONG _minDockedPanelVisibility = HIGH_CAPTION;
    // LONG is a Windows 32-bit integer type (equivalent to Int32)
    var _minDockedPanelVisibility: Int = HIGH_CAPTION

    // Line 410: SIZE _minFloatingPanelSize = { (HIGH_CAPTION) * 6, HIGH_CAPTION };
    // Windows SIZE structure: {cx (width), cy (height)}
    var _minFloatingPanelSize: CGSize = CGSize(width: HIGH_CAPTION * 6, height: HIGH_CAPTION)

    // Line 412: std::vector<FloatingWindowInfo> _floatingWindowInfo;
    var _floatingWindowInfo: [FloatingWindowInfo] = []

    // Line 413: std::vector<PluginDlgDockingInfo> _pluginDockInfo;
    var _pluginDockInfo: [PluginDlgDockingInfo] = []

    // Line 414: std::vector<ContainerTabInfo> _containerTabInfo;
    var _containerTabInfo: [ContainerTabInfo] = []

    // MARK: - Methods (Translation of lines 416-430)

    // Line 416-430: bool getFloatingRCFrom(int floatCont, RECT& rc) const
    func getFloatingRCFrom(floatCont: Int, rc: inout CGRect) -> Bool {
        // C++ code iterates through _floatingWindowInfo to find matching _cont
        for i in 0..<_floatingWindowInfo.count {
            if _floatingWindowInfo[i]._cont == floatCont {
                // C++ copies RECT fields: left, top, right, bottom
                rc = _floatingWindowInfo[i]._pos
                return true
            }
        }
        return false
    }

    // MARK: - Initialization

    init() {
        // All properties have default values
    }
}
