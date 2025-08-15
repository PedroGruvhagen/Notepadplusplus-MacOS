//
//  SyntaxHighlighter.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI
import AppKit

class SyntaxHighlighter: ObservableObject {
    private let languageManager = LanguageManager.shared
    
    func highlightedText(for content: String, language: LanguageDefinition?) -> AttributedString {
        guard let language = language else {
            return AttributedString(content)
        }
        
        var attributedString = AttributedString(content)
        
        // Highlight comments first (they override keywords)
        highlightComments(in: &attributedString, content: content, language: language)
        
        // Highlight strings
        highlightStrings(in: &attributedString, content: content)
        
        // Highlight keywords
        for keywordSet in language.keywords {
            highlightKeywords(in: &attributedString, content: content, keywords: keywordSet)
        }
        
        // Highlight numbers
        highlightNumbers(in: &attributedString, content: content)
        
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
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsString = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: match.range.location)
                    let endIndex = attributedString.index(startIndex, offsetByCharacters: match.range.length)
                    let attributeRange = startIndex..<endIndex
                    
                    attributedString[attributeRange].foregroundColor = color
                    
                    if bold {
                        attributedString[attributeRange].font = .system(.body).bold()
                    }
                    
                    if italic {
                        attributedString[attributeRange].font = .system(.body).italic()
                    }
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
    }
}

// Helper extension for AttributedString
extension AttributedString.Index {
    func offsetByCharacters(_ offset: Int) -> AttributedString.Index {
        var index = self
        for _ in 0..<offset {
            index = index.utf16Offset(in: self)
        }
        return index
    }
}

extension AttributedString {
    func index(_ i: AttributedString.Index, offsetByCharacters offset: Int) -> AttributedString.Index {
        var index = i
        var currentOffset = 0
        
        if offset > 0 {
            while currentOffset < offset && index < self.endIndex {
                index = self.index(afterCharacter: index)
                currentOffset += 1
            }
        } else if offset < 0 {
            while currentOffset > offset && index > self.startIndex {
                index = self.index(beforeCharacter: index)
                currentOffset -= 1
            }
        }
        
        return index
    }
    
    func index(afterCharacter i: AttributedString.Index) -> AttributedString.Index {
        return self.characters.index(after: i)
    }
    
    func index(beforeCharacter i: AttributedString.Index) -> AttributedString.Index {
        return self.characters.index(before: i)
    }
}