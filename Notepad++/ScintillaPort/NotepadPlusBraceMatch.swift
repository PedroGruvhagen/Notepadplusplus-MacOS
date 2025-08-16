//
//  NotepadPlusBraceMatch.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Notepad++ brace matching functions
//  Source: notepad-plus-plus-reference/PowerEditor/src/Notepad_plus.cpp:2960-3024
//  This is NOT a reimplementation - it's a direct translation
//

import AppKit

// MARK: - Extension to NSTextView for Notepad++ brace matching
extension NSTextView {
    
    // MARK: - Translation of Notepad_plus::findMatchingBracePos (lines 2960-2990)
    func findMatchingBracePos() -> (braceAtCaret: Int, braceOpposite: Int) {
        // Line 2962: Get current caret position
        let caretPos = getCurrentPos()  // SCI_GETCURRENTPOS
        
        // Line 2963-2964: Initialize results
        var braceAtCaret: Int = -1
        var braceOpposite: Int = -1
        
        // Line 2965: Character before caret
        var charBefore: Character? = nil
        
        // Line 2967: Get document length
        let lengthDoc = getLength()  // SCI_GETLENGTH
        
        // Line 2969-2972: Get character before caret if possible
        if lengthDoc > 0 && caretPos > 0 {
            charBefore = getCharAt(caretPos - 1)  // SCI_GETCHARAT
        }
        
        // Line 2974-2977: Priority goes to character before caret
        if let char = charBefore, "[](){}".contains(char) {
            braceAtCaret = caretPos - 1
        }
        
        // Line 2979-2987: No brace found so check other side
        if lengthDoc > 0 && braceAtCaret < 0 {
            if let charAfter = getCharAt(caretPos) {  // SCI_GETCHARAT
                if "[](){}".contains(charAfter) {
                    braceAtCaret = caretPos
                }
            }
        }
        
        // Line 2988-2989: Find matching brace if we found one
        if braceAtCaret >= 0 {
            // Call braceMatch from NSTextView+ScintillaAPI which uses the translated Document::BraceMatch
            braceOpposite = self.braceMatch(braceAtCaret)  // SCI_BRACEMATCH
        }
        
        return (braceAtCaret, braceOpposite)
    }
    
    // MARK: - Translation of Notepad_plus::braceMatch (lines 2993-3024)
    @discardableResult
    func braceMatch() -> Bool {
        // Line 2995-2997: Check if buffer allows brace matching
        guard let currentBuf = currentBuffer,
              currentBuf.allowBraceMatch() else {
            return false
        }
        
        // Line 2999-3001: Find matching brace positions
        let (braceAtCaret, braceOpposite) = findMatchingBracePos()
        
        // Line 3003-3007: Handle unmatched brace
        if braceAtCaret != -1 && braceOpposite == -1 {
            braceBadLight(braceAtCaret)  // SCI_BRACEBADLIGHT
            setHighlightGuide(0)  // SCI_SETHIGHLIGHTGUIDE
        }
        // Line 3008-3018: Handle matched braces
        else {
            braceHighlight(braceAtCaret, braceOpposite)  // SCI_BRACEHIGHLIGHT
            
            // Line 3012-3017: Set highlight guide if indent guides shown
            if isShownIndentGuide() {
                let columnAtCaret = getColumn(braceAtCaret)  // SCI_GETCOLUMN
                let columnOpposite = getColumn(braceOpposite)  // SCI_GETCOLUMN
                setHighlightGuide(min(columnAtCaret, columnOpposite))  // SCI_SETHIGHLIGHTGUIDE
            }
        }
        
        // Line 3020-3022: Enable/disable menu commands
        let enable = (braceAtCaret != -1) && (braceOpposite != -1)
        enableCommand(.searchGotoMatchingBrace, enable)
        enableCommand(.searchSelectMatchingBraces, enable)
        
        // Line 3023: Return whether a brace was found
        return braceAtCaret != -1
    }
    
}