//
//  NppGUI.swift
//  Notepad++
//
//  LITERAL TRANSLATION of NppGUI struct
//  Source: PowerEditor/src/Parameters.h lines 850-1018
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Supporting Enums (from Parameters.h)

// Translation of enum AutoIndentMode from Parameters.h line 126
enum AutoIndentMode: Int, Codable {
    case autoIndent_none = 0      // Line 126
    case autoIndent_advanced = 1  // Line 126
    case autoIndent_basic = 2     // Line 126
}

// Translation of writeTechnologyEngine enum from Parameters.h
enum WriteTechnologyEngine: Int, Codable {
    case scintillaWriteTechnology = 0
    case directWriteTechnology = 1
}

// Translation of enum urlMode from Parameters.h lines 122-124
enum URLMode: Int, Codable {
    case urlDisable = 0          // Line 122
    case urlNoUnderLineFg = 1    // Line 122 (auto-increment)
    case urlUnderLineFg = 2      // Line 122 (auto-increment)
    case urlNoUnderLineBg = 3    // Line 122 (auto-increment)
    case urlUnderLineBg = 4      // Line 122 (auto-increment)
    // urlMin and urlMax are just aliases, not separate cases
}

// Translation of BackupFeature enum from Parameters.h
enum BackupFeature: Int, Codable {
    case bakNone = 0
    case bakSimple = 1
    case bakVerbose = 2
}

// Translation of OpenSaveDirSetting enum from Parameters.h
enum OpenSaveDirSetting: Int, Codable {
    case dirFollowCurrent = 0
    case dirLastUsed = 1
    case dirSpecified = 2
}

// Translation of MultiInstSetting enum from Parameters.h
enum MultiInstSetting: Int, Codable {
    case monoInst = 0
    case multiInstOnSession = 1
    case multiInst = 2
}

// MARK: - NppGUI struct (Translation of Parameters.h line 843-1008)

struct NppGUI: Codable {

    // Line 845: TbIconInfo _tbIconInfo
    // Simplified - we'll expand this when we translate TbIconInfo
    var _toolbarIconSet: Int = 0

    // Line 846-848: Toolbar and UI visibility
    var _toolbarShow: Bool = true
    var _statusBarShow: Bool = true
    var _menuBarShow: Bool = true

    // Line 850-851: Tab settings
    var _tabStatus: Int = 0  // Will need constants for TAB_DRAWTOPBAR etc
    var _forceTabbarVisible: Bool = false

    // Line 853-854: Splitter and user define dialog
    var _splitterPos: Bool = true  // POS_VERTICAL
    var _userDefineDlgStatus: Int = 0  // UDD_DOCKED

    // Line 856-858: Tab indentation
    var _tabSize: Int = 4
    var _tabReplacedBySpace: Bool = false
    var _backspaceUnindent: Bool = false

    // Line 860-862: Finder settings
    var _finderLinesAreCurrentlyWrapped: Bool = false
    var _finderPurgeBeforeEverySearch: Bool = false
    var _finderShowOnlyOneEntryPerFoundLine: Bool = true

    // Line 864: File auto-detection
    var _fileAutoDetection: Int = 1  // cdEnabledNew

    // Line 866: History files
    var _checkHistoryFiles: Bool = false

    // Line 868: Application position (RECT)
    var _appPos: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 700)

    // Line 870-871: Find window position and mode
    var _findWindowPos: CGRect = .zero
    var _findWindowLessMode: Bool = false

    // Line 873-877: Window state and session
    var _isMaximized: Bool = false
    var _isMinimizedToTray: Int = 0  // sta_none
    var _rememberLastSession: Bool = true
    var _keepSessionAbsentFileEntries: Bool = false
    var _isCmdlineNosessionActivated: Bool = false

    // Line 878-881: File operations
    var _detectEncoding: Bool = true
    var _saveAllConfirm: Bool = true
    var _setSaveDlgExtFiltToAllTypes: Bool = false
    var _doTaskList: Bool = true

    // Line 882-883: Indentation and smart highlighting
    var _maintainIndent: AutoIndentMode = .autoIndent_advanced
    var _enableSmartHilite: Bool = true

    // Line 885-888: Smart highlight options
    var _smartHiliteCaseSensitive: Bool = false
    var _smartHiliteWordOnly: Bool = true
    var _smartHiliteUseFindSettings: Bool = false
    var _smartHiliteOnAnotherView: Bool = false

    // Line 890-891: Mark all options
    var _markAllCaseSensitive: Bool = false
    var _markAllWordOnly: Bool = true

    // Line 893-896: Tag highlighting
    var _disableSmartHiliteTmp: Bool = false
    var _enableTagsMatchHilite: Bool = true
    var _enableTagAttrsHilite: Bool = true
    var _enableHiliteNonHTMLZone: Bool = false

    // Line 897-900: Style and delimiter settings
    var _styleMRU: Bool = true
    var _leftmostDelimiter: String = "("
    var _rightmostDelimiter: String = ")"
    var _delimiterSelectionOnEntireDocument: Bool = false

    // Line 901-912: Find/Replace dialog settings
    var _backSlashIsEscapeCharacterForSql: Bool = true
    var _fillFindFieldWithSelected: Bool = true
    var _fillFindFieldSelectCaret: Bool = true
    var _monospacedFontFindDlg: Bool = false
    var _findDlgAlwaysVisible: Bool = false
    var _confirmReplaceInAllOpenDocs: Bool = true
    var _replaceStopsWithoutFindingNext: Bool = false
    var _inSelectionAutocheckThreshold: Int = 1024  // FINDREPLACE_INSELECTION_THRESHOLD_DEFAULT
    var _fillDirFieldFromActiveDoc: Bool = false
    var _muteSounds: Bool = false
    var _enableFoldCmdToggable: Bool = false
    var _hideMenuRightShortcuts: Bool = false

    // Line 913-917: Text rendering and word characters
    var _writeTechnologyEngine: WriteTechnologyEngine = .directWriteTechnology
    var _isWordCharDefault: Bool = true
    var _customWordChars: String = ""
    var _styleURL: URLMode = .urlUnderLineFg
    var _uriSchemes: String = "svn:// cvs:// git:// imap:// irc:// irc6:// ircs:// ldap:// ldaps:// news: telnet:// gopher:// ssh:// sftp:// smb:// skype: snmp:// spotify: steam:// sms: slack:// chrome:// bitcoin:"

    // Line 918: New document default settings
    var _newDocDefaultSettings: NewDocDefaultSettings = NewDocDefaultSettings()

    // Line 920-921: Date/time format
    var _dateTimeFormat: String = "yyyy-MM-dd HH:mm:ss"
    var _dateTimeReverseDefaultOrder: Bool = false

    // Line 925-926: Language menu
    // var _excludedLangList: [LangMenuItem]  // Will translate separately
    var _isLangMenuCompact: Bool = true

    // Line 928-931: Print and backup settings
    var _printSettings: PrintSettings = PrintSettings()
    var _backup: BackupFeature = .bakNone
    var _useDir: Bool = false
    var _backupDir: String = ""

    // Line 932-933: Docking and global override
    // var _dockingData: DockingManagerData  // Complex - will translate separately
    // var _globalOverride: GlobalOverride  // Will translate separately

    // Line 934-941: Auto-completion settings
    enum AutocStatus: Int, Codable {
        case autocNone = 0
        case autocFunc = 1
        case autocWord = 2
        case autocBoth = 3
    }

    var _autocStatus: AutocStatus = .autocBoth
    var _autocFromLen: Int = 1
    var _autocIgnoreNumbers: Bool = true
    var _autocInsertSelectedUseENTER: Bool = true
    var _autocInsertSelectedUseTAB: Bool = true
    var _autocBrief: Bool = false
    var _funcParams: Bool = true

    // Line 942: Matched pair configuration
    // var _matchedPairConf: MatchedPairConf  // Will translate separately

    // Line 944-945: Session and workspace extensions
    var _definedSessionExt: String = ""
    var _definedWorkspaceExt: String = ""

    // Line 948: Command line interpreter
    var _commandLineInterpreter: String = "/bin/sh"  // CMD_INTERPRETER for macOS

    // Line 950-958: Auto-update options
    enum AutoUpdateMode: Int, Codable {
        case autoupdateDisabled = 0
        case autoupdateOnStartup = 1
        case autoupdateOnExit = 2
    }

    struct AutoUpdateOptions: Codable {
        var _doAutoUpdate: AutoUpdateMode = .autoupdateOnStartup
        var _intervalDays: Int = 15
        var _nextUpdateDate: Date = Date()
    }

    var _autoUpdateOpt: AutoUpdateOptions = AutoUpdateOptions()

    // Line 960-962: Updater and caret settings
    var _doesExistUpdater: Bool = false
    var _caretBlinkRate: Int = 600
    var _caretWidth: Int = 1

    // Line 964: Short titlebar
    var _shortTitlebar: Bool = false

    // Line 966-970: Open/Save directory settings
    var _openSaveDir: OpenSaveDirSetting = .dirFollowCurrent
    var _defaultDir: String = ""
    var _defaultDirExp: String = ""
    var _lastUsedDir: String = ""

    // Line 972-973: Theme and multi-instance
    var _themeName: String = ""
    var _multiInstSetting: MultiInstSetting = .monoInst

    // Line 974-986: Panel keep state settings
    var _clipboardHistoryPanelKeepState: Bool = false
    var _docListKeepState: Bool = false
    var _charPanelKeepState: Bool = false
    var _fileBrowserKeepState: Bool = false
    var _projectPanelKeepState: Bool = false
    var _docMapKeepState: Bool = false
    var _funcListKeepState: Bool = false
    var _pluginPanelKeepState: Bool = false

    // Line 982-986: File switcher settings
    var _fileSwitcherWithoutExtColumn: Bool = false
    var _fileSwitcherExtWidth: Int = 50
    var _fileSwitcherWithoutPathColumn: Bool = true
    var _fileSwitcherPathWidth: Int = 50
    var _fileSwitcherDisableListViewGroups: Bool = false

    // Line 987-990: Snapshot mode
    var _isSnapshotMode: Bool = true
    var _snapshotBackupTiming: Int = 7000  // milliseconds
    var _cloudPath: String = ""  // never read/written from/to config.xml
    var _availableClouds: UInt8 = 0  // never read/written from/to config.xml

    // Line 993-995: Search engine settings
    enum SearchEngineChoice: Int, Codable {
        case seCustom = 0
        case seDuckDuckGo = 1
        case seGoogle = 2
        case seBing = 3
        case seYahoo = 4
        case seStackoverflow = 5
    }

    var _searchEngineChoice: SearchEngineChoice = .seGoogle
    var _searchEngineCustom: String = ""

    // Line 997: Folder dropped behavior
    var _isFolderDroppedOpenFiles: Bool = false

    // Line 999-1000: Document peek settings
    var _isDocPeekOnTab: Bool = false
    var _isDocPeekOnMap: Bool = false

    // Line 1003: Function list sorting
    var _shouldSortFunctionList: Bool = false

    // Line 1005: Dark mode configuration
    // var _darkmode: DarkModeConf  // Will translate separately

    // Line 1007: Large file restriction
    // var _largeFileRestriction: LargeFileRestriction  // Already translated in AppSettings.swift

    // MARK: - Methods (Translation of line 923-924)

    // Line 923: void setTabReplacedBySpace(bool b)
    mutating func setTabReplacedBySpace(_ b: Bool) {
        _tabReplacedBySpace = b
    }

    // Line 987: bool isSnapshotMode() const
    func isSnapshotMode() -> Bool {
        return _isSnapshotMode && _rememberLastSession && !_isCmdlineNosessionActivated
    }

    // MARK: - Initialization

    init() {
        // All properties have default values
    }
}
