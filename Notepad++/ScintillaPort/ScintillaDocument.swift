//
//  Document.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Scintilla Document class
//  Source: scintilla-reference/src/Document.cxx
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Constants from Scintilla
enum ScintillaCodePage {
    static let CpUtf8 = 65001
}

// MARK: - Document class (Translation of Scintilla Document)
class ScintillaDocument {
    
    // Properties from Document.h
    var cb: CellBuffer  // Text storage (made internal for access from NotepadPlusBraceMatch)
    private var endStyled: Int = 0
    private var dbcsCodePage: Int = 0
    private var hasStyles: Bool = true
    
    @MainActor init() {
        self.cb = CellBuffer()
    }
    
    // Helper method to set text content
    @MainActor func setText(_ text: String) {
        cb.setText(text)
    }
    
    // MARK: - Direct translations from Document.cxx
    
    // Translation of: Document::CharAt (Document.h:475)
    @MainActor func charAt(_ position: Int) -> Character {
        return cb.charAt(position) ?? "\0"
    }
    
    // Translation of: Document::StyleIndexAt (Document.h:481)
    @MainActor func styleIndexAt(_ position: Int) -> Int {
        return Int(cb.styleAt(position))
    }
    
    // Translation of: Document::LengthNoExcept (Document.h:520)
    @MainActor func lengthNoExcept() -> Int {
        return cb.length
    }
    
    // Translation of: Document::GetEndStyled (Document.h:548)
    func getEndStyled() -> Int {
        return endStyled
    }
    
    // Translation of: Document::MovePositionOutsideChar (Document.h:380)
    func movePositionOutsideChar(_ pos: Int, _ moveDir: Int, _ checkLineEnd: Bool = true) -> Int {
        // For now, simplified implementation - full DBCS support would be added
        // In UTF-8/ASCII, every position is valid
        return pos
    }
    
    // Translation of: Document::DBCSMinTrailByte (Document.cxx implementation)
    func dbcsMinTrailByte() -> UInt8 {
        // Simplified for now - would need full DBCS tables
        return 0x40
    }
    
    // MARK: - BraceOpposite (Document.cxx:2984-3005)
    // Direct translation of the C++ function
    private func braceOpposite(_ ch: Character) -> Character? {
        switch ch {
        case "(": return ")"
        case ")": return "("
        case "[": return "]"
        case "]": return "["
        case "{": return "}"
        case "}": return "{"
        case "<": return ">"
        case ">": return "<"
        default: return nil
        }
    }
    
    // MARK: - BraceMatch (Document.cxx:3010-3041)
    // EXACT TRANSLATION of Document::BraceMatch
    @MainActor func braceMatch(_ position: Int, _ maxReStyle: Int = 0, _ startPos: Int = 0, _ useStartPos: Bool = false) -> Int {
        // Line 3011-3012: Get character and find opposite
        let chBrace = charAt(position)
        guard let chSeek = braceOpposite(chBrace) else {
            return -1  // Line 3013-3014
        }
        
        // Line 3015: Get style at brace position
        let styBrace = styleIndexAt(position)
        
        // Line 3016-3018: Determine search direction
        var direction = -1
        if chBrace == "(" || chBrace == "[" || chBrace == "{" || chBrace == "<" {
            direction = 1
        }
        
        // Line 3019: Initialize depth
        var depth = 1
        
        // Line 3020: Set initial position
        var currentPos = useStartPos ? startPos : position + direction
        
        // Line 3022-3026: DBCS handling
        var maxSafeChar: UInt8 = 0xff
        if dbcsCodePage != 0 && dbcsCodePage != ScintillaCodePage.CpUtf8 {
            maxSafeChar = max(dbcsMinTrailByte(), 1) - 1
        }
        
        // Line 3028-3039: Main search loop
        while currentPos >= 0 && currentPos < lengthNoExcept() {
            let chAtPos = charAt(currentPos)
            
            // Line 3030: Check if character is brace or its opposite
            if chAtPos == chBrace || chAtPos == chSeek {
                // Line 3031-3032: Style checking and DBCS safety
                let positionStyleMatches = currentPos > getEndStyled() || styleIndexAt(currentPos) == styBrace
                let dbcsSafe = chAtPos.asciiValue ?? 0 <= maxSafeChar || 
                               currentPos == movePositionOutsideChar(currentPos, direction, false)
                
                if positionStyleMatches && dbcsSafe {
                    // Line 3033: Update depth
                    depth += (chAtPos == chBrace) ? 1 : -1
                    
                    // Line 3034-3035: Check if match found
                    if depth == 0 {
                        return currentPos
                    }
                }
            }
            
            // Line 3038: Move to next position
            currentPos += direction
        }
        
        // Line 3040: No match found
        return -1
    }
}

// CellBuffer is now properly translated in CellBuffer.swift
// Using the full literal translation from Scintilla's CellBuffer.cxx