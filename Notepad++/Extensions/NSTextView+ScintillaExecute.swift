//
//  NSTextView+ScintillaExecute.swift
//  Notepad++
//
//  DIRECT TRANSLATION of ScintillaEditView::execute method
//  This provides the exact API that Notepad++ uses to call Scintilla
//

import AppKit

extension NSTextView {
    
    // Translation of: ScintillaEditView::execute
    // This is how Notepad++ calls all Scintilla APIs
    @discardableResult
    func execute(_ message: Int, _ wParam: Int = 0, _ lParam: Any? = nil) -> Int {
        
        // Map Scintilla message codes to our translated functions
        switch message {
            
        // MARK: - Text Modification
        case ScintillaConstants.SCI_REPLACESEL:
            if let text = lParam as? String {
                replaceSel(text)
            }
            return 0
            
        case ScintillaConstants.SCI_INSERTTEXT:
            if let text = lParam as? String {
                insertText(at: wParam, text: text)
            }
            return 0
            
        case ScintillaConstants.SCI_DELETERANGE:
            if let length = lParam as? Int {
                deleteRange(start: wParam, length: length)
            }
            return 0
            
        case ScintillaConstants.SCI_CLEARALL:
            clearAll()
            return 0
            
        case ScintillaConstants.SCI_ADDTEXT:
            if let text = lParam as? String {
                addText(text)
            }
            return 0
            
        // MARK: - Undo/Redo
        case ScintillaConstants.SCI_UNDO:
            undo()
            return 0
            
        case ScintillaConstants.SCI_REDO:
            redo()
            return 0
            
        case ScintillaConstants.SCI_CANUNDO:
            return canUndo() ? 1 : 0
            
        case ScintillaConstants.SCI_CANREDO:
            return canRedo() ? 1 : 0
            
        case ScintillaConstants.SCI_BEGINUNDOACTION:
            beginUndoAction()
            return 0
            
        case ScintillaConstants.SCI_ENDUNDOACTION:
            endUndoAction()
            return 0
            
        // MARK: - Selection
        case ScintillaConstants.SCI_SETSEL:
            if let end = lParam as? Int {
                setSel(wParam, end)
            }
            return 0
            
        case ScintillaConstants.SCI_SELECTALL:
            selectAll()
            return 0
            
        case ScintillaConstants.SCI_GOTOPOS:
            gotoPos(wParam)
            return 0
            
        case ScintillaConstants.SCI_GOTOLINE:
            gotoLine(wParam)
            return 0
            
        case ScintillaConstants.SCI_SETCURRENTPOS:
            setCurrentPos(wParam)
            return 0
            
        case ScintillaConstants.SCI_SETANCHOR:
            setAnchor(wParam)
            return 0
            
        // MARK: - Position/Navigation
        case ScintillaConstants.SCI_GETCURRENTPOS:
            return getCurrentPos()
            
        case ScintillaConstants.SCI_GETANCHOR:
            return getAnchor()
            
        case ScintillaConstants.SCI_GETLENGTH:
            return getLength()
            
        case ScintillaConstants.SCI_GETCHARAT:
            if let char = getCharAt(wParam) {
                return Int(char.asciiValue ?? 0)
            }
            return 0
            
        case ScintillaConstants.SCI_GETCOLUMN:
            return getColumn(wParam)
            
        case ScintillaConstants.SCI_LINEFROMPOSITION:
            return lineFromPosition(wParam)
            
        case ScintillaConstants.SCI_GETLINEINDENT:
            return getLineIndent(wParam)
            
        // MARK: - Brace Matching
        case ScintillaConstants.SCI_BRACEMATCH:
            return braceMatch(wParam)
            
        case ScintillaConstants.SCI_BRACEHIGHLIGHT:
            if let pos2 = lParam as? Int {
                braceHighlight(wParam, pos2)
            }
            return 0
            
        case ScintillaConstants.SCI_BRACEBADLIGHT:
            braceBadLight(wParam)
            return 0
            
        case ScintillaConstants.SCI_SETHIGHLIGHTGUIDE:
            setHighlightGuide(wParam)
            return 0
            
        default:
            // For unimplemented messages, log and return 0
            print("WARNING: Unimplemented Scintilla message: \(message)")
            return 0
        }
    }
    
    // Convenience overload for string lParam (matching Notepad++ usage)
    @discardableResult
    func execute(_ message: Int, _ wParam: Int, _ lParam: String) -> Int {
        return execute(message, wParam, lParam as Any)
    }
    
    // Convenience overload for integer lParam
    @discardableResult
    func execute(_ message: Int, _ wParam: Int, _ lParam: Int) -> Int {
        return execute(message, wParam, lParam as Any)
    }
}

// MARK: - Extended Scintilla Constants
extension ScintillaConstants {
    // Text modification
    static let SCI_ADDTEXT = 2001
    static let SCI_INSERTTEXT = 2003
    static let SCI_CLEARALL = 2004
    static let SCI_DELETERANGE = 2645
    static let SCI_REPLACESEL = 2170
    
    // Undo/Redo
    static let SCI_UNDO = 2176
    static let SCI_REDO = 2011
    static let SCI_CANUNDO = 2174
    static let SCI_CANREDO = 2016
    static let SCI_BEGINUNDOACTION = 2078
    static let SCI_ENDUNDOACTION = 2079
    
    // Selection
    static let SCI_SETSEL = 2160
    static let SCI_GETSEL = 2143
    static let SCI_SELECTALL = 2013
    static let SCI_GOTOPOS = 2025
    static let SCI_GOTOLINE = 2024
    static let SCI_SETCURRENTPOS = 2141
    static let SCI_SETANCHOR = 2026
    static let SCI_GETANCHOR = 2009
}