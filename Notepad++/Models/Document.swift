//
//  Document.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI
import CoreGraphics
import AppKit

@MainActor
class Document: ObservableObject, Identifiable {
    let id = UUID()
    
    // CRITICAL FIX: Each document owns its own NSTextStorage
    // This is the Swift equivalent of Scintilla Document in Notepad++
    // Mirrors Buffer._doc from Buffer.h line 395
    let textStorage: NSTextStorage
    
    @Published var content: String {
        didSet {
            // Detect if content is being reset to original file content
            if oldValue.count > content.count && content == lastSavedContent {
                // Prevent the reset
                content = oldValue
            }
        }
    }
    @Published var fileURL: URL? // Renamed from filePath for consistency
    @Published var isModified: Bool = false
    @Published var fileName: String
    @Published var fileExtension: String?
    @Published var language: LanguageDefinition?
    @Published var foldingState = FoldingState()
    @Published var encoding: FileEncoding = .utf8
    @Published var eolType: EOLType = .unix
    @Published var caretPosition: Int = 0  // Caret position in the text
    @Published var scrollPosition: CGPoint = .zero  // Scroll position
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)  // Selected text range
    
    // Each document has its own syntax highlighter instance
    // This mirrors Notepad++ where each Buffer has its own lexer state
    let syntaxHighlighter = SyntaxHighlighter()
    
    // Document view state (preserved across tab switches)
    @Published var documentScrollPosition: NSPoint = .zero
    @Published var documentSelectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var documentVisibleRect: NSRect = .zero
    
    private var lastSavedContent: String
    
    init(content: String = "", filePath: URL? = nil) {
        // Initialize NSTextStorage with content
        self.textStorage = NSTextStorage(string: content)
        self.content = content
        self.fileURL = filePath
        self.lastSavedContent = content
        
        if let path = filePath {
            self.fileName = path.lastPathComponent
            self.fileExtension = path.pathExtension.isEmpty ? nil : path.pathExtension
            // Use the new LanguageManager to detect language
            if let nppLanguage = LanguageManager.shared.detectLanguage(for: path.lastPathComponent) {
                self.language = nppLanguage.toLanguageDefinition()
                print("DEBUG Document init: Language detected for \(path.lastPathComponent): \(nppLanguage.name)")
            } else {
                // Try the old language manager as fallback
                if let oldLanguage = OldLanguageManager.shared.detectLanguage(for: path) {
                    self.language = oldLanguage
                    print("DEBUG Document init: Old language manager detected: \(oldLanguage.name)")
                } else {
                    self.language = nil
                    print("DEBUG Document init: NO LANGUAGE DETECTED for \(path.lastPathComponent)")
                }
            }
        } else {
            self.fileName = "Untitled"
            self.fileExtension = nil
            self.language = nil
        }
    }
    
    func updateContent(_ newContent: String) {
        // Guard against reverting to old content
        if isModified && newContent == lastSavedContent && content.count > newContent.count {
            return
        }
        content = newContent
        
        // Update NSTextStorage
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: newContent)
        textStorage.endEditing()
        
        isModified = (newContent != lastSavedContent)
        
        // Auto-detect language for new documents based on content
        if language == nil && fileURL == nil {
            detectLanguageFromContent()
        }
    }
    
    private func detectLanguageFromContent() {
        // Simple content-based language detection for common patterns
        let firstLine = content.split(separator: "\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
        
        if firstLine.starts(with: "import ") || firstLine.starts(with: "from ") || 
           firstLine.starts(with: "def ") || firstLine.starts(with: "class ") ||
           content.contains("print(") {
            // Python patterns
            if let pythonLang = LanguageManager.shared.detectLanguage(for: "temp.py") {
                self.language = pythonLang.toLanguageDefinition()
            }
        } else if firstLine.starts(with: "function ") || firstLine.starts(with: "const ") ||
                  firstLine.starts(with: "let ") || firstLine.starts(with: "var ") ||
                  content.contains("console.log(") {
            // JavaScript patterns
            if let jsLang = LanguageManager.shared.detectLanguage(for: "temp.js") {
                self.language = jsLang.toLanguageDefinition()
            }
        } else if firstLine.starts(with: "<!DOCTYPE") || firstLine.starts(with: "<html") {
            // HTML
            if let htmlLang = LanguageManager.shared.detectLanguage(for: "temp.html") {
                self.language = htmlLang.toLanguageDefinition()
            }
        }
    }
    
    func markAsSaved() {
        lastSavedContent = content
        isModified = false
    }
    
    func save() async throws {
        guard let url = fileURL else {
            throw DocumentError.noFilePath
        }
        
        // Create backup before saving
        BackupManager.shared.createBackup(for: self)
        
        let contentToSave = content
        let encodingToUse = encoding
        try await Task {
            try await MainActor.run {
                try EncodingManager.shared.writeFile(content: contentToSave, to: url, encoding: encodingToUse)
            }
        }.value
        markAsSaved()
    }
    
    func saveAs(to url: URL) async throws {
        fileURL = url
        fileName = url.lastPathComponent
        fileExtension = url.pathExtension.isEmpty ? nil : url.pathExtension
        // Use the new LanguageManager to detect language
        if let nppLanguage = LanguageManager.shared.detectLanguage(for: url.lastPathComponent) {
            language = nppLanguage.toLanguageDefinition()
        } else {
            // Try the old language manager as fallback
            if let oldLanguage = OldLanguageManager.shared.detectLanguage(for: url) {
                language = oldLanguage
            } else {
                language = nil
            }
        }
        try await save()
    }
    
    static func open(from url: URL) async throws -> Document {
        // Read file with encoding and EOL detection on background thread
        let (content, detectedEncoding, detectedEOL) = try await Task.detached {
            // Encoding detection must happen on main thread
            let result = try await MainActor.run {
                let settings = AppSettings.shared
                return try EncodingManager.shared.readFile(at: url, openAnsiAsUtf8: settings.openAnsiAsUtf8)
            }
            return result
        }.value
        
        // Create Document on main thread
        return await MainActor.run {
            let doc = Document(content: content, filePath: url)
            doc.encoding = detectedEncoding
            doc.eolType = detectedEOL
            return doc
        }
    }
    
    // Convert EOL in current document
    func convertEOL(to newEOL: EOLType) {
        let convertedContent = EncodingManager.shared.convertEOL(in: content, to: newEOL)
        content = convertedContent
        eolType = newEOL
        isModified = true
    }
    
    // MARK: - Document State Management (Port of ScintillaEditView::saveCurrentPos)
    
    /// Save the current state from the text view (before switching tabs)
    /// Port of ScintillaEditView::saveCurrentPos() from ScintillaEditView.cpp
    func saveState(from textView: NSTextView) {
        documentSelectedRange = textView.selectedRange()
        if let scrollView = textView.enclosingScrollView {
            documentScrollPosition = scrollView.contentView.bounds.origin
        }
        documentVisibleRect = textView.visibleRect
        
        // Update content from text view
        let currentContent = textView.string
        if currentContent != content {
            updateContent(currentContent)
        }
    }
    
    /// Restore the saved state to the text view (after switching to this tab)
    /// Port of ScintillaEditView::restoreCurrentPos() from ScintillaEditView.cpp
    func restoreState(to textView: NSTextView) {
        // Restore selection
        if documentSelectedRange.location <= textView.string.count {
            textView.setSelectedRange(documentSelectedRange)
        }
        
        // Restore scroll position
        if let scrollView = textView.enclosingScrollView {
            scrollView.contentView.scroll(to: documentScrollPosition)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
    
    /// Activate this document in the text view (port of ScintillaEditView::activateBuffer)
    /// This is the CRITICAL method that performs the document swap
    func activate(in textView: NSTextView, restorePosition: Bool = false) {
        // Port of SCI_SETDOCPOINTER - swap the entire text storage
        if let layoutManager = textView.layoutManager {
            // Remove text view from old text storage
            textView.textStorage?.removeLayoutManager(layoutManager)
            
            // Attach to new text storage
            self.textStorage.addLayoutManager(layoutManager)
        }
        
        // Apply language-specific settings (port of defineDocType)
        if let language = self.language {
            applySyntaxHighlighting(to: textView, language: language)
        }
        
        // Only restore saved state when explicitly requested (e.g., when switching tabs)
        if restorePosition {
            restoreState(to: textView)
        }
    }
    
    private func applySyntaxHighlighting(to textView: NSTextView, language: LanguageDefinition) {
        // This will be handled by the syntax highlighter
        // For now, just ensure the text storage has the correct attributes
        if AppSettings.shared.syntaxHighlighting {
            // Apply syntax highlighting to our text storage
            syntaxHighlighter.highlight(textStorage: textStorage, language: language)
        }
    }
}

enum DocumentError: LocalizedError {
    case noFilePath
    case saveError(String)
    case openError(String)
    
    var errorDescription: String? {
        switch self {
        case .noFilePath:
            return "No file path specified"
        case .saveError(let message):
            return "Save error: \(message)"
        case .openError(let message):
            return "Open error: \(message)"
        }
    }
}