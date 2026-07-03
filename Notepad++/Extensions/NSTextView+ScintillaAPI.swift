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
private var highlightGuideColumnKey: UInt8 = 0
private var scintillaDocumentKey: UInt8 = 0
private var liveScintillaDocumentKey: UInt8 = 0
// F07: the .backgroundColor cells currently painted by braceHighlight/braceBadLight, so each brace
// update can remove exactly the previous cells (Scintilla replaces the prior brace indication on
// every SCI_BRACEHIGHLIGHT/SCI_BRACEBADLIGHT, Editor::BraceHighlight) instead of accumulating.
private var braceLightRangesKey: UInt8 = 0

// Weak wrapper so the associated object does not retain the live ScintillaDocument (it is
// owned by its Document; when the document closes, this box's reference goes nil and the
// brace path falls back to the shadow document). Objective-C associated objects cannot
// hold a Swift weak directly, hence the box.
private final class WeakScintillaDocumentBox {
    weak var doc: ScintillaDocument?
    init(_ doc: ScintillaDocument?) { self.doc = doc }
}

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
    
    // Translation of: SCI_GETLENGTH. UTF-16 length (O(1)), the coordinate space the caret
    // (selectedRange) and NSTextStorage use. This puts the whole brace path in ONE position
    // space, matching Scintilla where BraceMatch operates on the same buffer positions the
    // caret comes from (Document.cxx:3021), instead of mixing Character offsets with the
    // UTF-16 caret (F15).
    func getLength() -> Int {
        return (self.string as NSString).length
    }

    // Translation of: SCI_GETCHARAT. Reads one UTF-16 unit at `position` (O(1)) and maps it
    // to a Character exactly as CellBuffer.charAt does (Unicode.Scalar of the unit, or the
    // replacement sentinel for a lone surrogate half of a non-BMP scalar), so brace
    // detection round-trips in UTF-16 with no Character/UTF-16 index mismatch near emoji
    // (F15).
    func getCharAt(_ position: Int) -> Character? {
        let nsString = self.string as NSString
        guard position >= 0 && position < nsString.length else { return nil }
        let unit = nsString.character(at: position)
        if let scalar = Unicode.Scalar(unit) {
            return Character(scalar)
        }
        return "\u{FFFD}"
    }

    // Translation of: SCI_GETCOLUMN. Column of `position`, expanding tabs to the tab stop,
    // scanning back to the line start in UTF-16 units (O(column), O(1) unit access) rather
    // than walking Swift String indices. Same coordinate space as the caret (F15).
    func getColumn(_ position: Int) -> Int {
        let nsString = self.string as NSString
        guard position >= 0 && position <= nsString.length else { return 0 }

        // Find the start of the line: scan back to just after the previous '\n'.
        var lineStart = position
        while lineStart > 0 && nsString.character(at: lineStart - 1) != 0x000A {
            lineStart -= 1
        }

        // Calculate column position, tab stops every 4 (matching Notepad++ default).
        var column = 0
        var i = lineStart
        while i < position {
            if nsString.character(at: i) == 0x0009 { // '\t'
                column = ((column / 4) + 1) * 4
            } else {
                column += 1
            }
            i += 1
        }

        return column
    }

    // Translation of: SCI_LINEFROMPOSITION. Counts '\n' before `position` in UTF-16 units
    // (O(1) unit access, no String index walk). Same coordinate space as the caret (F15).
    func lineFromPosition(_ position: Int) -> Int {
        guard position > 0 else { return 0 }

        let nsString = self.string as NSString
        let limit = min(position, nsString.length)
        var lineNumber = 0
        var i = 0
        while i < limit {
            if nsString.character(at: i) == 0x000A { // '\n'
                lineNumber += 1
            }
            i += 1
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
    
    // MARK: - Live Scintilla document (F11)

    // The document's own ScintillaDocument (Document._doc), which the editor keeps in sync
    // incrementally through the storage delegate (F09). Held weakly (see box above). When
    // present, brace matching runs directly over it with NO per-call full setText.
    var liveScintillaDocument: ScintillaDocument? {
        (objc_getAssociatedObject(self, &liveScintillaDocumentKey) as? WeakScintillaDocumentBox)?.doc
    }

    func setLiveScintillaDocument(_ doc: ScintillaDocument?) {
        objc_setAssociatedObject(self, &liveScintillaDocumentKey, WeakScintillaDocumentBox(doc), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // Translation of: SCI_BRACEMATCH
    // Runs Scintilla's exact Document::BraceMatch (Document.cxx:3021), which operates on ONE
    // buffer position space. When the editor has installed the live document (the one the
    // storage delegate maintains incrementally, F09/F11), match directly against its O(1)
    // UTF-16 CellBuffer with NO per-call setText and NO whole-document style loop. Only the
    // dead editors (no live document installed) fall back to the shadow document that
    // copies the whole text per call, so they still compile and work.
    func braceMatch(_ position: Int) -> Int {
        if let liveDoc = liveScintillaDocument {
            return liveDoc.braceMatch(position, 0, 0, false)
        }

        // Fallback for the dead editors: get or create a shadow document and resync it.
        guard let document = getOrCreateScintillaDocument() else {
            return -1
        }
        synchronizeWithScintillaDocument(document)
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
    
    // F07: the brace .backgroundColor cells currently painted by braceHighlight/braceBadLight. Each
    // new brace update removes exactly these before repainting, mirroring Scintilla replacing the
    // previous brace indication on every SCI_BRACEHIGHLIGHT/SCI_BRACEBADLIGHT (Editor::BraceHighlight).
    var braceLightRanges: [NSRange] {
        get { (objc_getAssociatedObject(self, &braceLightRangesKey) as? [NSRange]) ?? [] }
        set { objc_setAssociatedObject(self, &braceLightRangesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // Remove the previously painted brace .backgroundColor (clamped to the current storage), returning
    // the cleared ranges so the caller can re-assert durable search/Mark All paint over them. Port of
    // Scintilla replacing the previous brace indication on each SCI_BRACEHIGHLIGHT/SCI_BRACEBADLIGHT
    // (Notepad_plus.cpp:3031/3036).
    @discardableResult
    func clearBraceLight() -> [NSRange] {
        guard let storage = textStorage else { braceLightRanges = []; return [] }
        let length = storage.length
        let cleared = braceLightRanges.filter { $0.location >= 0 && NSMaxRange($0) <= length }
        for r in cleared { storage.removeAttribute(.backgroundColor, range: r) }
        braceLightRanges = []
        return cleared
    }

    // Translation of: SCI_BRACEHIGHLIGHT (Notepad_plus.cpp:3036). Scintilla replaces the PREVIOUS
    // brace indication on each call (Editor::BraceHighlight), so clear the prior brace paint before
    // painting the matched pair. Each cell gets a RENDERED .backgroundColor (ThemeManager bracketColor)
    // so matched braces are actually visible (they used to paint an unrendered custom key, F07).
    func braceHighlight(_ pos1: Int, _ pos2: Int) {
        guard let textStorage = self.textStorage else { return }

        // Remove the previous brace paint first so matched-brace backgrounds never accumulate.
        clearBraceLight()

        let color = ThemeManager.shared.currentTheme.bracketColor.withAlphaComponent(0.4)
        let length = textStorage.length
        var painted: [NSRange] = []
        for pos in [pos1, pos2] where pos >= 0 && pos < length {
            let range = NSRange(location: pos, length: 1)
            textStorage.addAttribute(.backgroundColor, value: color, range: range)
            painted.append(range)
        }
        braceLightRanges = painted
    }

    // Translation of: SCI_BRACEBADLIGHT (Notepad_plus.cpp:3031). Scintilla replaces the previous brace
    // indication on each call, so clear the prior brace paint before painting the single unmatched
    // brace cell red. Storing it in braceLightRanges lets the next brace update remove exactly this
    // cell, so the red no longer accumulates across caret moves (F07).
    func braceBadLight(_ position: Int) {
        clearBraceLight()
        guard let textStorage = self.textStorage, position >= 0 else { return }
        let range = NSRange(location: position, length: 1)
        guard range.location + range.length <= textStorage.length else { return }
        textStorage.addAttribute(.backgroundColor, value: NSColor.systemRed.withAlphaComponent(0.3), range: range)
        braceLightRanges = [range]
    }
    
    // Translation of: SCI_SETHIGHLIGHTGUIDE
    func setHighlightGuide(_ column: Int) {
        // Store column using associated object (mimics Scintilla's internal storage)
        objc_setAssociatedObject(self, &highlightGuideColumnKey, column, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.needsDisplay = true
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
        // Check if brace matching is allowed (based on file size restrictions). The
        // restriction is now cached in AppSettings (F12), and the size uses the O(1) UTF-16
        // length instead of the O(n) grapheme walk `storage.string.count`.
        let restriction = AppSettings.shared.largeFileRestriction
        let fileSize = (storage.string as NSString).length
        
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
    
    // Replace a specific range with undo registration. Used by Find/Replace so a wrong
    // replacement can be reverted with Cmd+Z (previously replacements bypassed the text
    // view and the undo stack entirely). UTF-16 NSRange, matching NSString match offsets.
    func replaceCharactersUndoable(in range: NSRange, with text: String) {
        if self.shouldChangeText(in: range, replacementString: text) {
            self.textStorage?.replaceCharacters(in: range, with: text)
            self.didChangeText()
        }
    }

    // Replace every occurrence in `ranges` with `replacement` as ONE batched edit (F46).
    //
    // Translation of Notepad++ Replace All: processAll turns OFF all modification notifications
    // (SCI_SETMODEVENTMASK, 0 at FindReplaceDlg.cpp:3329) for the whole processRange loop of
    // replaceTarget calls (FindReplaceDlg.cpp:3654-3664), then restores them and posts ONE
    // document-modified update afterwards (:3391-3396); the caller wraps it in
    // SCI_BEGINUNDOACTION/ENDUNDOACTION (FindReplaceDlg.cpp:2538-2540) so it is a single undo step.
    //
    // The macOS equivalents:
    //   * shouldChangeText(in:replacementStrings:) registers ONE multi-range undo action, so the
    //     whole Replace All reverts with a single Cmd+Z.
    //   * A single textStorage.beginEditing()/endEditing() around all replaceCharacters coalesces
    //     every edit into ONE NSTextStorageDelegate callback (the Scintilla notification point that
    //     applyIncrementalEdit resyncs _doc.cb from), and ONE textDidChange after didChangeText().
    //     That is the SCI_SETMODEVENTMASK 0 suppression: the per-keystroke pipeline (model resync,
    //     brace match, current-line + smart highlight, gutter/fold render) runs once, not per match,
    //     turning a multi-minute per-hit hang into a single pass.
    // Returns the number of occurrences replaced.
    @discardableResult
    func replaceAllOccurrences(in ranges: [NSRange], with replacement: String) -> Int {
        guard let storage = self.textStorage, !ranges.isEmpty else { return 0 }

        // Ascending, so the undo snapshot ranges are well-ordered; apply in reverse so each edit
        // does not shift the offsets of the edits not yet applied.
        let ordered = ranges.sorted { $0.location < $1.location }
        let rangeValues = ordered.map { NSValue(range: $0) }
        let replacements = Array(repeating: replacement, count: ordered.count)

        guard self.shouldChangeText(inRanges: rangeValues, replacementStrings: replacements) else { return 0 }

        storage.beginEditing()
        for range in ordered.reversed() {
            storage.replaceCharacters(in: range, with: replacement)
        }
        storage.endEditing()
        self.didChangeText()

        return ordered.count
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