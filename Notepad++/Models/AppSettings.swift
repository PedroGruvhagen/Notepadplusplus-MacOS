//
//  AppSettings.swift
//  Notepad++
//
//  DIRECT TRANSLATION of Parameters.h structures
//  Original location: PowerEditor/src/Parameters.h
//

import Foundation
import SwiftUI

// Translation of: struct LargeFileRestriction final
// Original location: Parameters.h lines 835-848
struct LargeFileRestriction: Codable {
    // Line 837: int64_t _largeFileSizeDefInByte = NPP_STYLING_FILESIZE_LIMIT_DEFAULT;
    var _largeFileSizeDefInByte: Int64 = 209715200 // 200MB in bytes (NPP_STYLING_FILESIZE_LIMIT_DEFAULT)

    // Line 838: bool _isEnabled = true;
    var _isEnabled: Bool = true

    // Line 840: bool _deactivateWordWrap = true;
    var _deactivateWordWrap: Bool = true

    // Line 842: bool _allowBraceMatch = false;
    var _allowBraceMatch: Bool = false

    // Line 843: bool _allowAutoCompletion = false;
    var _allowAutoCompletion: Bool = false

    // Line 844: bool _allowSmartHilite = false;
    var _allowSmartHilite: Bool = false

    // Line 845: bool _allowClickableLink = false;
    var _allowClickableLink: Bool = false

    // Line 847: bool _suppress2GBWarning = false;
    var _suppress2GBWarning: Bool = false

    // Convenience computed properties for UI (not in C++ original)
    var fileSizeMB: Int {
        get { Int(_largeFileSizeDefInByte / (1024 * 1024)) }
        set { _largeFileSizeDefInByte = Int64(newValue * 1024 * 1024) }
    }

    var isEnabled: Bool {
        get { _isEnabled }
        set { _isEnabled = newValue }
    }

    var allowBraceMatch: Bool {
        get { _allowBraceMatch }
        set { _allowBraceMatch = newValue }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Complete NppGUI Translation
    // The proper way would be to use NppGUI struct entirely
    // For now maintaining backwards compatibility with existing @AppStorage properties
    // TODO: Migrate completely to NppGUI structure

    // Reference to complete NppGUI configuration
    var nppGUI: NppGUI {
        get {
            if let data = defaults.data(forKey: "nppGUI"),
               let gui = try? JSONDecoder().decode(NppGUI.self, from: data) {
                return gui
            }
            return NppGUI() // Return default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "nppGUI")
            }
        }
    }

    // Reference to MatchedPairConf configuration
    var matchedPairConf: MatchedPairConf {
        get {
            if let data = defaults.data(forKey: "matchedPairConf"),
               let conf = try? JSONDecoder().decode(MatchedPairConf.self, from: data) {
                return conf
            }
            return MatchedPairConf() // Return default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "matchedPairConf")
            }
        }
    }

    // Reference to DarkModeConf configuration
    var darkModeConf: DarkModeConf {
        get {
            if let data = defaults.data(forKey: "darkModeConf"),
               let conf = try? JSONDecoder().decode(DarkModeConf.self, from: data) {
                return conf
            }
            return DarkModeConf() // Return default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "darkModeConf")
            }
        }
    }
    
    // MARK: - General Settings
    @AppStorage("showToolbar") var showToolbar: Bool = true
    @AppStorage("showStatusBar") var showStatusBar: Bool = true
    @AppStorage("showTabBar") var showTabBar: Bool = true
    @AppStorage("tabBarPosition") var tabBarPosition: TabPosition = .top
    @AppStorage("rememberLastSession") var rememberLastSession: Bool = true
    @AppStorage("checkForUpdates") var checkForUpdates: Bool = true
    @AppStorage("updateInterval") var updateIntervalDays: Int = 15
    @AppStorage("detectFileChanges") var detectFileChanges: Bool = true
    
    // MARK: - Editor Settings
    @AppStorage("fontName") var fontName: String = "Menlo"
    @AppStorage("fontSize") var fontSize: Double = 13.0
    @AppStorage("showLineNumbers") var showLineNumbers: Bool = true
    @AppStorage("showBookmarks") var showBookmarks: Bool = true
    @AppStorage("highlightCurrentLine") var highlightCurrentLine: Bool = true
    @AppStorage("currentLineColor") var currentLineColor: String = "#F0F0F0"
    @AppStorage("wordWrap") var wordWrap: Bool = false
    @AppStorage("showWhitespace") var showWhitespace: Bool = false
    @AppStorage("showEndOfLine") var showEndOfLine: Bool = false
    @AppStorage("showIndentGuides") var showIndentGuides: Bool = true
    @AppStorage("caretWidth") var caretWidth: Double = 1.0
    @AppStorage("caretBlinkRate") var caretBlinkRate: Double = 600.0
    @AppStorage("enableMultiSelection") var enableMultiSelection: Bool = true
    @AppStorage("scrollBeyondLastLine") var scrollBeyondLastLine: Bool = false
    @AppStorage("codeFolding") var codeFolding: Bool = true
    
    // MARK: - Tab Settings
    @AppStorage("tabSize") var tabSize: Int = 4
    @AppStorage("replaceTabsBySpaces") var replaceTabsBySpaces: Bool = false
    @AppStorage("maintainIndent") var maintainIndent: Bool = false  // DISABLED - causes problems
    @AppStorage("autoIndent") var autoIndent: Bool = false  // DISABLED - causes problems
    @AppStorage("smartIndent") var smartIndent: Bool = false  // DISABLED - causes problems
    
    // MARK: - Appearance Settings
    @AppStorage("theme") var theme: String = "Default"
    @AppStorage("enableDarkMode") var enableDarkMode: Bool = false
    @AppStorage("syntaxHighlighting") var syntaxHighlighting: Bool = true
    @AppStorage("matchBraces") var matchBraces: Bool = true
    @AppStorage("highlightMatchingTags") var highlightMatchingTags: Bool = true
    
    // MARK: - New Document Settings
    @AppStorage("defaultEncoding") var defaultEncoding: String = "UTF-8"
    @AppStorage("defaultLineEnding") var defaultLineEnding: LineEnding = .unix
    @AppStorage("defaultLanguage") var defaultLanguage: String = "Plain Text"
    @AppStorage("openAnsiAsUtf8") var openAnsiAsUtf8: Bool = true
    
    // MARK: - Backup/Auto-Save Settings
    @AppStorage("enableBackup") var enableBackup: Bool = false
    @AppStorage("backupMode") var backupMode: BackupMode = .simple
    @AppStorage("backupDirectory") var backupDirectory: String = ""
    @AppStorage("enableAutoSave") var enableAutoSave: Bool = false
    @AppStorage("autoSaveInterval") var autoSaveInterval: Int = 1 // minutes
    @AppStorage("enableSessionSnapshot") var enableSessionSnapshot: Bool = true
    @AppStorage("snapshotInterval") var snapshotInterval: Int = 7 // seconds
    
    // MARK: - Auto-Completion Settings
    @AppStorage("enableAutoCompletion") var enableAutoCompletion: Bool = false  // Default: false (user can enable in settings)
    @AppStorage("autoCompletionMinChars") var autoCompletionMinChars: Int = 1  // Matches C++ default (line 192 in NppGUI.swift)
    @AppStorage("showFunctionParameters") var showFunctionParameters: Bool = false
    @AppStorage("autoCompletionIgnoreNumbers") var autoCompletionIgnoreNumbers: Bool = true
    @AppStorage("autoInsertParentheses") var autoInsertParentheses: Bool = false
    @AppStorage("autoInsertBrackets") var autoInsertBrackets: Bool = false
    @AppStorage("autoInsertQuotes") var autoInsertQuotes: Bool = false
    
    // MARK: - Search Settings
    @AppStorage("searchMatchCase") var searchMatchCase: Bool = false
    @AppStorage("searchWholeWord") var searchWholeWord: Bool = false
    @AppStorage("searchWrapAround") var searchWrapAround: Bool = true
    @AppStorage("searchUseRegex") var searchUseRegex: Bool = false
    @AppStorage("smartHighlighting") var smartHighlighting: Bool = true
    @AppStorage("smartHighlightMatchCase") var smartHighlightMatchCase: Bool = false
    @AppStorage("smartHighlightWholeWord") var smartHighlightWholeWord: Bool = true
    
    // MARK: - Recent Files Settings
    @AppStorage("maxRecentFiles") var maxRecentFiles: Int = 10
    @AppStorage("showRecentFilesInSubmenu") var showRecentFilesInSubmenu: Bool = false
    
    // MARK: - Performance Settings (Translation of LargeFileRestriction from Parameters.h line 1007)
    // This is stored as a single JSON object to match original NppGUI._largeFileRestriction structure
    var largeFileRestriction: LargeFileRestriction {
        get {
            if let data = defaults.data(forKey: "largeFileRestriction"),
               let restriction = try? JSONDecoder().decode(LargeFileRestriction.self, from: data) {
                return restriction
            }
            return LargeFileRestriction() // Return default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "largeFileRestriction")
                objectWillChange.send()
            }
        }
    }
    
    // Legacy compatibility - will be removed
    @AppStorage("largeFileSize") var largeFileSize: Int = 200 // MB
    @AppStorage("disableHighlightingForLargeFiles") var disableHighlightingForLargeFiles: Bool = true
    @AppStorage("disableAutoCompletionForLargeFiles") var disableAutoCompletionForLargeFiles: Bool = true
    
    // MARK: - Enums
    enum TabPosition: String, CaseIterable {
        case top = "Top"
        case bottom = "Bottom"
    }
    
    enum LineEnding: String, CaseIterable {
        case windows = "Windows (CR LF)"
        case unix = "Unix (LF)"
        case mac = "Mac (CR)"
    }
    
    enum BackupMode: String, CaseIterable {
        case none = "None"
        case simple = "Simple"
        case verbose = "Verbose"
    }
    
    // MARK: - Methods
    func resetToDefaults() {
        // General
        showToolbar = true
        showStatusBar = true
        showTabBar = true
        tabBarPosition = .top
        rememberLastSession = true
        checkForUpdates = true
        updateIntervalDays = 15
        
        // Editor
        fontName = "Menlo"
        fontSize = 13.0
        showLineNumbers = true
        showBookmarks = true
        highlightCurrentLine = true
        wordWrap = false
        showWhitespace = false
        showEndOfLine = false
        showIndentGuides = true
        
        // Tabs
        tabSize = 4
        replaceTabsBySpaces = false
        maintainIndent = false  // DISABLED
        autoIndent = false  // DISABLED
        
        // Appearance
        theme = "Default"
        enableDarkMode = false
        syntaxHighlighting = true
        
        // New Document
        defaultEncoding = "UTF-8"
        defaultLineEnding = .unix
        defaultLanguage = "Plain Text"
        
        // Backup
        enableBackup = false
        enableAutoSave = false
        autoSaveInterval = 1
        
        // Auto-completion
        enableAutoCompletion = false  // DISABLED by default
        autoCompletionMinChars = 3
        showFunctionParameters = false
        
        // Search
        searchMatchCase = false
        searchWholeWord = false
        searchWrapAround = true
        searchUseRegex = false
        
        // Recent Files
        maxRecentFiles = 10
        showRecentFilesInSubmenu = false
        
        // Performance
        largeFileSize = 200
        disableHighlightingForLargeFiles = true
    }
    
    func exportSettings() -> Data? {
        // Export settings to JSON
        let settings = getAllSettings()
        return try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
    }
    
    func importSettings(from data: Data) -> Bool {
        // Import settings from JSON
        guard let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        // Apply settings
        for (key, value) in settings {
            defaults.set(value, forKey: key)
        }
        
        return true
    }
    
    private func getAllSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        
        // Get all AppStorage keys
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let label = child.label, label.starts(with: "_") {
                let key = String(label.dropFirst())
                settings[key] = defaults.object(forKey: key)
            }
        }
        
        return settings
    }
}