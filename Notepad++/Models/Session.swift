//
//  Session.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Session Management structures
//  Source: PowerEditor/src/Parameters.h lines 187-265
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Position Struct (Translation of Parameters.h lines 187-197)

// Translation of struct Position from Parameters.h lines 187-197
struct Position: Codable {
    // Line 189: intptr_t _firstVisibleLine = 0;
    var _firstVisibleLine: Int = 0

    // Line 190: intptr_t _startPos = 0;
    var _startPos: Int = 0

    // Line 191: intptr_t _endPos = 0;
    var _endPos: Int = 0

    // Line 192: intptr_t _xOffset = 0;
    var _xOffset: Int = 0

    // Line 193: intptr_t _selMode = 0;
    var _selMode: Int = 0

    // Line 194: intptr_t _scrollWidth = 1;
    var _scrollWidth: Int = 1

    // Line 195: intptr_t _offset = 0;
    var _offset: Int = 0

    // Line 196: intptr_t _wrapCount = 0;
    var _wrapCount: Int = 0

    // MARK: - Initialization

    init() {
        // All properties have default values
    }

    init(firstVisibleLine: Int, startPos: Int, endPos: Int, xOffset: Int, selMode: Int, scrollWidth: Int, offset: Int, wrapCount: Int) {
        self._firstVisibleLine = firstVisibleLine
        self._startPos = startPos
        self._endPos = endPos
        self._xOffset = xOffset
        self._selMode = selMode
        self._scrollWidth = scrollWidth
        self._offset = offset
        self._wrapCount = wrapCount
    }
}

// MARK: - MapPosition Struct (Translation of Parameters.h lines 200-220)

// Translation of struct MapPosition from Parameters.h lines 200-220
struct MapPosition: Codable {
    // Line 203: intptr_t _maxPeekLenInKB = 512; // 512 KB (private in C++)
    private var _maxPeekLenInKB: Int = 512

    // Line 205: intptr_t _firstVisibleDisplayLine = -1;
    var _firstVisibleDisplayLine: Int = -1

    // Line 207: intptr_t _firstVisibleDocLine = -1; // map
    var _firstVisibleDocLine: Int = -1

    // Line 208: intptr_t _lastVisibleDocLine = -1;  // map
    var _lastVisibleDocLine: Int = -1

    // Line 209: intptr_t _nbLine = -1;              // map
    var _nbLine: Int = -1

    // Line 210: intptr_t _higherPos = -1;           // map
    var _higherPos: Int = -1

    // Line 211: intptr_t _width = -1;
    var _width: Int = -1

    // Line 212: intptr_t _height = -1;
    var _height: Int = -1

    // Line 213: intptr_t _wrapIndentMode = -1;
    var _wrapIndentMode: Int = -1

    // Line 215: intptr_t _KByteInDoc = _maxPeekLenInKB;
    var _KByteInDoc: Int = 512

    // Line 217: bool _isWrap = false;
    var _isWrap: Bool = false

    // MARK: - Methods (Translation of lines 218-219)

    // Line 218: bool isValid() const { return (_firstVisibleDisplayLine != -1); };
    func isValid() -> Bool {
        return _firstVisibleDisplayLine != -1
    }

    // Line 219: bool canScroll() const { return (_KByteInDoc < _maxPeekLenInKB); };
    func canScroll() -> Bool {
        return _KByteInDoc < _maxPeekLenInKB
    }

    // MARK: - Initialization

    init() {
        // All properties have default values
    }
}

// MARK: - FileTime Struct (Translation of Windows FILETIME)

// Translation of Windows FILETIME structure
// FILETIME is a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601 (UTC)
// Stored as two 32-bit values (dwLowDateTime, dwHighDateTime) in Windows
struct FileTime: Codable {
    var dwLowDateTime: UInt32 = 0
    var dwHighDateTime: UInt32 = 0

    // Convert to/from Date for macOS
    var date: Date? {
        let ticks = UInt64(dwHighDateTime) << 32 | UInt64(dwLowDateTime)
        if ticks == 0 { return nil }

        // Windows epoch: January 1, 1601
        // Unix epoch: January 1, 1970
        // Difference: 11644473600 seconds = 116444736000000000 * 100ns
        let windowsEpochDifference: UInt64 = 116444736000000000

        // Convert 100-nanosecond intervals to seconds
        let unixTicks = ticks - windowsEpochDifference
        let seconds = Double(unixTicks) / 10000000.0

        return Date(timeIntervalSince1970: seconds)
    }

    init() {}

    init(date: Date) {
        let windowsEpochDifference: UInt64 = 116444736000000000
        let seconds = date.timeIntervalSince1970
        let ticks = UInt64(seconds * 10000000.0) + windowsEpochDifference

        self.dwLowDateTime = UInt32(ticks & 0xFFFFFFFF)
        self.dwHighDateTime = UInt32(ticks >> 32)
    }
}

// MARK: - SessionFileInfo Struct (Translation of Parameters.h lines 223-250)

// Translation of struct sessionFileInfo from Parameters.h lines 223-250
// Inherits from Position in C++, Swift uses composition
struct SessionFileInfo: Codable {
    // Inherited from Position (C++: public Position)
    var position: Position = Position()

    // Line 235: std::wstring _fileName;
    var _fileName: String = ""

    // Line 236: std::wstring _langName;
    var _langName: String = ""

    // Line 237: std::vector<size_t> _marks;
    var _marks: [Int] = []

    // Line 238: std::vector<size_t> _foldStates;
    var _foldStates: [Int] = []

    // Line 239: int _encoding = -1;
    var _encoding: Int = -1

    // Line 240: bool _isUserReadOnly = false;
    var _isUserReadOnly: Bool = false

    // Line 241: bool _isMonitoring = false;
    var _isMonitoring: Bool = false

    // Line 242: int _individualTabColour = -1;
    var _individualTabColour: Int = -1

    // Line 243: bool _isRTL = false;
    var _isRTL: Bool = false

    // Line 244: bool _isPinned = false;
    var _isPinned: Bool = false

    // Line 245: bool _isUntitledTabRenamed = false;
    var _isUntitledTabRenamed: Bool = false

    // Line 246: std::wstring _backupFilePath;
    var _backupFilePath: String = ""

    // Line 247: FILETIME _originalFileLastModifTimestamp {};
    var _originalFileLastModifTimestamp: FileTime = FileTime()

    // Line 249: MapPosition _mapPos;
    var _mapPos: MapPosition = MapPosition()

    // MARK: - Initialization

    // Default constructor (Line 233)
    init(fileName: String) {
        self._fileName = fileName
    }

    // Full constructor (Lines 225-231)
    // C++ signature: sessionFileInfo(const wchar_t* fn, const wchar_t *ln, int encoding, bool userReadOnly, bool isPinned, bool isUntitleTabRenamed, const Position& pos, const wchar_t *backupFilePath, FILETIME originalFileLastModifTimestamp, const MapPosition & mapPos)
    init(
        fileName: String?,
        langName: String?,
        encoding: Int,
        isUserReadOnly: Bool,
        isPinned: Bool,
        isUntitledTabRenamed: Bool,
        position: Position,
        backupFilePath: String?,
        originalFileLastModifTimestamp: FileTime,
        mapPos: MapPosition
    ) {
        // Initialize inherited Position first (C++: Position(pos))
        self.position = position

        // Initialize members from initializer list (C++ lines 226)
        self._encoding = encoding
        self._isUserReadOnly = isUserReadOnly
        self._isPinned = isPinned
        self._isUntitledTabRenamed = isUntitledTabRenamed
        self._originalFileLastModifTimestamp = originalFileLastModifTimestamp
        self._mapPos = mapPos

        // Conditional initialization from constructor body (C++ lines 228-230)
        // Line 228: if (fn) _fileName = fn;
        if let fn = fileName {
            self._fileName = fn
        }

        // Line 229: if (ln) _langName = ln;
        if let ln = langName {
            self._langName = ln
        }

        // Line 230: if (backupFilePath) _backupFilePath = backupFilePath;
        if let bp = backupFilePath {
            self._backupFilePath = bp
        }
    }
}

// MARK: - Session Struct (Translation of Parameters.h lines 253-265)

// Translation of struct Session from Parameters.h lines 253-265
struct Session: Codable {
    // Line 257: size_t _activeView = 0;
    var _activeView: Int = 0

    // Line 258: size_t _activeMainIndex = 0;
    var _activeMainIndex: Int = 0

    // Line 259: size_t _activeSubIndex = 0;
    var _activeSubIndex: Int = 0

    // Line 260: bool _includeFileBrowser = false;
    var _includeFileBrowser: Bool = false

    // Line 261: std::wstring _fileBrowserSelectedItem;
    var _fileBrowserSelectedItem: String = ""

    // Line 262: std::vector<sessionFileInfo> _mainViewFiles;
    var _mainViewFiles: [SessionFileInfo] = []

    // Line 263: std::vector<sessionFileInfo> _subViewFiles;
    var _subViewFiles: [SessionFileInfo] = []

    // Line 264: std::vector<std::wstring> _fileBrowserRoots;
    var _fileBrowserRoots: [String] = []

    // MARK: - Methods (Translation of lines 255-256)

    // Line 255: size_t nbMainFiles() const {return _mainViewFiles.size();};
    func nbMainFiles() -> Int {
        return _mainViewFiles.count
    }

    // Line 256: size_t nbSubFiles() const {return _subViewFiles.size();};
    func nbSubFiles() -> Int {
        return _subViewFiles.count
    }

    // MARK: - Initialization

    init() {
        // All properties have default values
    }
}
