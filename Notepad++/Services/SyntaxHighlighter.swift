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

    /// The UTF-16 character range currently visible in `textView`, or nil if none can be
    /// resolved yet (view not laid out / not in a window). Used to style the visible
    /// window first at open and tab switch (Editor.cxx:5413 StyleToPositionInView clamps
    /// styling to the visible client area). Resolving the glyph range for the visible rect
    /// lays out only that rect when non-contiguous layout is enabled (F24).
    static func visibleCharacterRange(of textView: NSTextView) -> NSRange? {
        guard let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return nil }
        let visibleRect = textView.visibleRect
        guard visibleRect.width > 0 && visibleRect.height > 0 else { return nil }
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        guard glyphRange.length > 0 else { return nil }
        return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }

    /// One combined `\b(?:kw1|kw2|...)\b` regex per keyword set, compiled once and cached.
    /// This replaces compiling and running a fresh whole-document regex per keyword (F25).
    func combinedKeywordRegex(for keywords: [String]) -> NSRegularExpression? {
        guard !keywords.isEmpty else { return nil }
        let cacheKey = "kw:" + keywords.joined(separator: "\u{1}")
        if let cached = cachedRegexes[cacheKey] { return cached }
        let alternation = keywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: "\\b(?:\(alternation))\\b", options: []) else { return nil }
        cachedRegexes[cacheKey] = regex
        return regex
    }

    /// Highlight NSTextStorage directly (for document-owned text storage). `range` limits
    /// styling to a sub-range (the visible range at open / tab switch); nil styles the
    /// whole document. Faithful to Scintilla styling only the damaged / visible region
    /// (Document.cxx:2616 EnsureStyledTo, Editor.cxx:5413 StyleToPositionInView) instead
    /// of clearing and re-styling the whole document on every event.
    func highlight(textStorage: NSTextStorage, language: LanguageDefinition, range: NSRange? = nil) {
        guard AppSettings.shared.syntaxHighlighting else { return }

        let text = textStorage.string
        let nsText = text as NSString
        let fullLength = nsText.length
        guard fullLength > 0 else { return }

        // Clamp the requested range to the storage and expand it to whole lines so that
        // line-oriented lexers always see complete lines. UTF-16 length, never grapheme
        // count, so ranges match the NSTextStorage coordinate space.
        let requestedLocation = min(max(0, range?.location ?? 0), fullLength)
        let requestedLength = min(max(0, range?.length ?? fullLength), fullLength - requestedLocation)
        let targetRange = nsText.lineRange(for: NSRange(location: requestedLocation, length: requestedLength))

        // Clear existing attributes within the target range only
        textStorage.beginEditing()
        textStorage.removeAttribute(.foregroundColor, range: targetRange)
        textStorage.removeAttribute(.font, range: targetRange)

        // Apply theme colors within the target range
        let theme = ThemeManager.shared.currentTheme
        textStorage.addAttribute(.foregroundColor, value: theme.textColor, range: targetRange)

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
                range: targetRange,
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
                range: targetRange,
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
                range: targetRange,
                keywords: keywords0
            )

        default:
            // Fallback to basic highlighting for other languages
            applyBasicHighlighting(to: textStorage, language: language, range: targetRange)
        }

        textStorage.endEditing()
    }

    private func applyBasicHighlighting(to textStorage: NSTextStorage, language: LanguageDefinition, range: NSRange) {
        let text = textStorage.string

        // Apply basic keyword highlighting: ONE combined, cached regex per keyword set,
        // run once over the target range, instead of a fresh whole-document regex per
        // keyword (F25). For languages with no keyword lists (e.g. Markdown) this is a
        // no-op, so a plain-text open pays no keyword cost.
        for keywordSet in language.keywords {
            guard let regex = combinedKeywordRegex(for: keywordSet.keywords) else { continue }
            let color = keywordSet.style.nsColor
            for match in regex.matches(in: text, options: [], range: range) {
                textStorage.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
    }
}

// Helper extension removed - no longer needed
