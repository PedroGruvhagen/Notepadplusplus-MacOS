//
//  PerformanceManager.swift
//  Notepad++
//
//  Manages performance optimizations for large files
//

import Foundation
import AppKit

class PerformanceManager {
    static let shared = PerformanceManager()
    
    private init() {}
    
    /// Check if a file is considered "large" based on settings
    func isLargeFile(size: Int64) -> Bool {
        let settings = AppSettings.shared
        let sizeInMB = Double(size) / (1024 * 1024)
        return sizeInMB >= Double(settings.largeFileSize)
    }
    
    /// Check if a file is considered "large" based on its URL
    func isLargeFile(at url: URL) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return isLargeFile(size: fileSize)
            }
        } catch {
            print("Failed to get file size: \(error)")
        }
        return false
    }
    
    /// Get optimized settings for a document
    @MainActor
    func getOptimizedSettings(for document: Document) -> OptimizedSettings {
        let settings = AppSettings.shared
        
        // Check if document is large
        let isLarge: Bool
        if let url = document.fileURL {
            isLarge = isLargeFile(at: url)
        } else {
            // Check content size for unsaved documents
            let sizeInBytes = document.content.utf8.count
            isLarge = isLargeFile(size: Int64(sizeInBytes))
        }
        
        if isLarge {
            return OptimizedSettings(
                syntaxHighlighting: !settings.disableHighlightingForLargeFiles,
                autoCompletion: !settings.disableAutoCompletionForLargeFiles,
                codeFolding: false,
                smartHighlighting: false,
                bracketMatching: false,
                currentLineHighlight: false,
                showLineNumbers: true // Keep line numbers for navigation
            )
        } else {
            // Use normal settings
            return OptimizedSettings(
                syntaxHighlighting: settings.syntaxHighlighting,
                autoCompletion: settings.enableAutoCompletion,
                codeFolding: settings.codeFolding,
                smartHighlighting: settings.smartHighlighting,
                bracketMatching: settings.matchBraces,
                currentLineHighlight: settings.highlightCurrentLine,
                showLineNumbers: settings.showLineNumbers
            )
        }
    }
    
    /// Show warning when opening a large file
    func showLargeFileWarning(for url: URL, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Large File Detected"
        alert.informativeText = "This file is larger than \(AppSettings.shared.largeFileSize)MB. Some features may be disabled for better performance. Do you want to continue?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    /// Optimize text view for large content
    func optimizeTextView(_ textView: NSTextView, forLargeFile isLarge: Bool) {
        if isLarge {
            // Disable expensive features for large files
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isAutomaticDataDetectionEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false
            
            // Optimize layout
            if let layoutManager = textView.layoutManager {
                layoutManager.allowsNonContiguousLayout = true
                // hasNonContiguousLayout is read-only
            }
            
            // Reduce undo levels
            textView.allowsUndo = true
            textView.undoManager?.levelsOfUndo = 10 // Reduce from default
            
        } else {
            // Restore normal features
            textView.isAutomaticSpellingCorrectionEnabled = false // Keep disabled as per Notepad++ style
            textView.isAutomaticDataDetectionEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false
            
            if let layoutManager = textView.layoutManager {
                layoutManager.allowsNonContiguousLayout = false
                // hasNonContiguousLayout is read-only
            }
            
            textView.undoManager?.levelsOfUndo = 100 // Normal undo levels
        }
    }
}

struct OptimizedSettings {
    let syntaxHighlighting: Bool
    let autoCompletion: Bool
    let codeFolding: Bool
    let smartHighlighting: Bool
    let bracketMatching: Bool
    let currentLineHighlight: Bool
    let showLineNumbers: Bool
}

// Extension to Document to track if it's a large file
extension Document {
    @MainActor
    var isLargeFile: Bool {
        return PerformanceManager.shared.isLargeFile(size: Int64(content.utf8.count))
    }
    
    @MainActor
    func getOptimizedSettings() -> OptimizedSettings {
        return PerformanceManager.shared.getOptimizedSettings(for: self)
    }
}