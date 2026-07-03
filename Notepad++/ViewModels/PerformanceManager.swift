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

            // Undo levels are capped on each Document's own UndoManager (see
            // Document.undoManager and makeNSView). textView.undoManager is nil here
            // (called pre-window) so setting it was a no-op (F04).
            textView.allowsUndo = true

        } else {
            // Restore normal features
            textView.isAutomaticSpellingCorrectionEnabled = false // Keep disabled as per Notepad++ style
            textView.isAutomaticDataDetectionEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isContinuousSpellCheckingEnabled = false
            textView.isGrammarCheckingEnabled = false

            if let layoutManager = textView.layoutManager {
                // F24: keep non-contiguous (lazy) layout enabled for ALL files, not just
                // large ones. With it disabled TextKit laid out the entire document up
                // front, so opening a large file forced O(document) glyph layout on the
                // main thread. Non-contiguous layout lets TextKit lay out only the visible
                // rect on demand, the TextKit equivalent of Scintilla styling/laying out
                // only the visible window (Editor.cxx StyleToPositionInView clamps work to
                // the visible area).
                layoutManager.allowsNonContiguousLayout = true
                // hasNonContiguousLayout is read-only
            }
            // Undo levels are capped on each Document's own UndoManager (see F04 note above).
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

// Document.isLargeFile and Document.getOptimizedSettings now live on Document proper
// (Models/Document.swift): isLargeFile returns a value computed once at open/init instead
// of recomputing content.utf8.count per access, and getOptimizedSettings caches its result
// so the render path never stats the file (F13).