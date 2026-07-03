//
//  EditorLineNumberRulerView.swift
//  Notepad++
//
//  Line-number gutter as a native NSRulerView installed as the editor scroll view's
//  verticalRulerView (F61). Because the ruler is the scroll view's own ruler, AppKit redraws it in
//  lockstep with the document view as the user scrolls, so every number stays beside its line at all
//  times, by construction. This replaces the old sibling SwiftUI ScrollView gutter
//  (FoldingLineNumberView) that observed nothing on the editor and stayed frozen while the text
//  scrolled (the user-reported F61 defect: line 158 was unfindable).
//
//  Translation intent: Scintilla paints the line-number margin inside the SAME surface as the text
//  (scintilla-reference/src/MarginView.cxx PaintMargin, driven from the editor paint path), so margin
//  and text move together and only visible lines are drawn. An NSRulerView bound to the scroll view is
//  the AppKit equivalent: it enumerates only the visible line fragments and draws a number per line.
//
//  The ruler also hosts the fold markers (F19, chevron per fold header, click toggles the fold) and
//  the bookmark margin (F51/F56, glyph per bookmarked line, click toggles the bookmark), mirroring
//  Scintilla's fold margin and symbol margin living in the same gutter surface.
//

import AppKit

final class EditorLineNumberRulerView: NSRulerView {
    // The document supplies O(log n) line mapping (CellBuffer index), fold state, and bookmarks.
    // Repointed by the Coordinator on a tab switch so the gutter always reflects the active document.
    weak var document: Document? {
        didSet { needsDisplay = true }
    }

    private let numberFontSize: CGFloat
    private let bookmarkColumnWidth: CGFloat = 16
    private let foldColumnWidth: CGFloat = 14
    private let numberPadding: CGFloat = 6

    init(scrollView: NSScrollView, textView: NSTextView, fontSize: CGFloat) {
        self.numberFontSize = max(9, fontSize - 2)
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.reservedThicknessForAccessoryView = 0
        self.reservedThicknessForMarkers = 0
        self.ruleThickness = 44
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var numberFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: numberFontSize, weight: .regular)
    }

    private var showBookmarksMargin: Bool { AppSettings.shared.showBookmarks }

    // Code folding is gated on the document's cached OptimizedSettings, not the raw setting, so a
    // large file (where fold detection is disabled, PerformanceManager.getOptimizedSettings) shows no
    // fold column (F20).
    private var showFoldMargin: Bool { document?.getOptimizedSettings().codeFolding ?? false }

    // Recompute the ruler thickness from the current line count (digit width) plus the optional
    // bookmark and fold columns, and repaint. Called by the Coordinator on text / fold / bookmark
    // changes and on a document swap.
    func refresh() {
        let digits = max(2, String(max(document?.lineCount ?? 1, 1)).count)
        let numberWidth = ceil(CGFloat(digits) * numberFont.maximumAdvancement.width) + numberPadding * 2
        let thickness = numberWidth
            + (showBookmarksMargin ? bookmarkColumnWidth : 0)
            + (showFoldMargin ? foldColumnWidth : 0)
        if abs(thickness - ruleThickness) > 0.5 {
            ruleThickness = thickness
        }
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer,
              let document = document else { return }

        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        let inset = textView.textContainerOrigin
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: container)
        let nsText = textView.string as NSString
        let showFold = showFoldMargin
        let showBookmarks = showBookmarksMargin

        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { fragmentRect, _, _, glyphRange, _ in
            // Folded lines collapse to a zero-height fragment (FoldingLayoutManagerDelegate); skip them.
            guard fragmentRect.height > 0 else { return }
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            // Draw a number only at the START of a document line, so a wrapped line is numbered once.
            let lineRange = nsText.lineRange(for: NSRange(location: charIndex, length: 0))
            guard lineRange.location == charIndex else { return }
            let docLine = document.lineIndex(forCharacterAt: charIndex)
            let rulerY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            self.drawRow(docLine: docLine,
                         rulerY: rulerY,
                         height: fragmentRect.height,
                         numberAttributes: numberAttributes,
                         showFold: showFold,
                         showBookmarks: showBookmarks,
                         document: document)
        }

        // The trailing empty line (document ends with a newline) has no line fragment; Scintilla still
        // numbers it. Draw it from the extra line fragment rect.
        if layoutManager.extraLineFragmentTextContainer != nil {
            let fragmentRect = layoutManager.extraLineFragmentRect
            let docLine = max(document.lineCount - 1, 0)
            let rulerY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            self.drawRow(docLine: docLine,
                         rulerY: rulerY,
                         height: fragmentRect.height,
                         numberAttributes: numberAttributes,
                         showFold: showFold,
                         showBookmarks: showBookmarks,
                         document: document)
        }
    }

    private func drawRow(docLine: Int,
                         rulerY: CGFloat,
                         height: CGFloat,
                         numberAttributes: [NSAttributedString.Key: Any],
                         showFold: Bool,
                         showBookmarks: Bool,
                         document: Document) {
        let width = ruleThickness
        let bmWidth = showBookmarks ? bookmarkColumnWidth : 0
        let fWidth = showFold ? foldColumnWidth : 0
        let numberColumn = NSRect(x: bmWidth, y: rulerY, width: width - bmWidth - fWidth, height: height)

        // Line number, right aligned, vertically centred in the fragment.
        let label = "\(docLine + 1)" as NSString
        let labelSize = label.size(withAttributes: numberAttributes)
        let labelPoint = NSPoint(x: numberColumn.maxX - labelSize.width - numberPadding,
                                 y: rulerY + (height - labelSize.height) / 2)
        label.draw(at: labelPoint, withAttributes: numberAttributes)

        // Bookmark glyph in the left column (F51/F56). Filled rounded marker like Scintilla's
        // MARK_BOOKMARK image (ScintillaEditView.cpp:417 SCI_MARKERDEFINERGBAIMAGE).
        if showBookmarks, document.isBookmarked(line: docLine) {
            let d: CGFloat = min(bookmarkColumnWidth - 6, height - 4)
            let markRect = NSRect(x: (bmWidth - d) / 2, y: rulerY + (height - d) / 2, width: d, height: d)
            NSColor.systemBlue.setFill()
            NSBezierPath(roundedRect: markRect, xRadius: 2, yRadius: 2).fill()
        }

        // Fold chevron in the right column for a fold header (F19). Collapsed = pointing right,
        // expanded = pointing down, matching the Scintilla fold margin markers.
        if showFold, let region = document.foldingState.regions.first(where: { $0.startLine == docLine }) {
            let symbol = region.isCollapsed ? "chevron.right" : "chevron.down"
            if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
                let s: CGFloat = 10
                let iRect = NSRect(x: width - fWidth + (foldColumnWidth - s) / 2,
                                   y: rulerY + (height - s) / 2, width: s, height: s)
                image.withSymbolConfiguration(.init(pointSize: s, weight: .regular))?
                    .draw(in: iRect, from: .zero, operation: .sourceOver, fraction: 0.7)
            }
        }
    }

    // MARK: - Click handling (fold toggle / bookmark toggle)

    override func mouseDown(with event: NSEvent) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer,
              let document = document else { return }

        let clickPoint = convert(event.locationInWindow, from: nil)
        let inset = textView.textContainerOrigin
        let width = ruleThickness
        let bmWidth = showBookmarksMargin ? bookmarkColumnWidth : 0
        let fWidth = showFoldMargin ? foldColumnWidth : 0

        // Find the document line whose fragment contains the click y.
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: container)
        let nsText = textView.string as NSString
        var hitLine: Int? = nil
        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { fragmentRect, _, _, glyphRange, stop in
            guard fragmentRect.height > 0 else { return }
            let rulerY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            if clickPoint.y >= rulerY && clickPoint.y < rulerY + fragmentRect.height {
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
                let lineRange = nsText.lineRange(for: NSRange(location: charIndex, length: 0))
                hitLine = document.lineIndex(forCharacterAt: lineRange.location)
                stop.pointee = true
            }
        }
        guard let line = hitLine else { super.mouseDown(with: event); return }

        // Right column: toggle the fold if this line is a header (F19). Left/number column: toggle the
        // bookmark on this line (F51), mirroring Notepad++ symbol-margin click -> bookmarkToggle
        // (NppNotification.cpp:161).
        if showFoldMargin, clickPoint.x >= width - fWidth,
           document.foldingState.regions.contains(where: { $0.startLine == line }) {
            // Fold toggle drives foldingState.collapsedLines (@Published); the editor Coordinator's
            // subscription re-folds the text and refreshes this ruler.
            document.foldingState.toggleFold(at: line)
        } else if showBookmarksMargin, clickPoint.x < bmWidth {
            document.toggleBookmark(atLine: line)
            needsDisplay = true   // the ruler does not observe bookmarkedLines; repaint the glyph now
        } else {
            super.mouseDown(with: event)
        }
    }
}
