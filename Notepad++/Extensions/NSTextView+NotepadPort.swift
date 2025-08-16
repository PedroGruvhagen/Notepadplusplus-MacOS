//
//  NSTextView+NotepadPort.swift
//  Notepad++
//
//  Direct port of Notepad++ indentation behavior from maintainIndentation function
//

import AppKit

extension NSTextView {
    
    // Direct port of Notepad_plus::maintainIndentation(wchar_t ch)
    func maintainIndentation(character ch: Character) {
        let settings = AppSettings.shared
        
        // if (nppGui._maintainIndent == autoIndent_none) return;
        guard settings.maintainIndent else { return }
        
        // Only handle newline characters
        guard ch == "\n" || ch == "\r" else { return }
        
        let text = self.string as NSString
        let currentPos = self.selectedRange().location
        
        // Get current line number (we're already on the new line after Enter was pressed)
        var currentLineStart = 0
        var currentLineEnd = 0
        text.getLineStart(&currentLineStart, end: &currentLineEnd, contentsEnd: nil,
                         for: NSRange(location: currentPos, length: 0))
        
        // Get previous line
        guard currentLineStart > 0 else { return }
        
        let prevPos = currentLineStart - 1
        var prevLineStart = 0
        var prevLineEnd = 0
        text.getLineStart(&prevLineStart, end: &prevLineEnd, contentsEnd: nil,
                         for: NSRange(location: prevPos, length: 0))
        
        // Do not alter indentation if we were at the beginning of the line and we pressed Enter
        // (if previous line is empty)
        let prevLineLength = prevLineEnd - prevLineStart - 1 // -1 for newline
        if prevLineLength <= 0 { return }
        
        // Get previous line's indentation
        let prevLine = text.substring(with: NSRange(location: prevLineStart, length: prevLineLength))
        let indentAmount = getLineIndentation(prevLine)
        
        if indentAmount > 0 {
            // Port of setLineIndent - add indentation to current line
            setLineIndentation(indentAmount)
        }
    }
    
    // Port of getLineIndent
    private func getLineIndentation(_ line: String) -> Int {
        var indent = 0
        for char in line {
            if char == " " {
                indent += 1
            } else if char == "\t" {
                indent += AppSettings.shared.tabSize
            } else {
                break
            }
        }
        return indent
    }
    
    // Port of setLineIndent
    private func setLineIndentation(_ indentAmount: Int) {
        let settings = AppSettings.shared
        
        // Build indentation string
        var indentString = ""
        if settings.replaceTabsBySpaces {
            indentString = String(repeating: " ", count: indentAmount)
        } else {
            let tabs = indentAmount / settings.tabSize
            let spaces = indentAmount % settings.tabSize
            indentString = String(repeating: "\t", count: tabs) + String(repeating: " ", count: spaces)
        }
        
        // Insert at current position
        if !indentString.isEmpty {
            self.insertText(indentString, replacementRange: self.selectedRange())
        }
    }
}