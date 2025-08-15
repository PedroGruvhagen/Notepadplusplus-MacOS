//
//  AppSettings.swift
//  Notepad++
//
//  Settings model matching original Notepad++ preferences
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - General Settings
    @AppStorage("showToolbar") var showToolbar: Bool = true
    @AppStorage("showStatusBar") var showStatusBar: Bool = true
    @AppStorage("showTabBar") var showTabBar: Bool = true
    @AppStorage("tabBarPosition") var tabBarPosition: TabPosition = .top
    @AppStorage("rememberLastSession") var rememberLastSession: Bool = true
    @AppStorage("checkForUpdates") var checkForUpdates: Bool = true
    @AppStorage("updateInterval") var updateIntervalDays: Int = 15
    
    // MARK: - Editor Settings
    @AppStorage("fontName") var fontName: String = "SF Mono"
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
    @AppStorage("maintainIndent") var maintainIndent: Bool = true
    @AppStorage("autoIndent") var autoIndent: Bool = true
    @AppStorage("smartIndent") var smartIndent: Bool = false
    
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
    @AppStorage("enableAutoCompletion") var enableAutoCompletion: Bool = true
    @AppStorage("autoCompletionMinChars") var autoCompletionMinChars: Int = 1
    @AppStorage("showFunctionParameters") var showFunctionParameters: Bool = true
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
    
    // MARK: - Performance Settings
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
        fontName = "SF Mono"
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
        maintainIndent = true
        autoIndent = true
        
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
        enableAutoCompletion = true
        autoCompletionMinChars = 1
        showFunctionParameters = true
        
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