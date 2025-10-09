//
//  FeatureGates.swift
//  Notepad++
//
//  Central location to track which features are fully implemented
//  Settings for unimplemented features should be disabled in the UI
//

import Foundation

/// Tracks implementation status of features
/// Used to disable settings UI for features that aren't yet complete
struct FeatureGates {
    static let shared = FeatureGates()
    
    // MARK: - Fully Implemented Features
    
    /// These features are complete and their settings should be enabled
    let implementedFeatures = Set<String>([
        // General
        "showToolbar",
        "showStatusBar", 
        "showTabBar",
        "tabBarPosition",
        "detectFileChanges",
        
        // Editor
        "fontName",
        "fontSize",
        "wordWrap",
        "showLineNumbers",
        "syntaxHighlighting",
        "highlightCurrentLine",
        "currentLineColor",
        "matchBraces",
        "autoCloseBraces",
        "showWhitespace",
        "showEndOfLine",
        "showIndentGuides",
        "caretWidth",
        "scrollBeyondLastLine",
        
        // Tabs & Indentation
        "tabSize",
        "replaceTabsBySpaces",
        "maintainIndent",
        "autoIndent",
        
        // New Document
        "defaultLanguage",
        "defaultEncoding",
        "defaultLineEnding",
        "openAnsiAsUtf8",
        
        // Appearance
        "theme",
        "enableDarkMode",
        
        // Backup (Partially implemented)
        "enableBackup",
        "backupMode",
        "backupDirectory",
        "enableAutoSave",
        "autoSaveInterval",
        
        // File monitoring
        "detectFileChanges",

        // Auto-completion (FULLY IMPLEMENTED - translated from C++ AutoCompletion.cpp)
        "enableAutoCompletion",
        "autoCompletionMinChars",
        "showFunctionParameters",
        "autoCompletionIgnoreNumbers"
    ])
    
    // MARK: - Partially Implemented Features
    
    /// These features work but have limitations
    let partiallyImplementedFeatures = Set<String>([
        "rememberLastSession",  // Disabled in previous fix but setting exists
        "enableSessionSnapshot", // Disabled in previous fix but setting exists
        "snapshotInterval",     // Disabled in previous fix but setting exists
        "smartIndent",          // Basic implementation, not language-aware yet
        "largeFileThreshold",   // Used for warnings but not for disabling features
        "disableHighlightingThreshold" // Setting exists but highlighting not disabled
    ])
    
    // MARK: - Not Implemented Features
    
    /// These features are not implemented at all
    let notImplementedFeatures = Set<String>([
        // Updates
        "checkForUpdates",
        "updateIntervalDays",
        
        // Recent Files
        "maxRecentFiles",
        "showRecentFilesInSubmenu",

        // Auto-completion (advanced features not yet implemented)
        "autoCompletionMaxSuggestions",
        "autoCompleteOnEnter",
        "insertFunctionParameters",
        "wordBasedSuggestions",
        "caseInsensitive",

        // Search (advanced features)
        "searchHistorySize",
        "replaceHistorySize",
        
        // Editor (advanced features)
        "enableMultiSelection",
        "highlightAnotherView",
        
        // Language management
        "customLanguages"
    ])
    
    // MARK: - Helper Methods
    
    /// Check if a feature is fully implemented
    func isImplemented(_ feature: String) -> Bool {
        return implementedFeatures.contains(feature)
    }
    
    /// Check if a feature is partially implemented
    func isPartiallyImplemented(_ feature: String) -> Bool {
        return partiallyImplementedFeatures.contains(feature)
    }
    
    /// Check if a feature is not implemented
    func isNotImplemented(_ feature: String) -> Bool {
        return notImplementedFeatures.contains(feature)
    }
    
    /// Get implementation status for a feature
    func getStatus(_ feature: String) -> ImplementationStatus {
        if isImplemented(feature) {
            return .implemented
        } else if isPartiallyImplemented(feature) {
            return .partial
        } else if isNotImplemented(feature) {
            return .notImplemented
        } else {
            // Unknown feature, assume implemented to avoid breaking existing functionality
            return .implemented
        }
    }
    
    enum ImplementationStatus {
        case implemented
        case partial
        case notImplemented
        
        var isEnabled: Bool {
            switch self {
            case .implemented:
                return true
            case .partial, .notImplemented:
                return false
            }
        }
        
        var helpText: String? {
            switch self {
            case .implemented:
                return nil
            case .partial:
                return "This feature is partially implemented"
            case .notImplemented:
                return "This feature is not yet implemented"
            }
        }
        
        var badgeText: String? {
            switch self {
            case .implemented:
                return nil
            case .partial:
                return "Partial"
            case .notImplemented:
                return "Coming Soon"
            }
        }
    }
}