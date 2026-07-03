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
    // Substance is stored as UTF-16 code units so that CharAt/Length are O(1) index
    // operations, mirroring Scintilla's SplitVector<char> whose ValueAt is O(1)
    // (CellBuffer.cxx:845 `substance.ValueAt(position)`). A Swift String backed by UTF-8
    // has no O(1) random access by offset, so `substance.index(offsetBy:)` walks were
    // O(position); the previous representation made CharAt O(n) and setText O(chars x
    // lines). Positions/line starts are therefore UTF-16 offsets, the same coordinate
    // space AppKit's NSTextView (NSString) uses, and the same one Scintilla's line vector
    // maintains via startsUTF16 (CellBuffer.cxx:208,229,278). F10.
    private var substance: [unichar] = []
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
        self.substance = []
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
    
    /// Translation of Length() from CellBuffer.h. O(1): the count of stored UTF-16 units.
    var length: Int {
        return substance.count
    }

    /// Translation of CharAt() (CellBuffer.cxx:845 `substance.ValueAt(position)`), now
    /// O(1) by direct UTF-16 index instead of the previous O(position) String index walk.
    func charAt(_ position: Int) -> Character? {
        guard position >= 0 && position < substance.count else { return nil }
        let unit = substance[position]
        if let scalar = Unicode.Scalar(unit) {
            return Character(scalar)
        }
        // Lone UTF-16 surrogate half (one code unit of a non-BMP scalar). Return a
        // sentinel that never equals an ASCII brace so brace matching stays correct;
        // Scintilla's ValueAt likewise returns a raw code unit, not a whole character.
        return "\u{FFFD}"
    }

    /// Translation of UCharAt() for byte access. O(1) UTF-16 index; returns 0 above the
    /// single-byte range, matching the previous ASCII-only behavior for callers.
    func uCharAt(_ position: Int) -> UInt8 {
        guard position >= 0 && position < substance.count else { return 0 }
        let unit = substance[position]
        return unit <= 0xFF ? UInt8(unit) : 0
    }

    /// Translation of GetCharRange() from CellBuffer.cxx. Builds a String from the stored
    /// UTF-16 slice.
    func getCharRange(position: Int, length: Int) -> String {
        guard position >= 0 && length >= 0 && position + length <= substance.count else {
            return ""
        }
        guard length > 0 else { return "" }
        let units = Array(substance[position..<(position + length)])
        return String(utf16CodeUnits: units, count: units.count)
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
    
    /// Set text content. Stores the UTF-16 units and rebuilds the line-start vector in a
    /// SINGLE O(n) scan (see updateLineStarts), not the previous O(chars x lines)
    /// text.distance walk. Faithful to CellBuffer.cxx BasicInsertString (:872-925): here
    /// the whole buffer is the inserted text starting at position 0.
    func setText(_ newText: String) {
        substance = Array(newText.utf16)
        if hasStyles {
            style = Data(count: substance.count)
        }
        // Reset line starts, then scan once for the newlines.
        lineStarts = [0]
        updateLineStarts(from: 0, delta: substance.count, text: newText)
    }
    
    // MARK: - Modification (Translation of insert/delete methods)
    
    /// Translation of IsReadOnly() from CellBuffer.cxx line 617
    var isReadOnly: Bool {
        get { readOnly }
        set { readOnly = newValue }
    }
    
    /// Translation of BasicInsertString() from CellBuffer.cxx line 840. Inserts EXACTLY
    /// `insertLength` UTF-16 units from `s` (CellBuffer.cxx:867
    /// `substance.InsertFromArray(position, s, 0, insertLength)`), so a caller passing a
    /// length shorter than `s` inserts only that prefix, honouring the (position, s,
    /// insertLength) contract instead of ignoring insertLength and inserting all of `s`.
    private func basicInsertString(position: Int, s: String, insertLength: Int) {
        guard insertLength > 0 else { return }

        let allUnits = Array(s.utf16)
        // Insert exactly insertLength units (a prefix of s), never more than s holds.
        let units = allUnits.count <= insertLength ? allUnits : Array(allUnits.prefix(insertLength))
        guard !units.isEmpty else { return }

        // Insert the UTF-16 units into substance (CellBuffer.cxx:867
        // substance.InsertFromArray).
        let clampedPos = min(position, substance.count)
        substance.insert(contentsOf: units, at: clampedPos)

        // Update line starts (CellBuffer.cxx:872-925: shift lines after, scan inserted
        // text once for line ends). Scan exactly the inserted units, not all of `s`.
        let insertedText = units.count == allUnits.count ? s : String(utf16CodeUnits: units, count: units.count)
        updateLineStarts(from: clampedPos, delta: units.count, text: insertedText)

        // Handle styles if needed
        if hasStyles {
            let styleBytes = Data(count: units.count)
            style.insert(contentsOf: styleBytes, at: min(clampedPos, style.count))
        }
    }
    
    /// Translation of BasicDeleteChars() from CellBuffer.cxx line 786
    private func basicDeleteChars(position: Int, deleteLength: Int) {
        guard deleteLength > 0 && position >= 0 && position + deleteLength <= substance.count else {
            return
        }
        
        // Get text being deleted for line tracking
        let deletedText = getCharRange(position: position, length: deleteLength)

        // Delete the UTF-16 units from substance
        substance.removeSubrange(position..<(position + deleteLength))

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

        // Length is measured in UTF-16 units to match the substance coordinate space, and
        // is clamped to what `s` actually holds so the recorded undo lenData equals the
        // number of units actually inserted (basicInsertString inserts exactly `length`).
        let available = s.utf16.count
        let length = min(insertLength ?? available, available)
        guard length > 0 else { return }

        // Record undo action if collecting
        if collectingUndo {
            let action = Action(
                at: .insert,
                mayCoalesce: false,
                position: position,
                data: s,
                lenData: length
            )
            undoHistory.append(action)
            // Clear redo stack on new action
            redoHistory.removeAll()
        }

        // Perform the insertion of exactly `length` units.
        basicInsertString(position: position, s: s, insertLength: length)
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

    /// Translation of SetUndoCollection()/IsCollectingUndo() from CellBuffer.cxx line
    /// 1112-1120 (`collectingUndo = collectUndo; uh->DropUndoSequence();`). Turning
    /// collection OFF also drops any accumulated history, mirroring Scintilla dropping the
    /// pending undo sequence, so a buffer used purely as a text/line mirror (undo owned
    /// elsewhere) never accumulates an unbounded undoHistory.
    var isCollectingUndo: Bool {
        get { collectingUndo }
        set {
            collectingUndo = newValue
            if !newValue {
                undoHistory.removeAll()
                redoHistory.removeAll()
                savePoint = 0
            }
        }
    }

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
            basicInsertString(position: action.position, s: action.data, insertLength: action.lenData)
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
            basicInsertString(position: action.position, s: action.data, insertLength: action.lenData)
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

        // Handle new lines in inserted text with a SINGLE forward scan over the inserted
        // UTF-16 units, tracking a running index `i` and recording (position + i) + 1 for
        // each '\n' (CellBuffer.cxx:783,914-925). This replaces the previous
        // text.distance(from: startIndex, to: ...) call, which re-walked the string from
        // the start for every newline and made setText O(chars x lines). '\n' is always a
        // single UTF-16 unit (0x000A), and iterating text.utf16 visits units in the same
        // order they were stored into substance, so `i` matches the substance offset.
        if delta > 0 {
            // Point all the lines after the change point further along in the buffer
            // (CellBuffer.cxx:874 `plv->InsertText(lineInsert-1, insertLength)`).
            for i in (lineAffected + 1)..<lineStarts.count {
                lineStarts[i] += delta
            }

            var newLinePositions: [Int] = []
            var i = 0
            for unit in text.utf16 {
                if unit == 0x000A {  // '\n'
                    newLinePositions.append(position + i + 1)
                }
                i += 1
            }

            // Insert new line starts
            if !newLinePositions.isEmpty {
                lineStarts.insert(contentsOf: newLinePositions, at: lineAffected + 1)
            }
        }
        // Handle deletion. Faithful to BasicDeleteChars (CellBuffer.cxx:1011-1075): the
        // later line starts are shifted back by deleteLength (`plv->InsertText(lineRemove-1,
        // -(deleteLength))`, :1028) and every line whose start fell inside the deleted span
        // is removed (the RemoveLine calls at :1070-1081 for line ends within the span).
        // The removal MUST happen on the UNSHIFTED line starts: the previous code shifted
        // all later starts first and then compared them against the unshifted bounds, so it
        // removed the wrong entries.
        else if delta < 0 {
            let end = position - delta      // == position + deleteLength
            // Remove starts that began strictly inside the deleted span (position, end].
            lineStarts.removeAll { $0 > position && $0 <= end }
            // Shift the surviving later starts back by deleteLength (delta < 0).
            for i in lineStarts.indices where lineStarts[i] > position {
                lineStarts[i] += delta
            }
        }
    }
    
    // MARK: - Translation of ContainsLineEnd() from CellBuffer.cxx line 522
    func containsLineEnd(_ s: String) -> Bool {
        return s.contains("\r") || s.contains("\n")
    }
}