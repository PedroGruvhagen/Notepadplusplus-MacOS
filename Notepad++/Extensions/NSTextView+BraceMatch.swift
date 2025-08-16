//
//  NSTextView+BraceMatch.swift
//  Notepad++
//
//  DIRECT TRANSLATION of Notepad++ brace matching functionality
//  Translated from: PowerEditor/src/Notepad_plus.cpp lines 2960-3024
//

import AppKit

extension NSTextView {
    
    // MARK: - Direct Translation from Notepad_plus.cpp
    
    // Translation of: void Notepad_plus::findMatchingBracePos(intptr_t& braceAtCaret, intptr_t& braceOpposite)
    // Original location: Notepad_plus.cpp line 2960-2990
    func findMatchingBracePos(_ braceAtCaret: inout Int, _ braceOpposite: inout Int) {
        // Line 2962: intptr_t caretPos = _pEditView->execute(SCI_GETCURRENTPOS);
        let caretPos = self.getCurrentPos()
        
        // Line 2963-2964: Initialize to -1
        braceAtCaret = -1
        braceOpposite = -1
        
        // Line 2965: wchar_t charBefore = '\0';
        var charBefore: Character? = nil
        
        // Line 2967: intptr_t lengthDoc = _pEditView->execute(SCI_GETLENGTH);
        let lengthDoc = self.getLength()
        
        // Line 2969-2972: Get character before caret
        if lengthDoc > 0 && caretPos > 0 {
            // Line 2971: charBefore = wchar_t(_pEditView->execute(SCI_GETCHARAT, caretPos - 1, 0));
            charBefore = self.getCharAt(caretPos - 1)
        }
        
        // Line 2973-2977: Priority goes to character before caret
        // Line 2974: if (charBefore && wcschr(L"[](){}", charBefore))
        if let char = charBefore, "[](){}".contains(char) {
            // Line 2976: braceAtCaret = caretPos - 1;
            braceAtCaret = caretPos - 1
        }
        
        // Line 2979-2987: No brace found so check other side
        if lengthDoc > 0 && braceAtCaret < 0 {
            // Line 2982: wchar_t charAfter = wchar_t(_pEditView->execute(SCI_GETCHARAT, caretPos, 0));
            let charAfter = self.getCharAt(caretPos)
            
            // Line 2983: if (charAfter && wcschr(L"[](){}", charAfter))
            if let char = charAfter, "[](){}".contains(char) {
                // Line 2985: braceAtCaret = caretPos;
                braceAtCaret = caretPos
            }
        }
        
        // Line 2988-2989: Find matching brace
        if braceAtCaret >= 0 {
            // Line 2989: braceOpposite = _pEditView->execute(SCI_BRACEMATCH, braceAtCaret, 0);
            braceOpposite = self.braceMatch(braceAtCaret)
        }
    }
    
    // Translation of: bool Notepad_plus::braceMatch()
    // Original location: Notepad_plus.cpp line 2993-3024
    @discardableResult
    func performBraceMatch() -> Bool {
        // Line 2995: Buffer* currentBuf = _pEditView->getCurrentBuffer();
        guard let currentBuf = self.currentBuffer else { return false }
        
        // Line 2996: if (!currentBuf->allowBraceMach())
        if !currentBuf.allowBraceMatch() {
            // Line 2997: return false;
            return false
        }
        
        // Line 2999-3000: Initialize brace positions
        var braceAtCaret: Int = -1
        var braceOpposite: Int = -1
        
        // Line 3001: findMatchingBracePos(braceAtCaret, braceOpposite);
        findMatchingBracePos(&braceAtCaret, &braceOpposite)
        
        // Line 3003-3007: Handle unmatched brace
        if braceAtCaret != -1 && braceOpposite == -1 {
            // Line 3005: _pEditView->execute(SCI_BRACEBADLIGHT, braceAtCaret);
            self.braceBadLight(braceAtCaret)
            // Line 3006: _pEditView->execute(SCI_SETHIGHLIGHTGUIDE, 0);
            self.setHighlightGuide(0)
        }
        // Line 3008-3018: Handle matched braces
        else {
            // Line 3010: _pEditView->execute(SCI_BRACEHIGHLIGHT, braceAtCaret, braceOpposite);
            self.braceHighlight(braceAtCaret, braceOpposite)
            
            // Line 3012: if (_pEditView->isShownIndentGuide())
            if self.isShownIndentGuide() {
                // Line 3014: intptr_t columnAtCaret = _pEditView->execute(SCI_GETCOLUMN, braceAtCaret);
                let columnAtCaret = self.getColumn(braceAtCaret)
                // Line 3015: intptr_t columnOpposite = _pEditView->execute(SCI_GETCOLUMN, braceOpposite);
                let columnOpposite = self.getColumn(braceOpposite)
                // Line 3016: _pEditView->execute(SCI_SETHIGHLIGHTGUIDE, (columnAtCaret < columnOpposite)?columnAtCaret:columnOpposite);
                self.setHighlightGuide(columnAtCaret < columnOpposite ? columnAtCaret : columnOpposite)
            }
        }
        
        // Line 3020: const bool enable = (braceAtCaret != -1) && (braceOpposite != -1);
        let enable = (braceAtCaret != -1) && (braceOpposite != -1)
        
        // Line 3021: enableCommand(IDM_SEARCH_GOTOMATCHINGBRACE, enable, MENU | TOOLBAR);
        self.enableCommand(.searchGotoMatchingBrace, enable)
        // Line 3022: enableCommand(IDM_SEARCH_SELECTMATCHINGBRACES, enable, MENU);
        self.enableCommand(.searchSelectMatchingBraces, enable)
        
        // Line 3023: return (braceAtCaret != -1);
        return braceAtCaret != -1
    }
}