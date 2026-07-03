//
//  FoldingLayoutManagerDelegate.swift
//  Notepad++
//
//  Real code folding for the live editor (F19). Translates Scintilla's line-hiding: a collapsed
//  fold header hides its subordinate document lines so the text below it moves up, exactly like
//  ContractionState::SetVisible(line+1, lastChild, false) (scintilla-reference/src/ContractionState.cxx:251),
//  which subtracts each hidden line's display-row height from the document-line -> display-line
//  partition so paint/scroll/hit-test never enumerate the hidden lines
//  (EditView.cxx:2533 Paint loop bounded by pcs->LinesDisplayed()). The header line itself stays
//  visible (Editor::FoldLine, Editor.cxx:5704 hides only [line+1, lineMaxSubord]).
//
//  TextKit equivalent: for every glyph whose document line is in FoldingState.collapsedLines, mark
//  the glyph NSGlyphProperty.null (ignored for layout and display), and collapse that line's layout
//  fragment to zero height. The bytes are never touched, matching Scintilla folding, which only
//  flips visibility bits and never edits the CellBuffer.
//

import AppKit
import CoreGraphics

final class FoldingLayoutManagerDelegate: NSObject, NSLayoutManagerDelegate {
    // The document whose foldingState.collapsedLines (0-based hidden line indices) drives hiding.
    // Weak: the layout manager outlives no document; the Coordinator repoints this on a tab swap.
    weak var document: Document?

    // NSLayoutManager glyph generation hook. For each glyph in the run, if its document line is
    // collapsed, override the property to .null so it is not laid out or drawn. Returns 0 (no change)
    // when nothing is folded so the non-folding path pays essentially nothing.
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
                       properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
                       characterIndexes charIndexes: UnsafePointer<Int>,
                       font aFont: NSFont,
                       forGlyphRange glyphRange: NSRange) -> Int {
        // TextKit glyph generation runs on the main thread; assert that so the @MainActor Document
        // line index / fold set can be read here (same pattern as the storage delegate, F09).
        MainActor.assumeIsolated {
            guard let document, !document.foldingState.collapsedLines.isEmpty else { return 0 }
            let hidden = document.foldingState.collapsedLines
            let n = glyphRange.length
            var newProps = [NSLayoutManager.GlyphProperty](repeating: NSLayoutManager.GlyphProperty(rawValue: 0), count: n)
            var modified = false

            // Resolve the document line per glyph, recomputing only when crossing a line boundary
            // (O(n) glyphs, O(log n) lookup per line via the CellBuffer index). A hidden glyph gets .null.
            var cachedStart = 0
            var cachedEnd = -1   // exclusive char boundary of the cached line
            var cachedHidden = false
            for i in 0..<n {
                let c = charIndexes[i]
                newProps[i] = props[i]
                if !(c >= cachedStart && c < cachedEnd) {
                    let line = document.lineIndex(forCharacterAt: c)
                    cachedStart = document.lineStartPosition(line)
                    cachedEnd = document.lineStartPosition(line + 1)
                    if cachedEnd <= c { cachedEnd = c + 1 }   // guarantee forward progress on degenerate bounds
                    cachedHidden = hidden.contains(line)
                }
                if cachedHidden {
                    newProps[i] = .null
                    modified = true
                }
            }

            if !modified { return 0 }
            newProps.withUnsafeBufferPointer { buf in
                layoutManager.setGlyphs(glyphs,
                                        properties: buf.baseAddress!,
                                        characterIndexes: charIndexes,
                                        font: aFont,
                                        forGlyphRange: glyphRange)
            }
            return n
        }
    }

    // Collapse a folded line's fragment to zero height so the following visible line stacks directly
    // beneath the fold header, matching ContractionState subtracting the hidden line's height from the
    // display partition. Non-folded fragments are left untouched (return false).
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
                       lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
                       baselineOffset: UnsafeMutablePointer<CGFloat>,
                       in textContainer: NSTextContainer,
                       forGlyphRange glyphRange: NSRange) -> Bool {
        MainActor.assumeIsolated {
            guard let document, !document.foldingState.collapsedLines.isEmpty else { return false }
            let firstChar = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let line = document.lineIndex(forCharacterAt: firstChar)
            guard document.foldingState.collapsedLines.contains(line) else { return false }

            var frame = lineFragmentRect.pointee
            frame.size.height = 0
            lineFragmentRect.pointee = frame

            var used = lineFragmentUsedRect.pointee
            used.size.height = 0
            lineFragmentUsedRect.pointee = used

            baselineOffset.pointee = 0
            return true
        }
    }
}
