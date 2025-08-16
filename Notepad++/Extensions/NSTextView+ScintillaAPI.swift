//
//  NSTextView+ScintillaAPI.swift
//  Notepad++
//
//  Scintilla API compatibility layer for NSTextView
//  This file provides exact equivalents of Scintilla APIs used in Notepad++
//  DIRECT TRANSLATION from Scintilla API to macOS NSTextView
//

import AppKit
import ObjectiveC

// MARK: - Associated Objects for storing bracket positions
// Since we can't use setValue:forKey: on NSTextView, we use associated objects
// This mimics how Scintilla internally stores these values
private var bracketHighlightPos1Key: UInt8 = 0
private var bracketHighlightPos2Key: UInt8 = 0
private var highlightGuideColumnKey: UInt8 = 0

// MARK: - Scintilla API Constants (from Scintilla.h)
enum ScintillaConstants {
    // Brace highlighting
    static let SCI_BRACEHIGHLIGHT = 2351
    static let SCI_BRACEBADLIGHT = 2352
    static let SCI_BRACEMATCH = 2353
    static let SCI_SETHIGHLIGHTGUIDE = 2134
    
    // Position and navigation
    static let SCI_GETCURRENTPOS = 2008
    static let SCI_GETCHARAT = 2007
    static let SCI_GETLENGTH = 2006
    static let SCI_GETCOLUMN = 2129
    static let SCI_LINEFROMPOSITION = 2166
    static let SCI_GETLINEINDENT = 2128
}

extension NSTextView {
    
    // MARK: - Buffer Management (Translation of Buffer class methods)
    
    var currentBuffer: TextBuffer? {
        // Translation of: Buffer* _pEditView->getCurrentBuffer()
        // In our case, the buffer is the text storage itself
        return self.textStorage.map { TextBuffer(storage: $0) }
    }
    
    // MARK: - Position and Character Access
    
    // Translation of: SCI_GETCURRENTPOS
    func getCurrentPos() -> Int {
        return self.selectedRange().location
    }
    
    // Translation of: SCI_GETLENGTH
    func getLength() -> Int {
        return self.string.count
    }
    
    // Translation of: SCI_GETCHARAT
    func getCharAt(_ position: Int) -> Character? {
        guard position >= 0 && position < self.string.count else { return nil }
        let index = self.string.index(self.string.startIndex, offsetBy: position)
        return self.string[index]
    }
    
    // Translation of: SCI_GETCOLUMN
    func getColumn(_ position: Int) -> Int {
        guard position >= 0 && position < self.string.count else { return 0 }
        
        let text = self.string
        let index = text.index(text.startIndex, offsetBy: position)
        
        // Find the start of the line
        var lineStart = index
        while lineStart > text.startIndex && text[text.index(before: lineStart)] != "\n" {
            lineStart = text.index(before: lineStart)
        }
        
        // Calculate column position (handling tabs)
        var column = 0
        var currentIndex = lineStart
        while currentIndex < index {
            if text[currentIndex] == "\t" {
                // Tab stops every 4 spaces (matching Notepad++ default)
                column = ((column / 4) + 1) * 4
            } else {
                column += 1
            }
            currentIndex = text.index(after: currentIndex)
        }
        
        return column
    }
    
    // Translation of: SCI_LINEFROMPOSITION
    func lineFromPosition(_ position: Int) -> Int {
        guard position >= 0 else { return 0 }
        
        let text = self.string
        var lineNumber = 0
        var currentPos = 0
        
        for char in text {
            if currentPos >= position {
                break
            }
            if char == "\n" {
                lineNumber += 1
            }
            currentPos += 1
        }
        
        return lineNumber
    }
    
    // Translation of: SCI_GETLINEINDENT
    func getLineIndent(_ line: Int) -> Int {
        let text = self.string
        var currentLine = 0
        var lineStartIndex = text.startIndex
        
        // Find the start of the requested line
        for (index, char) in text.enumerated() {
            if currentLine == line {
                lineStartIndex = text.index(text.startIndex, offsetBy: index)
                break
            }
            if char == "\n" {
                currentLine += 1
            }
        }
        
        // Count indentation (spaces and tabs)
        var indent = 0
        var index = lineStartIndex
        while index < text.endIndex {
            let char = text[index]
            if char == " " {
                indent += 1
            } else if char == "\t" {
                indent += 4 // Tab counts as 4 spaces (Notepad++ default)
            } else {
                break
            }
            index = text.index(after: index)
        }
        
        return indent
    }
    
    // MARK: - Brace Matching
    
    // Translation of: SCI_BRACEMATCH
    func braceMatch(_ position: Int) -> Int {
        let text = self.string
        guard position >= 0 && position < text.count else { return -1 }
        
        let index = text.index(text.startIndex, offsetBy: position)
        let char = text[index]
        
        // Check if it's a brace character
        let openBraces = "([{"
        let closeBraces = ")]}"
        let allBraces = "()[]{}";
        
        guard allBraces.contains(char) else { return -1 }
        
        if openBraces.contains(char) {
            // Find closing brace
            let matchChar: Character
            switch char {
            case "(": matchChar = ")"
            case "[": matchChar = "]"
            case "{": matchChar = "}"
            default: return -1
            }
            
            var depth = 1
            var searchIndex = text.index(after: index)
            var currentPos = position + 1
            
            while searchIndex < text.endIndex {
                let currentChar = text[searchIndex]
                if currentChar == char {
                    depth += 1
                } else if currentChar == matchChar {
                    depth -= 1
                    if depth == 0 {
                        return currentPos
                    }
                }
                searchIndex = text.index(after: searchIndex)
                currentPos += 1
            }
        } else if closeBraces.contains(char) {
            // Find opening brace
            let matchChar: Character
            switch char {
            case ")": matchChar = "("
            case "]": matchChar = "["
            case "}": matchChar = "{"
            default: return -1
            }
            
            var depth = 1
            var searchIndex = index
            var currentPos = position
            
            while searchIndex > text.startIndex {
                searchIndex = text.index(before: searchIndex)
                currentPos -= 1
                let currentChar = text[searchIndex]
                if currentChar == char {
                    depth += 1
                } else if currentChar == matchChar {
                    depth -= 1
                    if depth == 0 {
                        return currentPos
                    }
                }
            }
        }
        
        return -1 // No match found
    }
    
    // Translation of: SCI_BRACEHIGHLIGHT
    func braceHighlight(_ pos1: Int, _ pos2: Int) {
        // Store positions using associated objects (mimics Scintilla's internal storage)
        objc_setAssociatedObject(self, &bracketHighlightPos1Key, pos1, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bracketHighlightPos2Key, pos2, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Trigger display update
        guard let textStorage = self.textStorage else { return }
        
        // Clear any existing bracket highlighting first
        if textStorage.length > 0 {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.removeAttribute(.bracketHighlight, range: fullRange)
        }
        
        // Apply new highlighting
        if pos1 >= 0 && pos1 < textStorage.length {
            let range1 = NSRange(location: pos1, length: min(1, textStorage.length - pos1))
            textStorage.addAttribute(.bracketHighlight, value: NSColor.systemYellow.withAlphaComponent(0.3), range: range1)
        }
        
        if pos2 >= 0 && pos2 < textStorage.length {
            let range2 = NSRange(location: pos2, length: min(1, textStorage.length - pos2))
            textStorage.addAttribute(.bracketHighlight, value: NSColor.systemYellow.withAlphaComponent(0.3), range: range2)
        }
    }
    
    // Translation of: SCI_BRACEBADLIGHT
    func braceBadLight(_ position: Int) {
        // Highlight unmatched brace in red
        if position >= 0, let textStorage = self.textStorage {
            let range = NSRange(location: position, length: 1)
            // Ensure range is valid
            if range.location + range.length <= textStorage.length {
                textStorage.addAttribute(.backgroundColor, value: NSColor.systemRed.withAlphaComponent(0.3), range: range)
            }
        }
    }
    
    // Translation of: SCI_SETHIGHLIGHTGUIDE
    func setHighlightGuide(_ column: Int) {
        // Store column using associated object (mimics Scintilla's internal storage)
        objc_setAssociatedObject(self, &highlightGuideColumnKey, column, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.needsDisplay = true
    }
    
    // Helper to get stored bracket positions
    func getBracketHighlightPositions() -> (pos1: Int?, pos2: Int?) {
        let pos1 = objc_getAssociatedObject(self, &bracketHighlightPos1Key) as? Int
        let pos2 = objc_getAssociatedObject(self, &bracketHighlightPos2Key) as? Int
        return (pos1, pos2)
    }
    
    // Helper to get highlight guide column
    func getHighlightGuideColumn() -> Int? {
        return objc_getAssociatedObject(self, &highlightGuideColumnKey) as? Int
    }
    
    // Helper to check if indent guides are shown
    func isShownIndentGuide() -> Bool {
        // This would be a setting in the app
        return AppSettings.shared.showIndentGuides
    }
    
    // Enable/disable menu commands (translation of enableCommand)
    func enableCommand(_ commandID: CommandID, _ enable: Bool) {
        // This would update menu item states
        NotificationCenter.default.post(
            name: .commandStateChanged,
            object: nil,
            userInfo: ["commandID": commandID, "enabled": enable]
        )
    }
}

// MARK: - Supporting Types

// Translation of Buffer class
struct TextBuffer {
    let storage: NSTextStorage
    
    // Translation of: Buffer::allowBraceMach()
    func allowBraceMatch() -> Bool {
        // Check if brace matching is allowed (based on file size restrictions)
        let restriction = AppSettings.shared.largeFileRestriction
        let fileSize = storage.string.count
        
        // Check large file restrictions (matching Parameters.cpp logic)
        if restriction.isEnabled {
            let maxSize = restriction.fileSizeMB * 1024 * 1024
            if fileSize > maxSize {
                return restriction.allowBraceMatch
            }
        }
        
        return true
    }
}

// Command IDs (matching menuCmdID.h)
enum CommandID {
    case searchGotoMatchingBrace    // IDM_SEARCH_GOTOMATCHINGBRACE
    case searchSelectMatchingBraces  // IDM_SEARCH_SELECTMATCHINGBRACES
}

// Notification for command state changes
extension Notification.Name {
    static let commandStateChanged = Notification.Name("commandStateChanged")
}

// Custom attribute for bracket highlighting
extension NSAttributedString.Key {
    static let bracketHighlight = NSAttributedString.Key("NotepadPlusBracketHighlight")
}