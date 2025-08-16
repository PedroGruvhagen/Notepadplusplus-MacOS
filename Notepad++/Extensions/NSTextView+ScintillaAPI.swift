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
private var scintillaDocumentKey: UInt8 = 0

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
    // This now uses the EXACT translation of Scintilla's Document::BraceMatch
    func braceMatch(_ position: Int) -> Int {
        // Get or create the Scintilla document
        guard let document = getOrCreateScintillaDocument() else {
            return -1
        }
        
        // Synchronize text and styles with the document
        synchronizeWithScintillaDocument(document)
        
        // Call the exact translated BraceMatch function from Document.cxx
        return document.braceMatch(position, 0, 0, false)
    }
    
    // Helper to get or create associated Scintilla document
    private func getOrCreateScintillaDocument() -> ScintillaDocument? {
        if let doc = objc_getAssociatedObject(self, &scintillaDocumentKey) as? ScintillaDocument {
            return doc
        }
        
        let doc = ScintillaDocument()
        objc_setAssociatedObject(self, &scintillaDocumentKey, doc, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return doc
    }
    
    // Helper to synchronize NSTextView with Scintilla document
    private func synchronizeWithScintillaDocument(_ doc: ScintillaDocument) {
        let text = self.string
        doc.cb.setText(text)
        
        // Apply syntax styles if available
        if let textStorage = self.textStorage {
            applySyntaxStylesToDocument(doc, from: textStorage)
        }
    }
    
    // Apply NSTextStorage styles to Scintilla document
    private func applySyntaxStylesToDocument(_ doc: ScintillaDocument, from textStorage: NSTextStorage) {
        // Map NSTextStorage attributes to Scintilla style IDs
        let STYLE_DEFAULT: UInt8 = 0
        let STYLE_COMMENT: UInt8 = 1
        let STYLE_STRING: UInt8 = 2
        let STYLE_KEYWORD: UInt8 = 3
        
        // Iterate through the text and map colors to style IDs
        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Set default style for all positions
        for i in 0..<text.count {
            doc.cb.setStyleAt(i, STYLE_DEFAULT)
        }
        
        // Map color attributes to Scintilla styles
        textStorage.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, range, _ in
            if let color = value as? NSColor {
                var styleId = STYLE_DEFAULT
                
                // Map colors to style IDs (based on typical syntax highlighting colors)
                if color == NSColor.systemGreen {
                    styleId = STYLE_COMMENT
                } else if color == NSColor.systemRed {
                    styleId = STYLE_STRING
                } else if color == NSColor.systemBlue {
                    styleId = STYLE_KEYWORD
                }
                
                // Apply style to range
                for i in range.location..<(range.location + range.length) {
                    if i < text.count {
                        doc.cb.setStyleAt(i, styleId)
                    }
                }
            }
        }
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

// MARK: - Text Modification APIs (Translation from Editor.cxx)

extension NSTextView {
    
    // Translation of: SCI_REPLACESEL
    // Replaces the selected text with the specified text
    func replaceSel(_ text: String) {
        // Get current selection
        let range = self.selectedRange()
        
        // Replace the selection with new text
        if self.shouldChangeText(in: range, replacementString: text) {
            self.textStorage?.replaceCharacters(in: range, with: text)
            self.didChangeText()
            
            // Move cursor to end of inserted text
            let newPosition = range.location + text.count
            self.setSelectedRange(NSRange(location: newPosition, length: 0))
        }
    }
    
    // Translation of: SCI_INSERTTEXT
    // Insert text at a specific position
    func insertText(at position: Int, text: String) {
        guard position >= 0 && position <= self.string.count else { return }
        
        let range = NSRange(location: position, length: 0)
        
        if self.shouldChangeText(in: range, replacementString: text) {
            self.textStorage?.replaceCharacters(in: range, with: text)
            self.didChangeText()
        }
    }
    
    // Translation of: SCI_DELETERANGE
    // Delete a range of text
    func deleteRange(start: Int, length: Int) {
        guard start >= 0 && start + length <= self.string.count else { return }
        
        let range = NSRange(location: start, length: length)
        
        if self.shouldChangeText(in: range, replacementString: "") {
            self.textStorage?.replaceCharacters(in: range, with: "")
            self.didChangeText()
        }
    }
    
    // Translation of: SCI_CLEARALL
    // Clear all text in the document
    func clearAll() {
        let fullRange = NSRange(location: 0, length: self.string.count)
        
        if self.shouldChangeText(in: fullRange, replacementString: "") {
            self.textStorage?.replaceCharacters(in: fullRange, with: "")
            self.didChangeText()
        }
    }
    
    // Translation of: SCI_ADDTEXT
    // Add text to the current position
    func addText(_ text: String) {
        let position = self.selectedRange().location
        insertText(at: position, text: text)
    }
    
    // Translation of: SCI_UNDO
    func undo() {
        self.undoManager?.undo()
    }
    
    // Translation of: SCI_REDO
    func redo() {
        self.undoManager?.redo()
    }
    
    // Translation of: SCI_CANUNDO
    func canUndo() -> Bool {
        return self.undoManager?.canUndo ?? false
    }
    
    // Translation of: SCI_CANREDO
    func canRedo() -> Bool {
        return self.undoManager?.canRedo ?? false
    }
    
    // Translation of: SCI_BEGINUNDOACTION
    func beginUndoAction() {
        self.undoManager?.beginUndoGrouping()
    }
    
    // Translation of: SCI_ENDUNDOACTION
    func endUndoAction() {
        self.undoManager?.endUndoGrouping()
    }
    
    // Translation of: SCI_SETSEL
    func setSel(_ start: Int, _ end: Int) {
        let safeStart = max(0, min(start, self.string.count))
        let safeEnd = max(safeStart, min(end, self.string.count))
        let range = NSRange(location: safeStart, length: safeEnd - safeStart)
        self.setSelectedRange(range)
    }
    
    // Translation of: SCI_GETSEL
    func getSel() -> (start: Int, end: Int) {
        let range = self.selectedRange()
        return (range.location, range.location + range.length)
    }
    
    // Translation of: SCI_GETSELTEXT
    func getSelText() -> String {
        let range = self.selectedRange()
        guard range.length > 0 else { return "" }
        
        let text = self.string as NSString
        return text.substring(with: range)
    }
    
    // Translation of: SCI_SELECTALL
    func selectAll() {
        let range = NSRange(location: 0, length: self.string.count)
        self.setSelectedRange(range)
    }
    
    // Translation of: SCI_GOTOPOS
    func gotoPos(_ position: Int) {
        let safePos = max(0, min(position, self.string.count))
        self.setSelectedRange(NSRange(location: safePos, length: 0))
    }
    
    // Translation of: SCI_GOTOLINE
    func gotoLine(_ line: Int) {
        let text = self.string
        var currentLine = 0
        var position = 0
        
        for (index, char) in text.enumerated() {
            if currentLine == line {
                position = index
                break
            }
            if char == "\n" {
                currentLine += 1
            }
        }
        
        gotoPos(position)
    }
    
    // Translation of: SCI_SETCURRENTPOS
    func setCurrentPos(_ position: Int) {
        gotoPos(position)
    }
    
    // Translation of: SCI_GETANCHOR
    func getAnchor() -> Int {
        // In NSTextView, anchor is the start of selection
        return self.selectedRange().location
    }
    
    // Translation of: SCI_SETANCHOR
    func setAnchor(_ position: Int) {
        // Set selection from anchor to current position
        let currentPos = getCurrentPos()
        if position < currentPos {
            setSel(position, currentPos)
        } else {
            setSel(currentPos, position)
        }
    }
}