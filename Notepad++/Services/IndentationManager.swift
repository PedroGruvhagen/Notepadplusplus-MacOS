//
//  IndentationManager.swift
//  Notepad++
//
//  Handles auto-indentation similar to Notepad++
//  Based on maintainIndentation function from Notepad++ source
//

import Foundation
import AppKit

// AutoIndentMode is defined in NppGUI.swift as the literal C++ translation
// Using that definition instead of duplicating here

class IndentationManager {
    static let shared = IndentationManager()
    
    // This is called AFTER a character has been inserted, matching Notepad++ behavior
    func handleCharacterInserted(_ char: Character, in textView: NSTextView) {
        let settings = AppSettings.shared
        
        // Check if we should maintain indentation
        guard settings.maintainIndent || settings.autoIndent else { return }
        
        // Only handle newline characters
        guard char == "\n" || char == "\r" else { return }
        
        let text = textView.string as NSString
        let currentPos = textView.selectedRange().location
        
        // Get current line number
        var lineStart = 0
        var lineEnd = 0
        text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, 
                         for: NSRange(location: currentPos, length: 0))
        
        // If we just pressed Enter, we're now on a new line
        // Find the previous line (the one we came from)
        guard currentPos > 0 else { return }
        
        let prevPos = currentPos - 1
        var prevLineStart = 0
        var prevLineEnd = 0
        text.getLineStart(&prevLineStart, end: &prevLineEnd, contentsEnd: nil,
                         for: NSRange(location: prevPos, length: 0))
        
        // Skip if previous line is empty (no indentation to maintain)
        let prevLineLength = prevLineEnd - prevLineStart
        guard prevLineLength > 1 else { return }  // 1 for the newline character
        
        // Get the previous line's content
        let prevLineRange = NSRange(location: prevLineStart, length: prevPos - prevLineStart)
        let prevLine = text.substring(with: prevLineRange)
        
        // Calculate indentation from previous line
        var indentString = ""
        for char in prevLine {
            if char == " " || char == "\t" {
                indentString.append(char)
            } else {
                break
            }
        }
        
        // Only apply indentation if there's something to apply
        guard !indentString.isEmpty else { return }
        
        // Check if we need advanced indentation (for specific languages)
        if settings.smartIndent {
            indentString = calculateSmartIndent(
                prevLine: prevLine,
                indentString: indentString,
                language: getCurrentLanguage(textView),
                settings: settings
            )
        }
        
        // Insert the indentation at current position
        if !indentString.isEmpty {
            textView.insertText(indentString, replacementRange: NSRange(location: currentPos, length: 0))
        }
    }
    
    private func calculateSmartIndent(prevLine: String, indentString: String, language: String?, settings: AppSettings) -> String {
        var newIndent = indentString
        
        // Skip smart indent if no language is set
        guard let lang = language else { return newIndent }
        
        // Trim the previous line to check for patterns
        let trimmed = prevLine.trimmingCharacters(in: .whitespaces)
        
        // C-like languages (matching Notepad++ behavior)
        let cLikeLanguages = ["c", "cpp", "java", "cs", "objc", "javascript", "php", "css", "perl", 
                              "rust", "powershell", "json", "typescript", "go", "swift"]
        
        if cLikeLanguages.contains(lang.lowercased()) {
            // Check if previous line ends with {
            if trimmed.hasSuffix("{") {
                // Add one level of indentation
                if settings.replaceTabsBySpaces {
                    newIndent += String(repeating: " ", count: settings.tabSize)
                } else {
                    newIndent += "\t"
                }
            }
        }
        
        // Python-like languages
        let pythonLikeLanguages = ["python", "ruby", "yaml"]
        if pythonLikeLanguages.contains(lang.lowercased()) {
            // Check if previous line ends with :
            if trimmed.hasSuffix(":") {
                // Add one level of indentation
                if settings.replaceTabsBySpaces {
                    newIndent += String(repeating: " ", count: settings.tabSize)
                } else {
                    newIndent += "\t"
                }
            }
        }
        
        return newIndent
    }
    
    private func getCurrentLanguage(_ textView: NSTextView) -> String? {
        // This would need to be connected to the document's language
        // For now, return nil
        return nil
    }
}