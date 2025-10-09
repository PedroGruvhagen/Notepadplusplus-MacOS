//
//  SettingsManager.swift
//  Notepad++
//
//  Manages settings and provides interface for preferences window
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings = AppSettings.shared
    @Published var isShowingSettings = false
    @Published var selectedTab: SettingsTab = .general
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case editing = "Editing"
        case appearance = "Appearance"
        case tabsIndentation = "Tabs & Indentation"
        case newDocument = "New Document"
        case backup = "Backup/Auto-Save"
        case autoCompletion = "Auto-Completion"
        case search = "Search"
        case performance = "Performance"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .editing: return "pencil"
            case .appearance: return "paintbrush"
            case .tabsIndentation: return "increase.indent"
            case .newDocument: return "doc.badge.plus"
            case .backup: return "clock.arrow.circlepath"
            case .autoCompletion: return "text.cursor"
            case .search: return "magnifyingglass"
            case .performance: return "speedometer"
            }
        }
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for settings changes and apply them
        settings.objectWillChange
            .sink { [weak self] _ in
                self?.applySettings()
            }
            .store(in: &cancellables)
    }
    
    func showSettings(tab: SettingsTab? = nil) {
        if let tab = tab {
            selectedTab = tab
        }
        isShowingSettings = true
    }
    
    func applySettings() {
        // This will be called when settings change
        // Other parts of the app can observe these changes
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
    
    func resetSettings(for tab: SettingsTab) {
        switch tab {
        case .general:
            resetGeneralSettings()
        case .editing:
            resetEditorSettings()
        case .appearance:
            resetAppearanceSettings()
        case .tabsIndentation:
            resetTabSettings()
        case .newDocument:
            resetNewDocumentSettings()
        case .backup:
            resetBackupSettings()
        case .autoCompletion:
            resetAutoCompletionSettings()
        case .search:
            resetSearchSettings()
        case .performance:
            resetPerformanceSettings()
        }
    }
    
    private func resetGeneralSettings() {
        settings.showToolbar = true
        settings.showStatusBar = true
        settings.showTabBar = true
        settings.tabBarPosition = .top
        settings.rememberLastSession = true
        settings.checkForUpdates = true
        settings.updateIntervalDays = 15
    }
    
    private func resetEditorSettings() {
        settings.fontName = "SF Mono"
        settings.fontSize = 13.0
        settings.showLineNumbers = true
        settings.showBookmarks = true
        settings.highlightCurrentLine = true
        settings.wordWrap = false
        settings.showWhitespace = false
        settings.showEndOfLine = false
        settings.showIndentGuides = true
        settings.caretWidth = 1.0
        settings.caretBlinkRate = 600.0
        settings.enableMultiSelection = true
        settings.scrollBeyondLastLine = false
    }
    
    private func resetAppearanceSettings() {
        settings.theme = "Default"
        settings.enableDarkMode = false
        settings.syntaxHighlighting = true
        settings.matchBraces = true
        settings.highlightMatchingTags = true
    }
    
    private func resetTabSettings() {
        settings.tabSize = 4
        settings.replaceTabsBySpaces = false
        settings.maintainIndent = true
        settings.autoIndent = true
        settings.smartIndent = false
    }
    
    private func resetNewDocumentSettings() {
        settings.defaultEncoding = "UTF-8"
        settings.defaultLineEnding = .unix
        settings.defaultLanguage = "Plain Text"
        settings.openAnsiAsUtf8 = true
    }
    
    private func resetBackupSettings() {
        settings.enableBackup = false
        settings.backupMode = .simple
        settings.backupDirectory = ""
        settings.enableAutoSave = false
        settings.autoSaveInterval = 1
        settings.enableSessionSnapshot = true
        settings.snapshotInterval = 7
    }
    
    private func resetAutoCompletionSettings() {
        settings.enableAutoCompletion = false  // Default: disabled (user can enable)
        settings.autoCompletionMinChars = 1    // Matches C++ default
        settings.showFunctionParameters = false
        settings.autoCompletionIgnoreNumbers = true  // Matches C++ default
        settings.autoInsertParentheses = false
        settings.autoInsertBrackets = false
        settings.autoInsertQuotes = false
    }
    
    private func resetSearchSettings() {
        settings.searchMatchCase = false
        settings.searchWholeWord = false
        settings.searchWrapAround = true
        settings.searchUseRegex = false
        settings.smartHighlighting = true
        settings.smartHighlightMatchCase = false
        settings.smartHighlightWholeWord = true
    }
    
    private func resetPerformanceSettings() {
        settings.largeFileSize = 200
        settings.disableHighlightingForLargeFiles = true
        settings.disableAutoCompletionForLargeFiles = true
    }
    
    // MARK: - Font Management
    var availableFonts: [String] {
        let fontManager = NSFontManager.shared
        let fontFamilies = fontManager.availableFontFamilies
        
        // Filter for monospace fonts primarily
        let monospaceFonts = fontFamilies.filter { family in
            family.contains("Mono") || 
            family.contains("Code") || 
            family.contains("Courier") ||
            family == "Menlo" ||
            family == "Monaco" ||
            family == "SF Mono"
        }
        
        return monospaceFonts.sorted()
    }
    
    // MARK: - Theme Management
    var availableThemes: [String] {
        // TODO: Load from theme files
        return ["Default", "Dark", "Solarized Light", "Solarized Dark", "Monokai", "Dracula"]
    }
    
    // MARK: - Language Management
    var availableLanguages: [String] {
        // TODO: Load from language definitions
        return ["Plain Text", "Swift", "JavaScript", "Python", "Java", "C++", "HTML", "CSS", "JSON", "XML", "Markdown"]
    }
}