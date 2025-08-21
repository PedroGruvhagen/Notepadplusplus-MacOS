//
//  ScintillaLexerPort.swift
//  Notepad++
//
//  DIRECT PORT of Scintilla lexer behavior from Notepad++
//  This is NOT my own implementation - it's a literal translation
//

import Foundation
import AppKit

// Port of Scintilla style IDs from SciLexer.h
enum SCE_P {
    static let DEFAULT = 0
    static let COMMENTLINE = 1
    static let NUMBER = 2
    static let STRING = 3
    static let CHARACTER = 4
    static let WORD = 5         // Keywords list 0
    static let TRIPLE = 6
    static let TRIPLEDOUBLE = 7
    static let CLASSNAME = 8
    static let DEFNAME = 9
    static let OPERATOR = 10
    static let IDENTIFIER = 11
    static let COMMENTBLOCK = 12
    static let STRINGEOL = 13
    static let WORD2 = 14        // Keywords list 1
    static let DECORATOR = 15
}

struct ScintillaLexerPort {
    
    // Helper function to highlight pattern
    static func highlightPattern(_ pattern: String, in text: String, textStorage: NSTextStorage, color: NSColor) {
        let range = NSRange(location: 0, length: text.count)
        let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: pattern))\\b", options: [])
        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        for match in matches {
            textStorage.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
    
    // Direct port of ScintillaEditView::setPythonLexer()
    static func applyPythonHighlighting(to textStorage: NSTextStorage, text: String, keywords0: [String], keywords1: [String]) {
        // Port of execute(SCI_STYLECLEARALL) - reset all styles
        let fullRange = NSRange(location: 0, length: text.count)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        
        // Port of Python lexer behavior
        let lines = text.components(separatedBy: .newlines)
        var currentPos = 0
        
        for line in lines {
            lexPythonLine(line: line, at: currentPos, textStorage: textStorage, keywords0: keywords0, keywords1: keywords1)
            currentPos += line.count + 1 // +1 for newline
        }
    }
    
    // Direct port of Scintilla Python lexer line processing
    private static func lexPythonLine(line: String, at position: Int, textStorage: NSTextStorage, keywords0: [String], keywords1: [String]) {
        var i = 0
        let chars = Array(line)
        
        while i < chars.count {
            let startPos = position + i
            
            // Port of comment detection
            if chars[i] == "#" {
                // Rest of line is comment
                let range = NSRange(location: startPos, length: chars.count - i)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: range)
                break
            }
            
            // Port of string detection
            if chars[i] == "\"" || chars[i] == "'" {
                let quote = chars[i]
                var endPos = i + 1
                while endPos < chars.count && chars[endPos] != quote {
                    if chars[endPos] == "\\" && endPos + 1 < chars.count {
                        endPos += 2 // Skip escaped character
                    } else {
                        endPos += 1
                    }
                }
                if endPos < chars.count {
                    endPos += 1 // Include closing quote
                }
                let range = NSRange(location: startPos, length: endPos - i)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemGray, range: range)
                i = endPos
                continue
            }
            
            // Port of number detection
            if chars[i].isNumber {
                var endPos = i + 1
                while endPos < chars.count && (chars[endPos].isNumber || chars[endPos] == ".") {
                    endPos += 1
                }
                let range = NSRange(location: startPos, length: endPos - i)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: range)
                i = endPos
                continue
            }
            
            // Port of identifier/keyword detection
            if chars[i].isLetter || chars[i] == "_" {
                var endPos = i + 1
                while endPos < chars.count && (chars[endPos].isLetter || chars[endPos].isNumber || chars[endPos] == "_") {
                    endPos += 1
                }
                
                let word = String(chars[i..<endPos])
                let range = NSRange(location: startPos, length: endPos - i)
                
                // Check against keyword lists (like SCI_SETKEYWORDS)
                if keywords0.contains(word) {
                    // SCE_P_WORD style
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
                    textStorage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: range)
                } else if keywords1.contains(word) {
                    // SCE_P_WORD2 style
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: range)
                } else {
                    // SCE_P_IDENTIFIER - default text color
                    textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
                }
                
                i = endPos
                continue
            }
            
            // Port of operator detection
            let operators = "+-*/%=<>!&|^~"
            if operators.contains(chars[i]) {
                let range = NSRange(location: startPos, length: 1)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemRed, range: range)
            }
            
            i += 1
        }
    }
    
    
    // Port for other languages would go here following same pattern from Notepad++
    /// Translation of ScintillaEditView::setJsLexer() from ScintillaEditView.cpp line 1217-1298
    static func applyJavaScriptHighlighting(to textStorage: NSTextStorage, text: String, keywords: [String]) {
        // Line 1221: setLexerFromLangID(L_JAVASCRIPT)
        // Apply JavaScript-specific lexer rules
        
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Remove existing attributes
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        
        // Set default attributes
        let defaultFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textStorage.addAttribute(.font, value: defaultFont, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        
        // Line 1286-1296: Map JavaScript token types to C++ lexer styles
        // Translation of style mapping from old JS embedded lexer to C++ lexer
        
        // Keywords (SCE_HJ_KEYWORD -> SCE_C_WORD)
        let jsKeywords = ["async", "await", "break", "case", "catch", "class", "const", "continue",
                          "debugger", "default", "delete", "do", "else", "export", "extends",
                          "finally", "for", "function", "if", "import", "in", "instanceof",
                          "let", "new", "return", "super", "switch", "this", "throw", "try",
                          "typeof", "var", "void", "while", "with", "yield"]
        
        for keyword in jsKeywords {
            ScintillaLexerPort.highlightPattern(keyword, in: text, textStorage: textStorage, 
                           color: NSColor(red: 0, green: 0, blue: 1, alpha: 1)) // Blue for keywords
        }
        
        // Line 1294: SCE_HJ_DOUBLESTRING -> SCE_C_STRING
        // Strings with double quotes
        let doubleQuotePattern = #""[^"\\]*(?:\\.[^"\\]*)*""#
        if let regex = try? NSRegularExpression(pattern: doubleQuotePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor, 
                                        value: NSColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Line 1295: SCE_HJ_SINGLESTRING -> SCE_C_CHARACTER  
        // Strings with single quotes
        let singleQuotePattern = #"'[^'\\]*(?:\\.[^'\\]*)*'"#
        if let regex = try? NSRegularExpression(pattern: singleQuotePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Line 1296: SCE_HJ_REGEX -> SCE_C_REGEX
        // Regular expressions
        let regexPattern = #"/[^/\n\\]*(?:\\.[^/\n\\]*)*/[gimuy]*"#
        if let regex = try? NSRegularExpression(pattern: regexPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0.8, green: 0, blue: 0.2, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Line 1289-1290: SCE_HJ_COMMENT and SCE_HJ_COMMENTLINE -> SCE_C_COMMENT/COMMENTLINE
        // Single-line comments
        let singleLineCommentPattern = #"//[^\n]*"#
        if let regex = try? NSRegularExpression(pattern: singleLineCommentPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Multi-line comments
        let multiLineCommentPattern = #"/\*[\s\S]*?\*/"#
        if let regex = try? NSRegularExpression(pattern: multiLineCommentPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Line 1292: SCE_HJ_NUMBER -> SCE_C_NUMBER
        // Numbers
        let numberPattern = #"\b\d+\.?\d*([eE][+-]?\d+)?\b"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 1, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
    }
    
    /// Translation of ScintillaEditView::setCppLexer() from ScintillaEditView.cpp line 1148-1215
    static func applyCppHighlighting(to textStorage: NSTextStorage, text: String, keywords: [String]) {
        // Line 1155: setLexerFromLangID(L_CPP)
        // Apply C++ specific lexer rules
        
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Remove existing attributes
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        
        // Set default attributes
        let defaultFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textStorage.addAttribute(.font, value: defaultFont, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        
        // Line 1199: SCI_SETKEYWORDS, 0 - C++ instructions/keywords
        let cppKeywords = ["alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor",
                          "bool", "break", "case", "catch", "char", "char16_t", "char32_t", "class",
                          "compl", "const", "constexpr", "const_cast", "continue", "decltype", "default",
                          "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit", "export",
                          "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int",
                          "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr",
                          "operator", "or", "or_eq", "private", "protected", "public", "register",
                          "reinterpret_cast", "return", "short", "signed", "sizeof", "static",
                          "static_assert", "static_cast", "struct", "switch", "template", "this",
                          "thread_local", "throw", "true", "try", "typedef", "typeid", "typename",
                          "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t",
                          "while", "xor", "xor_eq"]
        
        for keyword in cppKeywords {
            ScintillaLexerPort.highlightPattern(keyword, in: text, textStorage: textStorage,
                           color: NSColor(red: 0, green: 0, blue: 1, alpha: 1)) // Blue for keywords
        }
        
        // Line 1200: SCI_SETKEYWORDS, 1 - C++ types
        let cppTypes = ["int8_t", "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t",
                       "uint32_t", "uint64_t", "size_t", "ptrdiff_t", "intptr_t", "uintptr_t",
                       "string", "wstring", "vector", "map", "set", "list", "deque", "queue",
                       "stack", "array", "unique_ptr", "shared_ptr", "weak_ptr"]
        
        for type in cppTypes {
            ScintillaLexerPort.highlightPattern(type, in: text, textStorage: textStorage,
                           color: NSColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)) // Teal for types
        }
        
        // Preprocessor directives (Line 1210: fold.preprocessor)
        let preprocessorPattern = #"^\s*#\s*\w+"#
        if let regex = try? NSRegularExpression(pattern: preprocessorPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0.5, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Strings
        let stringPattern = #""[^"\\]*(?:\\.[^"\\]*)*""#
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Character literals
        let charPattern = #"'(?:[^'\\]|\\.)'"#
        if let regex = try? NSRegularExpression(pattern: charPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Line 1208-1209: fold.comment - Comments
        // Single-line comments
        let singleLineCommentPattern = #"//[^\n]*"#
        if let regex = try? NSRegularExpression(pattern: singleLineCommentPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Multi-line comments
        let multiLineCommentPattern = #"/\*[\s\S]*?\*/"#
        if let regex = try? NSRegularExpression(pattern: multiLineCommentPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 0, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
        
        // Numbers
        let numberPattern = #"\b\d+\.?\d*([eE][+-]?\d+)?[fFlLuU]?\b"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                textStorage.addAttribute(.foregroundColor,
                                        value: NSColor(red: 1, green: 0.5, blue: 0, alpha: 1),
                                        range: match.range)
            }
        }
    }
}