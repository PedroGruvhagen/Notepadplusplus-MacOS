//
//  SyntaxHighlighter.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI
import AppKit

// Extension to help with color conversion
extension SyntaxStyle {
    var nsColor: NSColor {
        // Convert hex color string to NSColor
        return NSColor(hex: color) ?? NSColor.labelColor
    }
}

class SyntaxHighlighter: ObservableObject {
    private let languageManager = OldLanguageManager.shared
    private var cachedRegexes: [String: NSRegularExpression] = [:]
    
    func highlightedText(for content: String, language: LanguageDefinition?) -> AttributedString {
        guard let language = language else {
            return AttributedString(content)
        }
        
        // Early return for very large files to prevent performance issues
        if content.count > 100000 {
            return AttributedString(content)
        }
        
        var attributedString = AttributedString(content)
        
        // Apply highlighting in order of precedence
        // 1. Strings (highest precedence)
        highlightStrings(in: &attributedString, content: content)
        
        // 2. Comments (override keywords but not strings)
        highlightComments(in: &attributedString, content: content, language: language)
        
        // 3. Numbers
        highlightNumbers(in: &attributedString, content: content)
        
        // 4. Keywords (lowest precedence)
        for keywordSet in language.keywords {
            highlightKeywords(in: &attributedString, content: content, keywords: keywordSet)
        }
        
        return attributedString
    }
    
    private func highlightComments(in attributedString: inout AttributedString, content: String, language: LanguageDefinition) {
        let commentColor = Color(hex: "008000") ?? .green
        
        // Single-line comments
        if let commentLine = language.commentLine {
            let pattern = "\(NSRegularExpression.escapedPattern(for: commentLine)).*$"
            highlightPattern(pattern, in: &attributedString, content: content, color: commentColor, options: .anchorsMatchLines)
        }
        
        // Multi-line comments
        if let commentStart = language.commentStart, let commentEnd = language.commentEnd {
            let escapedStart = NSRegularExpression.escapedPattern(for: commentStart)
            let escapedEnd = NSRegularExpression.escapedPattern(for: commentEnd)
            let pattern = "\(escapedStart)[\\s\\S]*?\(escapedEnd)"
            highlightPattern(pattern, in: &attributedString, content: content, color: commentColor)
        }
    }
    
    private func highlightStrings(in attributedString: inout AttributedString, content: String) {
        let stringColor = Color(hex: "808080") ?? .gray
        
        // Double-quoted strings
        let doubleQuotePattern = "\"(?:[^\"\\\\]|\\\\.)*\""
        highlightPattern(doubleQuotePattern, in: &attributedString, content: content, color: stringColor)
        
        // Single-quoted strings
        let singleQuotePattern = "'(?:[^'\\\\]|\\\\.)*'"
        highlightPattern(singleQuotePattern, in: &attributedString, content: content, color: stringColor)
        
        // Template literals (for JavaScript)
        let templatePattern = "`(?:[^`\\\\]|\\\\.)*`"
        highlightPattern(templatePattern, in: &attributedString, content: content, color: stringColor)
    }
    
    private func highlightNumbers(in attributedString: inout AttributedString, content: String) {
        let numberColor = Color(hex: "FF8000") ?? .orange
        
        // Match various number formats
        let patterns = [
            "\\b\\d+\\.\\d+([eE][+-]?\\d+)?\\b",  // Float with optional scientific notation
            "\\b0[xX][0-9a-fA-F]+\\b",             // Hexadecimal
            "\\b0[oO][0-7]+\\b",                   // Octal
            "\\b0[bB][01]+\\b",                    // Binary
            "\\b\\d+\\b"                           // Integer
        ]
        
        for pattern in patterns {
            highlightPattern(pattern, in: &attributedString, content: content, color: numberColor)
        }
    }
    
    private func highlightKeywords(in attributedString: inout AttributedString, content: String, keywords: KeywordSet) {
        let color = keywords.style.swiftUIColor
        
        for keyword in keywords.keywords {
            // Use word boundaries to match whole words only
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            highlightPattern(
                pattern,
                in: &attributedString,
                content: content,
                color: color,
                bold: keywords.style.bold,
                italic: keywords.style.italic
            )
        }
    }
    
    private func highlightPattern(_ pattern: String, in attributedString: inout AttributedString, content: String, color: Color, bold: Bool = false, italic: Bool = false, options: NSRegularExpression.Options = []) {
        do {
            // Cache regex for better performance
            let cacheKey = "\(pattern)_\(options.rawValue)"
            let regex: NSRegularExpression
            if let cached = cachedRegexes[cacheKey] {
                regex = cached
            } else {
                regex = try NSRegularExpression(pattern: pattern, options: options)
                cachedRegexes[cacheKey] = regex
            }
            
            let nsString = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if let range = Range(match.range, in: content) {
                    if let attributeRange = Range(range, in: attributedString) {
                        // Check if this range already has highlighting (for precedence)
                        if attributedString[attributeRange].foregroundColor == nil {
                            attributedString[attributeRange].foregroundColor = color
                            
                            if bold {
                                attributedString[attributeRange].font = .system(.body).bold()
                            }
                            
                            if italic {
                                attributedString[attributeRange].font = .system(.body).italic()
                            }
                        }
                    }
                }
            }
        } catch {
            // Silently fail for invalid patterns
        }
    }
    
    // MARK: - NSTextStorage Highlighting (for Document-owned text storage)
    
    /// Highlight NSTextStorage directly (for document-owned text storage)
    /// This is used when each Document owns its own NSTextStorage
    func highlight(textStorage: NSTextStorage, language: LanguageDefinition) {
        guard AppSettings.shared.syntaxHighlighting else { return }
        
        let text = textStorage.string
        
        // Clear existing attributes
        textStorage.beginEditing()
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        
        // Apply theme colors
        let theme = ThemeManager.shared.currentTheme
        textStorage.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
        
        // Port of language-specific lexer selection (like defineDocType switch statement)
        switch language.name.lowercased() {
        case "python":
            // Get keywords for LIST_0 and LIST_1
            var keywords0: [String] = []
            var keywords1: [String] = []
            
            for keywordSet in language.keywords {
                if keywordSet.name == "Instructions" {
                    keywords0 = keywordSet.keywords
                } else if keywordSet.name == "Types" || keywordSet.name == "Instructions 2" {
                    keywords1 = keywordSet.keywords
                }
            }
            
            // Direct port of setPythonLexer()
            ScintillaLexerPort.applyPythonHighlighting(
                to: textStorage,
                text: text,
                keywords0: keywords0,
                keywords1: keywords1
            )
            
        case "javascript", "js":
            var keywords0: [String] = []
            for keywordSet in language.keywords {
                if keywordSet.name == "Instructions" {
                    keywords0 = keywordSet.keywords
                    break
                }
            }
            ScintillaLexerPort.applyJavaScriptHighlighting(
                to: textStorage,
                text: text,
                keywords: keywords0
            )
            
        case "c", "cpp", "c++":
            var keywords0: [String] = []
            for keywordSet in language.keywords {
                if keywordSet.name == "Instructions" {
                    keywords0 = keywordSet.keywords
                    break
                }
            }
            ScintillaLexerPort.applyCppHighlighting(
                to: textStorage,
                text: text,
                keywords: keywords0
            )
            
        default:
            // Fallback to basic highlighting for other languages
            applyBasicHighlighting(to: textStorage, language: language)
        }
        
        textStorage.endEditing()
    }
    
    private func applyBasicHighlighting(to textStorage: NSTextStorage, language: LanguageDefinition) {
        let text = textStorage.string
        
        // Apply basic keyword highlighting
        for keywordSet in language.keywords {
            let color = keywordSet.style.nsColor
            for keyword in keywordSet.keywords {
                if let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b", options: []) {
                    let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
                    for match in matches {
                        textStorage.addAttribute(.foregroundColor, value: color, range: match.range)
                    }
                }
            }
        }
    }
}

// Helper extension removed - no longer needed
