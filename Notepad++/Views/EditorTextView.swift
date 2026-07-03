//
//  EditorTextView.swift
//  Notepad++
//
//  NSTextView subclass for the live editor. Adds the two things a plain NSTextView cannot express
//  and that had persisted settings with no effect (F55 caret, F56 indent guides):
//
//  - Caret WIDTH: Notepad++ applies SCI_SETCARETWIDTH from NppGUI._caretWidth (NppBigSwitch.cpp:1746);
//    AppKit has no caret-width property, so we widen the insertion-point rect in
//    drawInsertionPoint(in:color:turnedOn:).
//  - Caret BLINK: Notepad++ applies SCI_SETCARETPERIOD (NppBigSwitch.cpp:1896); a value of 0 means a
//    steady (non-blinking) caret. AppKit exposes no blink period, but a steady caret is achievable by
//    never restarting the blink timer (updateInsertionPointStateAndRestartTimer). The exact non-zero
//    period is not settable through public AppKit API (see .deferred/notepadpp/2026-07-03-caret-blink-period.md).
//  - Indent guides: Scintilla draws a vertical guide at every indent stop (EditView.cxx:2099
//    DrawIndentGuide, gated by SCI_SETINDENTATIONGUIDES / ScintillaViewParams._indentGuideLineShow).
//    We draw the same faint verticals over the leading indentation of each visible line.
//

import AppKit

final class EditorTextView: NSTextView {
    // Effective caret pixel width (EditorSettingsView slider is 1...5 px). 1 = default line caret.
    var caretPixelWidth: CGFloat = 1

    // True when the caret must not blink (Notepad++ caret period 0 = steady). Applied by not
    // restarting AppKit's blink timer, so the caret stays solid without ghosting on caret moves.
    var caretSteady: Bool = false

    // Indent-guide drawing (F56).
    var showIndentGuidesFlag: Bool = true
    var indentTabSize: Int = 4

    // MARK: - Caret width + steady blink (F55)

    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        var caretRect = rect
        if caretPixelWidth > 1 {
            caretRect.size.width = caretPixelWidth
        }
        super.drawInsertionPoint(in: caretRect, color: color, turnedOn: flag)
    }

    override func updateInsertionPointStateAndRestartTimer(_ restartFlag: Bool) {
        // caretSteady: never (re)start the blink timer, so the caret updates position on moves but
        // never blinks off. Otherwise honour AppKit's default blink.
        super.updateInsertionPointStateAndRestartTimer(caretSteady ? false : restartFlag)
    }

    // MARK: - Indent guides (F56)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if showIndentGuidesFlag {
            drawIndentGuides(in: dirtyRect)
        }
    }

    private func drawIndentGuides(in dirtyRect: NSRect) {
        guard let layoutManager = layoutManager,
              let container = textContainer,
              let font = font else { return }
        let charWidth = font.maximumAdvancement.width
        let indentColumns = max(1, indentTabSize)
        guard charWidth > 0 else { return }

        let origin = textContainerOrigin
        let nsText = string as NSString
        let glyphRange = layoutManager.glyphRange(forBoundingRect: dirtyRect, in: container)
        NSColor.tertiaryLabelColor.withAlphaComponent(0.6).setStroke()

        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { fragmentRect, _, _, gRange, _ in
            guard fragmentRect.height > 0 else { return }
            let charIndex = layoutManager.characterIndexForGlyph(at: gRange.location)
            let lineRange = nsText.lineRange(for: NSRange(location: charIndex, length: 0))
            guard lineRange.location == charIndex else { return }   // one line only, not wrap rows

            let leadCols = self.leadingIndentColumns(nsText, lineRange: lineRange, tabSize: indentColumns)
            guard leadCols >= indentColumns else { return }

            var col = indentColumns
            while col < leadCols {
                let x = origin.x + CGFloat(col) * charWidth + 0.5
                let path = NSBezierPath()
                path.lineWidth = 1
                path.move(to: NSPoint(x: x, y: fragmentRect.minY + origin.y))
                path.line(to: NSPoint(x: x, y: fragmentRect.maxY + origin.y))
                path.stroke()
                col += indentColumns
            }
        }
    }

    // Column count of the leading whitespace on a line (space = 1 column, tab advances to the next
    // tab stop), i.e. the indent depth at the first non-whitespace character. Mirrors how Scintilla
    // measures indentation before drawing guides.
    private func leadingIndentColumns(_ nsText: NSString, lineRange: NSRange, tabSize: Int) -> Int {
        var columns = 0
        var i = lineRange.location
        let end = NSMaxRange(lineRange)
        while i < end {
            let ch = nsText.character(at: i)
            if ch == 0x20 {            // space
                columns += 1
            } else if ch == 0x09 {     // tab
                columns += tabSize - (columns % tabSize)
            } else {
                break
            }
            i += 1
        }
        return columns
    }
}
