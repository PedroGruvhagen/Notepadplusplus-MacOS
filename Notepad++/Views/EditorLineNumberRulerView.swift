//
//  EditorLineNumberRulerView.swift
//  Notepad++
//
//  Line-number gutter, PURGED AND REBUILT FROM SCRATCH (2026-08-17) as a plain sibling NSView
//  (EditorGutterView) instead of an NSRulerView. The previous NSRulerView-based implementation is
//  gone; its exact code is recoverable with `git show 0be07fc:Notepad++/Views/EditorLineNumberRulerView.swift`
//  if it is ever needed for reference. It was purged for two concrete, Pedro-confirmed defects that
//  this rebuild avoids BY CONSTRUCTION rather than by patching around them:
//
//  1. TEXT-UNDER-NUMBERS OVERLAP (the original bug report). The old gutter was installed via
//     `scrollView.verticalRulerView = ruler; scrollView.hasVerticalRuler = true`
//     (old DocumentTextEditor.swift:211-212), relying on AppKit's NSScrollView ruler-reservation
//     machinery (tile() / ruleThickness) to offset the document view's drawn content to the right of
//     the ruler. That reservation did not reliably survive a SwiftUI NSViewRepresentable.makeNSView
//     layout pass: the SAME Coordinator also toggles `scrollView.automaticallyAdjustsContentInsets`
//     and writes `scrollView.contentInsets` on every `updateNSView` cycle for scroll-beyond-last-line
//     (DocumentTextEditor.swift:641-658, `applyScrollBeyondLastLine`, which runs far more often than
//     the one-time ruler install in `makeNSView`) - `automaticallyAdjustsContentInsets` governs the
//     exact content-inset system the ruler's reserved space depends on, so repeatedly stomping it
//     after the ruler was installed was the strongest identified lead for why the reservation never
//     durably took effect, leaving the first 1-3 characters of every line drawn underneath the number
//     column. This rebuild reserves gutter space with a plain Auto Layout width constraint between two
//     sibling views (EditorContainerView, in DocumentTextEditor.swift) - a mechanism with zero
//     relationship to ruleThickness, tile(), or contentInsets, so this class of bug cannot recur.
//
//  2. WIDE, CONFUSING GAP BETWEEN NUMBER AND TEXT (introduced by an uncommitted recovery attempt that
//     fixed defect #1 by shifting the document view right by the ruler's full `ruleThickness`). The old
//     ruler drew its columns bookmark -> number -> fold, left to right (old
//     EditorLineNumberRulerView.swift:139 `numberColumn = NSRect(x: bmWidth, ..., width: width - bmWidth
//     - fWidth, ...)`, and :157-167 drew the fold chevron in the RIGHTMOST `fWidth` points, i.e.
//     directly against the text). Shifting the text by the full ruler thickness therefore left the
//     14pt fold column sitting between the last digit and the first character of every line. Pedro's
//     words: "a human being won't be able to easily tell what text comes with what line number, which
//     defeats the purpose." This rebuild puts BOTH the bookmark and fold columns to the LEFT of the
//     numbers (bookmark -> fold -> number, see `drawRow` below), so nothing but the text container's
//     own small `lineFragmentPadding` (the same handful of points any plain NSTextView already
//     reserves before its first character) ever sits between a number and its line - a tight, obvious
//     pairing, matching the reference editor Pedro asked for.
//
//  Mechanism: EditorGutterView is a plain NSView, a sibling of the editor's NSScrollView inside a
//  shared container (EditorContainerView, DocumentTextEditor.swift), laid out with Auto Layout so the
//  two views' frames can never overlap and the text view never needs its own insets adjusted for the
//  gutter. It is NOT part of the scroll view's ruler system at all (no verticalRulerView /
//  hasVerticalRuler / rulersVisible), which also removes it as a suspect for the separate tab-bar
//  hairline-bleed artifact Pedro reported (a thin vertical line bleeding from the gutter boundary up
//  through the tab bar above it) - verified visually gone after this rebuild, see the Phase 1 handoff.
//  Scroll lockstep (F61) is preserved by construction, not via a timer/polling hack: the gutter
//  observes NSView.boundsDidChangeNotification on the scroll view's clip view (posted synchronously by
//  AppKit on every scroll - the same underlying primitive NSRulerView itself relies on) and redraws,
//  computing each line's position via the standard `convert(_:from:)` window-coordinate walk, so
//  numbers always land exactly beside their line fragment.
//
//  The gutter also hosts the fold markers (F19, chevron per fold header, click toggles the fold) and
//  the bookmark margin (F51/F56, glyph per bookmarked line, click toggles the bookmark), mirroring
//  Scintilla's fold margin and symbol margin living in the same gutter surface
//  (scintilla-reference/src/MarginView.cxx PaintMargin).
//

import AppKit

final class EditorGutterView: NSView {
    // The document supplies O(log n) line mapping (CellBuffer index), fold state, and bookmarks.
    // Repointed by the Coordinator on a tab switch so the gutter always reflects the active document.
    weak var document: Document? {
        didSet { needsDisplay = true }
    }

    private weak var textView: NSTextView?

    private let numberFontSize: CGFloat
    private let bookmarkColumnWidth: CGFloat = 16
    private let foldColumnWidth: CGFloat = 14
    private let numberPadding: CGFloat = 6

    // Reserves the gutter's width against the sibling scroll view (EditorContainerView). Updated by
    // refresh() as the digit count / margin visibility changes; this is the entire "reserve space for
    // the gutter" mechanism, replacing ruleThickness/tile().
    private var widthConstraint: NSLayoutConstraint!

    private var boundsObserver: NSObjectProtocol?

    // View menu "Show Line Numbers" (F61 visibility toggle). Collapses the gutter to zero width rather
    // than removing it from the view hierarchy, so the scroll view reclaims exactly its space and
    // refresh() can simply re-expand it later.
    var showGutter: Bool = true {
        didSet {
            guard showGutter != oldValue else { return }
            isHidden = !showGutter
            refresh()
        }
    }

    init(scrollView: NSScrollView, textView: NSTextView, fontSize: CGFloat) {
        self.numberFontSize = max(9, fontSize - 2)
        self.textView = textView
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: 44)
        widthConstraint.isActive = true

        // F61: redraw in lockstep with scrolling. The clip view posts this notification
        // synchronously on every scroll (AppKit's own scroll-tracking primitive), so this keeps the
        // gutter in sync by construction, not by a timer/polling hack.
        scrollView.contentView.postsBoundsChangedNotifications = true
        boundsObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let boundsObserver {
            NotificationCenter.default.removeObserver(boundsObserver)
        }
    }

    // Matches NSTextView's flipped coordinate space (top-down, y increases downward) so line-fragment
    // rects convert directly into this view's own drawing coordinates without an extra flip.
    override var isFlipped: Bool { true }

    private var numberFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: numberFontSize, weight: .regular)
    }

    private var showBookmarksMargin: Bool { AppSettings.shared.showBookmarks }

    // Code folding is gated on the document's cached OptimizedSettings, not the raw setting, so a
    // large file (where fold detection is disabled, PerformanceManager.getOptimizedSettings) shows no
    // fold column (F20).
    private var showFoldMargin: Bool { document?.getOptimizedSettings().codeFolding ?? false }

    // Recompute the gutter's width from the current line count (digit width) plus the optional
    // bookmark and fold columns, and repaint. Called by the Coordinator on text / fold / bookmark
    // changes and on a document swap.
    func refresh() {
        let digits = max(2, String(max(document?.lineCount ?? 1, 1)).count)
        let numberWidth = ceil(CGFloat(digits) * numberFont.maximumAdvancement.width) + numberPadding * 2
        let thickness = showGutter
            ? numberWidth
                + (showBookmarksMargin ? bookmarkColumnWidth : 0)
                + (showFoldMargin ? foldColumnWidth : 0)
            : 0
        if abs(thickness - widthConstraint.constant) > 0.5 {
            widthConstraint.constant = thickness
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let textView = textView,
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
            let rowY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            self.drawRow(docLine: docLine,
                         rowY: rowY,
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
            let rowY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            self.drawRow(docLine: docLine,
                         rowY: rowY,
                         height: fragmentRect.height,
                         numberAttributes: numberAttributes,
                         showFold: showFold,
                         showBookmarks: showBookmarks,
                         document: document)
        }
    }

    private func drawRow(docLine: Int,
                         rowY: CGFloat,
                         height: CGFloat,
                         numberAttributes: [NSAttributedString.Key: Any],
                         showFold: Bool,
                         showBookmarks: Bool,
                         document: Document) {
        let width = bounds.width
        let bmWidth = showBookmarks ? bookmarkColumnWidth : 0
        let fWidth = showFold ? foldColumnWidth : 0
        // Bookmark, then fold, then the number - BOTH marker columns sit to the LEFT of the numbers so
        // nothing ever intervenes between a number and its line's text (see header comment: defect #2,
        // the specific reason the previous fix attempt was rejected).
        let numberColumn = NSRect(x: bmWidth + fWidth, y: rowY, width: width - bmWidth - fWidth, height: height)

        // Line number, right aligned, vertically centred in the fragment.
        let label = "\(docLine + 1)" as NSString
        let labelSize = label.size(withAttributes: numberAttributes)
        let labelPoint = NSPoint(x: numberColumn.maxX - labelSize.width - numberPadding,
                                 y: rowY + (height - labelSize.height) / 2)
        label.draw(at: labelPoint, withAttributes: numberAttributes)

        // Bookmark glyph in the leftmost column (F51/F56). Filled rounded marker like Scintilla's
        // MARK_BOOKMARK image (ScintillaEditView.cpp:417 SCI_MARKERDEFINERGBAIMAGE).
        if showBookmarks, document.isBookmarked(line: docLine) {
            let d: CGFloat = min(bookmarkColumnWidth - 6, height - 4)
            let markRect = NSRect(x: (bmWidth - d) / 2, y: rowY + (height - d) / 2, width: d, height: d)
            NSColor.systemBlue.setFill()
            NSBezierPath(roundedRect: markRect, xRadius: 2, yRadius: 2).fill()
        }

        // Fold chevron in the column between bookmark and number, for a fold header (F19). Collapsed =
        // pointing right, expanded = pointing down, matching the Scintilla fold margin markers.
        if showFold, let region = document.foldingState.regions.first(where: { $0.startLine == docLine }) {
            let symbol = region.isCollapsed ? "chevron.right" : "chevron.down"
            if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
                let s: CGFloat = 10
                let iRect = NSRect(x: bmWidth + (foldColumnWidth - s) / 2,
                                   y: rowY + (height - s) / 2, width: s, height: s)
                image.withSymbolConfiguration(.init(pointSize: s, weight: .regular))?
                    .draw(in: iRect, from: .zero, operation: .sourceOver, fraction: 0.7)
            }
        }
    }

    // MARK: - Click handling (fold toggle / bookmark toggle)

    override func mouseDown(with event: NSEvent) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer,
              let document = document else {
            super.mouseDown(with: event)
            return
        }

        let clickPoint = convert(event.locationInWindow, from: nil)
        let inset = textView.textContainerOrigin
        let bmWidth = showBookmarksMargin ? bookmarkColumnWidth : 0
        let fWidth = showFoldMargin ? foldColumnWidth : 0

        // Find the document line whose fragment contains the click y.
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: container)
        let nsText = textView.string as NSString
        var hitLine: Int? = nil
        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { fragmentRect, _, _, glyphRange, stop in
            guard fragmentRect.height > 0 else { return }
            let rowY = self.convert(NSPoint(x: 0, y: fragmentRect.minY + inset.y), from: textView).y
            if clickPoint.y >= rowY && clickPoint.y < rowY + fragmentRect.height {
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
                let lineRange = nsText.lineRange(for: NSRange(location: charIndex, length: 0))
                hitLine = document.lineIndex(forCharacterAt: lineRange.location)
                stop.pointee = true
            }
        }
        guard let line = hitLine else { super.mouseDown(with: event); return }

        // Leftmost column: toggle the bookmark on this line (F51), mirroring Notepad++ symbol-margin
        // click -> bookmarkToggle (NppNotification.cpp:161). Next column: toggle the fold if this line
        // is a header (F19).
        if showBookmarksMargin, clickPoint.x < bmWidth {
            document.toggleBookmark(atLine: line)
            needsDisplay = true   // the gutter does not observe bookmarkedLines; repaint the glyph now
        } else if showFoldMargin, clickPoint.x >= bmWidth, clickPoint.x < bmWidth + fWidth,
                  document.foldingState.regions.contains(where: { $0.startLine == line }) {
            // Fold toggle drives foldingState.collapsedLines (@Published); the editor Coordinator's
            // subscription re-folds the text and refreshes this gutter.
            document.foldingState.toggleFold(at: line)
        } else {
            super.mouseDown(with: event)
        }
    }
}
