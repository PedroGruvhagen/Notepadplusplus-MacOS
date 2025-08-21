//
//  CellBuffer.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Scintilla's CellBuffer from CellBuffer.cxx
//  Manages the text of the document with undo support
//

import Foundation

/// Translation of ActionType enum from CellBuffer.h line 31
enum ActionType: UInt8 {
    case insert
    case remove
    case container
}

/// Translation of Action struct from CellBuffer.h line 36-42
struct Action {
    var at: ActionType = .insert
    var mayCoalesce: Bool = false
    var position: Int = 0
    var data: String = ""
    var lenData: Int = 0
}

/// Translation of SplitView struct from CellBuffer.h line 44-67
struct SplitView {
    let segment1: String
    let length1: Int
    let segment2: String
    let length: Int
    
    func charAt(position: Int) -> Character? {
        if position < length1 {
            let index = segment1.index(segment1.startIndex, offsetBy: position)
            return segment1[index]
        }
        if position < length {
            let index = segment2.index(segment2.startIndex, offsetBy: position - length1)
            return segment2[index]
        }
        return nil
    }
}

/// Translation of CellBuffer class from CellBuffer.h line 75 and CellBuffer.cxx
/// Based on "Data Structures in a Bit-Mapped Text Editor" by Wilfred J. Hansen
@MainActor
class CellBuffer {
    // Translation of member variables from CellBuffer.h line 76-91
    private var hasStyles: Bool = false
    private var largeDocument: Bool = false
    private var substance: String = ""  // Simplified: using String instead of SplitVector
    private var style: Data = Data()    // Simplified: using Data for style bytes
    private var readOnly: Bool = false
    private var utf8Substance: Bool = true
    private var utf8LineEnds: EOLType = .unix
    
    private var collectingUndo: Bool = true
    private var undoHistory: [Action] = []
    private var redoHistory: [Action] = []
    private var savePoint: Int = 0
    private var currentAction: Int = 0
    
    // Line management - simplified version of ILineVector
    private var lineStarts: [Int] = [0]  // Position of start of each line
    
    // MARK: - Initialization
    
    /// Translation of CellBuffer constructor from CellBuffer.cxx line 407-418
    init(initialLength: Int = 0, hasStyles: Bool = false) {
        self.hasStyles = hasStyles
        self.largeDocument = initialLength > Int32.max
        self.substance = ""
        if hasStyles {
            self.style = Data(count: initialLength)
        }
    }
    
    // MARK: - Line Management (Translation of ILineVector interface)
    
    /// Translation of Lines() from CellBuffer.cxx line 561
    var lines: Int {
        return lineStarts.count
    }
    
    /// Translation of LineStart() from CellBuffer.cxx line 569
    func lineStart(_ line: Int) -> Int {
        if line < 0 {
            return 0
        } else if line >= lines {
            return length
        } else {
            return lineStarts[line]
        }
    }
    
    /// Translation of LineEnd() from CellBuffer.cxx line 578
    func lineEnd(_ line: Int) -> Int {
        if line >= lines - 1 {
            return lineStart(line + 1)
        } else {
            var position = lineStart(line + 1)
            position -= 1  // Back over CR or LF
            // When line terminator is CR+LF, may need to go back one more
            if position > lineStart(line) && charAt(position - 1) == "\r" {
                position -= 1
            }
            return position
        }
    }
    
    /// Translation of LineFromPosition() from CellBuffer.cxx line 605
    func lineFromPosition(_ pos: Int) -> Int {
        // Binary search through lineStarts
        var lower = 0
        var upper = lineStarts.count - 1
        while upper > lower {
            let mid = (upper + lower + 1) / 2
            if lineStarts[mid] > pos {
                upper = mid - 1
            } else {
                lower = mid
            }
        }
        return lower
    }
    
    // MARK: - Content Access (Translation of character access methods)
    
    /// Translation of Length() from CellBuffer.h
    var length: Int {
        return substance.count
    }
    
    /// Translation of CharAt() - simplified version
    func charAt(_ position: Int) -> Character? {
        guard position >= 0 && position < substance.count else { return nil }
        let index = substance.index(substance.startIndex, offsetBy: position)
        return substance[index]
    }
    
    /// Translation of UCharAt() for byte access
    func uCharAt(_ position: Int) -> UInt8 {
        guard position >= 0 && position < substance.count else { return 0 }
        let index = substance.index(substance.startIndex, offsetBy: position)
        return substance[index].asciiValue ?? 0
    }
    
    /// Translation of GetCharRange() from CellBuffer.cxx
    func getCharRange(position: Int, length: Int) -> String {
        guard position >= 0 && position + length <= substance.count else {
            return ""
        }
        let startIndex = substance.index(substance.startIndex, offsetBy: position)
        let endIndex = substance.index(startIndex, offsetBy: length)
        return String(substance[startIndex..<endIndex])
    }
    
    /// Translation of StyleAt()
    func styleAt(_ position: Int) -> UInt8 {
        guard hasStyles && position >= 0 && position < style.count else {
            return 0
        }
        return style[position]
    }
    
    /// Set style at position
    func setStyleAt(_ position: Int, _ styleValue: UInt8) {
        guard hasStyles && position >= 0 && position < style.count else { return }
        style[position] = styleValue
    }
    
    /// Set text content
    func setText(_ newText: String) {
        substance = newText
        if hasStyles {
            style = Data(repeating: 0, count: newText.count)
        }
        // Reset line starts
        lineStarts = [0]
        updateLineStarts(from: 0, delta: newText.count, text: newText)
    }
    
    // MARK: - Modification (Translation of insert/delete methods)
    
    /// Translation of IsReadOnly() from CellBuffer.cxx line 617
    var isReadOnly: Bool {
        get { readOnly }
        set { readOnly = newValue }
    }
    
    /// Translation of BasicInsertString() from CellBuffer.cxx line 752
    private func basicInsertString(position: Int, s: String) {
        let insertLength = s.count
        guard insertLength > 0 else { return }
        
        // Insert into substance
        let index = substance.index(substance.startIndex, offsetBy: min(position, substance.count))
        substance.insert(contentsOf: s, at: index)
        
        // Update line starts
        updateLineStarts(from: position, delta: insertLength, text: s)
        
        // Handle styles if needed
        if hasStyles {
            let styleBytes = Data(repeating: 0, count: insertLength)
            style.insert(contentsOf: styleBytes, at: min(position, style.count))
        }
    }
    
    /// Translation of BasicDeleteChars() from CellBuffer.cxx line 786
    private func basicDeleteChars(position: Int, deleteLength: Int) {
        guard deleteLength > 0 && position >= 0 && position + deleteLength <= substance.count else {
            return
        }
        
        // Get text being deleted for line tracking
        let deletedText = getCharRange(position: position, length: deleteLength)
        
        // Delete from substance
        let startIndex = substance.index(substance.startIndex, offsetBy: position)
        let endIndex = substance.index(startIndex, offsetBy: deleteLength)
        substance.removeSubrange(startIndex..<endIndex)
        
        // Update line starts
        updateLineStarts(from: position, delta: -deleteLength, text: deletedText)
        
        // Handle styles if needed
        if hasStyles && position < style.count {
            let endPos = min(position + deleteLength, style.count)
            style.removeSubrange(position..<endPos)
        }
    }
    
    /// Translation of InsertString() with undo from CellBuffer.cxx line 942
    func insertString(position: Int, s: String, insertLength: Int? = nil) {
        guard !readOnly else { return }
        
        let length = insertLength ?? s.count
        guard length > 0 else { return }
        
        // Record undo action if collecting
        if collectingUndo {
            let action = Action(
                at: .insert,
                mayCoalesce: false,
                position: position,
                data: String(s.prefix(length)),
                lenData: length
            )
            undoHistory.append(action)
            // Clear redo stack on new action
            redoHistory.removeAll()
        }
        
        // Perform the insertion
        basicInsertString(position: position, s: String(s.prefix(length)))
    }
    
    /// Translation of DeleteChars() with undo from CellBuffer.cxx line 982
    func deleteChars(position: Int, deleteLength: Int) {
        guard !readOnly && deleteLength > 0 else { return }
        
        // Record undo action if collecting
        if collectingUndo {
            let deletedText = getCharRange(position: position, length: deleteLength)
            let action = Action(
                at: .remove,
                mayCoalesce: false,
                position: position,
                data: deletedText,
                lenData: deleteLength
            )
            undoHistory.append(action)
            // Clear redo stack on new action
            redoHistory.removeAll()
        }
        
        // Perform the deletion
        basicDeleteChars(position: position, deleteLength: deleteLength)
    }
    
    // MARK: - Undo/Redo (Simplified translation of undo system)
    
    /// Translation of SetSavePoint() from CellBuffer.cxx line 633
    func setSavePoint() {
        savePoint = undoHistory.count
    }
    
    /// Translation of IsSavePoint() from CellBuffer.cxx line 640
    func isSavePoint() -> Bool {
        return undoHistory.count == savePoint
    }
    
    /// Translation of CanUndo() from CellBuffer.cxx line 1022
    func canUndo() -> Bool {
        return !undoHistory.isEmpty
    }
    
    /// Translation of CanRedo() from CellBuffer.cxx line 1026
    func canRedo() -> Bool {
        return !redoHistory.isEmpty
    }
    
    /// Simplified undo implementation
    func undo() {
        guard let action = undoHistory.popLast() else { return }
        
        collectingUndo = false
        switch action.at {
        case .insert:
            basicDeleteChars(position: action.position, deleteLength: action.lenData)
        case .remove:
            basicInsertString(position: action.position, s: action.data)
        case .container:
            break  // Not implemented in this simplified version
        }
        collectingUndo = true
        
        redoHistory.append(action)
    }
    
    /// Simplified redo implementation
    func redo() {
        guard let action = redoHistory.popLast() else { return }
        
        collectingUndo = false
        switch action.at {
        case .insert:
            basicInsertString(position: action.position, s: action.data)
        case .remove:
            basicDeleteChars(position: action.position, deleteLength: action.lenData)
        case .container:
            break  // Not implemented in this simplified version
        }
        collectingUndo = true
        
        undoHistory.append(action)
    }
    
    // MARK: - Helper Methods
    
    private func updateLineStarts(from position: Int, delta: Int, text: String) {
        // Find which line is affected
        let lineAffected = lineFromPosition(position)
        
        // Update positions of lines after the change
        for i in (lineAffected + 1)..<lineStarts.count {
            lineStarts[i] += delta
        }
        
        // Handle new lines in inserted text
        if delta > 0 {
            var newLinePositions: [Int] = []
            var searchStart = text.startIndex
            while let range = text[searchStart...].range(of: "\n") {
                let offset = text.distance(from: text.startIndex, to: range.lowerBound) + 1
                newLinePositions.append(position + offset)
                searchStart = range.upperBound
            }
            
            // Insert new line starts
            if !newLinePositions.isEmpty {
                lineStarts.insert(contentsOf: newLinePositions, at: lineAffected + 1)
            }
        }
        // Handle deleted lines
        else if delta < 0 {
            var linesToRemove: [Int] = []
            for (index, lineStart) in lineStarts.enumerated() {
                if lineStart > position && lineStart <= position - delta {
                    linesToRemove.append(index)
                }
            }
            for index in linesToRemove.reversed() {
                lineStarts.remove(at: index)
            }
        }
    }
    
    // MARK: - Translation of ContainsLineEnd() from CellBuffer.cxx line 522
    func containsLineEnd(_ s: String) -> Bool {
        return s.contains("\r") || s.contains("\n")
    }
}