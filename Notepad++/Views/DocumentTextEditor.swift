//
//  DocumentTextEditor.swift
//  Notepad++
//
//  Document-aware text editor that uses Document's NSTextStorage
//  This is the CRITICAL FIX for language state bleeding across tabs
//

import SwiftUI
import AppKit
import Combine

// F61: the editor pane's root view. Holds the line-number gutter (EditorGutterView) and the text
// scroll view as SIBLINGS laid out side by side with Auto Layout, so their frames can never overlap
// and the text view never needs its own insets adjusted to make room for the gutter. This replaces
// the old design where the gutter was installed as the scroll view's own `verticalRulerView` - see
// EditorLineNumberRulerView.swift's header comment for exactly why that was purged and rebuilt this
// way (including the separate tab-bar hairline-bleed artifact this design also eliminates, since it
// never touches the scroll view's ruler machinery at all).
final class EditorContainerView: NSView {
    let scrollView: NSScrollView
    let gutterView: EditorGutterView

    init(scrollView: NSScrollView, gutterView: EditorGutterView) {
        self.scrollView = scrollView
        self.gutterView = gutterView
        super.init(frame: .zero)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gutterView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            gutterView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gutterView.topAnchor.constraint(equalTo: topAnchor),
            gutterView.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: gutterView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DocumentTextEditor: NSViewRepresentable {
    @ObservedObject var document: Document
    let fontSize: CGFloat
    var fontName: String = "Menlo"
    var wordWrap: Bool = false
    var showWhitespace: Bool = false
    var showEndOfLine: Bool = false
    var highlightCurrentLine: Bool = true
    var currentLineColor: String = "#F0F0F0"
    var showIndentGuides: Bool = true
    var caretWidth: CGFloat = 1.0
    var caretBlinkRate: Double = 600
    var scrollBeyondLastLine: Bool = false
    var showLineNumbers: Bool = true
    var tabSize: Int = 4
    var replaceTabsBySpaces: Bool = false
    var maintainIndent: Bool = true
    var autoIndent: Bool = true
    var smartIndent: Bool = false
    let syntaxHighlightingEnabled: Bool
    
    // Non-owning handle to the currently active editor view so components like
    // FindReplaceBar can reach the focused editor. This is a POINTER, never a shared
    // instance reparented across windows (that shared-singleton was the F01 input-death
    // bug). Each Coordinator owns its own NSTextView, one per view pane, mirroring
    // Notepad++ having one persistent ScintillaEditView per pane
    // (ScintillaEditView.cpp:2333 activateBuffer, not a process-wide control).
    static weak var activeTextView: NSTextView?

    // Select, scroll, centre (CARET_EVEN) and pulse a range in a text view. Shared by Find
    // Next/Previous (F49) and Find in Files result activation (F50). Port of
    // Searching::displaySectionCentered (FindReplaceDlg.cpp def :227, called :663), which scrolls the
    // whole match into view (SCI_SCROLLRANGE :242), centres the caret (CARET_EVEN visible policy
    // :234/:238), then selects the result with SCI_GOTOPOS + SCI_SETANCHOR (:259-260). Clamped so a
    // stale range (document edited after the search) cannot raise NSRangeException.
    static func reveal(_ range: NSRange, in textView: NSTextView) {
        let length = (textView.string as NSString).length
        guard range.location >= 0, range.location <= length else { return }
        let clamped = NSRange(location: range.location,
                              length: min(range.length, length - range.location))
        textView.setSelectedRange(clamped)
        textView.scrollRangeToVisible(clamped)
        textView.centerSelectionInVisibleArea(nil)
        textView.showFindIndicator(for: clamped)
    }

    func makeNSView(context: Context) -> EditorContainerView {
        let scrollView = NSScrollView()
        
        // Each representable/Coordinator owns its own NSTextView (one per view pane).
        // Port of Notepad++ keeping one persistent ScintillaEditView per pane rather
        // than a process-wide shared control (F01). EditorTextView adds caret width/steady-blink
        // (F55) and indent-guide drawing (F56).
        let textView = EditorTextView()
        Self.activeTextView = textView
        
        // Essential properties for text to be visible and editable
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true  // Enable rich text for syntax highlighting
        textView.importsGraphics = false
        textView.allowsUndo = true
        
        // Text appearance with theme support
        let theme = ThemeManager.shared.currentTheme
        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        
        // Ensure text is always visible with proper contrast
        let bgColor = theme.backgroundColor
        let txtColor = theme.textColor
        
        // Fallback: if colors are too similar, force black on white
        if abs(bgColor.brightnessComponent - txtColor.brightnessComponent) < 0.3 {
            textView.textColor = .black
            textView.backgroundColor = .white
        } else {
            textView.textColor = txtColor
            textView.backgroundColor = bgColor
        }
        
        textView.insertionPointColor = textView.textColor
        textView.selectedTextAttributes = [
            .backgroundColor: theme.selectionColor,
            .foregroundColor: theme.textColor
        ]
        
        // Disable auto substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        
        // CRITICAL: Activate this document's text storage
        // This is the Swift equivalent of SCI_SETDOCPOINTER
        document.activate(in: textView)

        // F09: receive per-edit deltas from THIS document's storage so the CellBuffer is
        // maintained incrementally (never re-ingested whole on a keystroke). F11: point the
        // live brace path at this document's ScintillaDocument (the one kept in sync here),
        // instead of a shadow document that does a full setText per brace-match call.
        document.textStorage.delegate = context.coordinator
        textView.setLiveScintillaDocument(document.document)

        // F24: do NOT force whole-document layout at open. With non-contiguous layout
        // enabled (PerformanceManager.optimizeTextView, called below) TextKit lays out
        // only what is drawn; the previous `ensureLayout(for: textContainer)` laid out the
        // entire document synchronously on the main thread, which for a large file was a
        // dominant part of the open beachball. Ask only for the visible rect (empty until
        // the view is in its window, in which case this is a no-op and TextKit lays out on
        // demand), matching Scintilla laying out/styling just the visible window
        // (Editor.cxx StyleToPositionInView).
        if let textContainer = textView.textContainer {
            textView.layoutManager?.ensureLayout(forBoundingRect: textView.visibleRect, in: textContainer)
        }
        textView.needsDisplay = true
        
        // Configure word wrap
        if let textContainer = textView.textContainer {
            if wordWrap {
                textContainer.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = true
                textView.isHorizontallyResizable = false
                textView.autoresizingMask = [.width]
            } else {
                textContainer.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = false
                textView.isHorizontallyResizable = true
                textView.autoresizingMask = []
            }
            textContainer.heightTracksTextView = false
        }
        
        // Configure caret width
        if let layoutManager = textView.layoutManager {
            layoutManager.showsInvisibleCharacters = showWhitespace || showEndOfLine
        }
        
        // Configure layout manager
        textView.minSize = CGSize(width: 0, height: 0)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        
        // Store additional settings in coordinator
        context.coordinator.document = document
        context.coordinator.highlightCurrentLine = highlightCurrentLine
        context.coordinator.currentLineColor = currentLineColor
        context.coordinator.showIndentGuides = showIndentGuides
        context.coordinator.scrollBeyondLastLine = scrollBeyondLastLine
        context.coordinator.tabSize = tabSize
        context.coordinator.replaceTabsBySpaces = replaceTabsBySpaces
        context.coordinator.maintainIndent = maintainIndent
        context.coordinator.autoIndent = autoIndent
        context.coordinator.smartIndent = smartIndent
        context.coordinator.lastFontName = fontName
        context.coordinator.lastFontSize = fontSize
        context.coordinator.lastWordWrap = wordWrap

        // Configure indentation settings
        textView.configureIndentationSettings(
            tabSize: tabSize,
            replaceTabsBySpaces: replaceTabsBySpaces,
            maintainIndent: maintainIndent,
            autoIndent: autoIndent,
            smartIndent: smartIndent
        )

        // F55/F56: apply caret width, steady-blink (period 0), and indent-guide settings to the
        // EditorTextView subclass. Port of SCI_SETCARETWIDTH (NppBigSwitch.cpp:1746),
        // SCI_SETCARETPERIOD (NppBigSwitch.cpp:1896), SCI_SETINDENTATIONGUIDES (ScintillaEditView.cpp:3454).
        textView.caretPixelWidth = caretWidth
        textView.caretSteady = caretBlinkRate <= 0
        textView.showIndentGuidesFlag = showIndentGuides
        textView.indentTabSize = tabSize

        // F19: install the folding layout-manager delegate so a collapsed fold header hides its
        // subordinate text lines (not just gutter numbers). Repointed on a tab swap in updateNSView.
        context.coordinator.foldingDelegate.document = document
        textView.layoutManager?.delegate = context.coordinator.foldingDelegate

        // Set delegate
        textView.delegate = context.coordinator

        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder

        // F61: the line-number gutter is EditorGutterView, a plain NSView laid out side by side with
        // this scroll view inside EditorContainerView (Auto Layout, above) - NOT the scroll view's own
        // verticalRulerView. See EditorLineNumberRulerView.swift's header comment for exactly why the
        // previous NSRulerView-based gutter was purged and rebuilt this way. The gutter observes the
        // scroll view's clip view to redraw in lockstep on every scroll, and also hosts the fold
        // markers (F19) and bookmark margin (F51/F56).
        let gutterView = EditorGutterView(scrollView: scrollView, textView: textView, fontSize: fontSize)
        gutterView.document = document
        gutterView.showGutter = showLineNumbers
        context.coordinator.lineNumberGutter = gutterView
        gutterView.refresh()

        let container = EditorContainerView(scrollView: scrollView, gutterView: gutterView)

        context.coordinator.textView = textView

        // F19: re-fold layout whenever this document's collapsed line set changes (chevron click,
        // Fold All / Unfold All), and keep the gutter thickness / markers in sync.
        context.coordinator.subscribeFolding(to: document)

        // F53: wire the auto-completion engine to THIS live editor. Previously the 882-line engine was
        // never instantiated, so its settings tab was a phantom. configure(for:) installs the
        // NSText.didChangeNotification observer that drives update(ch) -> word/keyword completion,
        // translating the SCN_CHARADDED -> AutoCompletion::update path (NppNotification.cpp:196). The
        // engine self-gates on AppSettings.enableAutoCompletion (default off; the user opts in).
        let engine = AutoCompletionEngine(textView: textView)
        engine.configure(for: textView)
        context.coordinator.autoCompletionEngine = engine
        context.coordinator.applyAutoCompletionLanguage(for: document)
        
        // Apply performance optimizations if needed
        PerformanceManager.shared.optimizeTextView(textView, forLargeFile: document.isLargeFile)
        
        // Apply initial syntax highlighting if enabled. F25: ONE pass, visible range
        // first then the rest deferred (highlightVisibleThenRest). The previous code ran a
        // whole-document highlight here AND another inside document.activate above, i.e.
        // two synchronous whole-document passes at open. activate no longer highlights, so
        // this is the single open-time styling pass. `syntaxHighlightingEnabled` carries
        // the large-file optimized gate.
        if syntaxHighlightingEnabled, let language = document.language {
            document.highlightVisibleThenRest(in: textView, language: language)
        }

        context.coordinator.updateBracketHighlighting()
        
        // Set up notification observer for bracket navigation
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.jumpToMatchingBracket(_:)),
            name: .jumpToMatchingBracket,
            object: nil
        )

        // F49: the Find bar posts these to drive Find Next/Previous and match highlighting. The
        // handlers are wired into the Coordinator that actually owns the live NSTextView, so Cmd+F
        // navigation acts on the focused editor. dismantleNSView removes all of this coordinator's
        // observers. The Find bar
        // (FindReplaceBar) drives selection+centring through the "range" key of .highlightSearchResult
        // (findNext/findPrevious), so no separate .selectSearchResult observer is needed here.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleHighlightSearchResults(_:)),
            name: .highlightSearchResult,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleClearSearchHighlights(_:)),
            name: .clearSearchHighlights,
            object: nil
        )

        // F51: bookmark toggle / navigation act on the live editor's caret line and this document's
        // bookmark set (Notepad_plus bookmarkToggle/bookmarkNext). Same observe-in-the-live-Coordinator
        // pattern as F49, since only the live NSTextView knows the caret line.
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.handleToggleBookmark(_:)),
            name: .toggleBookmark, object: nil)
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.handleNextBookmark(_:)),
            name: .nextBookmark, object: nil)
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.handlePreviousBookmark(_:)),
            name: .previousBookmark, object: nil)
        // F52: Search menu Mark All / Clear Marks paint (and clear) occurrence marks on the live editor
        // (FindReplaceDlg::markAll, FindReplaceDlg.cpp:3279 / clearMarks :4767).
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.handleMarkAll(_:)),
            name: .markAll, object: nil)
        NotificationCenter.default.addObserver(
            context.coordinator, selector: #selector(Coordinator.handleClearMarks(_:)),
            name: .clearMarks, object: nil)

        // Undo history lives in the Document (Scintilla model). Cap the document's own
        // UndoManager here where the object is real; the old code set levelsOfUndo on
        // textView.undoManager while that was still nil, so the cap was inert (F04).
        document.undoManager.levelsOfUndo = document.isLargeFile ? 10 : 100

        // Restore first responder after the view is placed in a window, so typing works
        // immediately and survives window churn (F01). textView.window is nil during
        // makeNSView, so defer to the next runloop when the view is in its window.
        DispatchQueue.main.async { [weak textView] in
            guard let textView else { return }
            textView.window?.makeFirstResponder(textView)
        }

        return container
    }

    func updateNSView(_ container: EditorContainerView, context: Context) {
        let scrollView = container.scrollView
        // Resolve this pane's text view: the Coordinator owns it (one NSTextView per view
        // pane, F01), falling back to the scroll view's documentView only if the
        // coordinator reference was lost.
        let textView = context.coordinator.textView ?? (scrollView.documentView as? NSTextView)
        guard let textView = textView else { return }
        Self.activeTextView = textView

        // Self-heal: keep this pane's own text view installed as the scroll view's
        // documentView. An NSView can only live in one scroll view at a time; after
        // close/reopen cycles it can be left dangling with no documentView owner.
        if scrollView.documentView !== textView {
            scrollView.documentView = textView
        }

        // Trigger a doc swap when either the tab id changed (normal tab switch) OR when
        // the text view is still attached to the wrong text storage (the desync that
        // causes a blank editor after close/reopen). Port of SCI_SETDOCPOINTER guard.
        let needsDocSwap = context.coordinator.document?.id != document.id
            || textView.textStorage !== document.textStorage

        if needsDocSwap {
            // Capture the outgoing storage before the swap so its delegate can be cleared
            // (F09): only the current document's storage should notify this coordinator.
            let previousStorage = textView.textStorage

            // F02: only save state from the outgoing document if the view still holds
            // that document's storage. saveState is now positions only (port of
            // ScintillaEditView::saveCurrentPos, ScintillaEditView.cpp:2202-2224, which
            // never copies text between buffers). On a pure desync we skip it and just
            // activate the new document, exactly as SCI_SETDOCPOINTER never copies
            // content across documents.
            if let outgoing = context.coordinator.document,
               textView.textStorage === outgoing.textStorage {
                outgoing.saveState(from: textView)
            }

            // F03: clear all transient painted attributes from the OUTGOING storage
            // before the swap so no colored residue leaks into the next document, and
            // reset the per-view mark bookkeeping. In Scintilla indicators/markers are
            // per-document state swapped by SCI_SETDOCPOINTER.
            context.coordinator.clearPaintedAttributes(on: textView)

            // Activate new document (swaps text storage) and restore position when
            // switching tabs. activate() no longer highlights; styling is applied once
            // below, visible range first (F05, F25).
            document.activate(in: textView, restorePosition: true)

            // F09/F11: re-point the incremental CellBuffer sync and the live brace document
            // at the newly activated document, and detach the outgoing storage's delegate so
            // only the current document's storage feeds this coordinator.
            if previousStorage !== document.textStorage {
                previousStorage?.delegate = nil
            }
            document.textStorage.delegate = context.coordinator
            textView.setLiveScintillaDocument(document.document)

            // F19/F61: repoint the folding delegate and the gutter at the newly activated document,
            // and re-subscribe to its fold-visibility so a fold toggle re-lays out THIS document.
            context.coordinator.foldingDelegate.document = document
            context.coordinator.lineNumberGutter?.document = document
            context.coordinator.subscribeFolding(to: document)
            context.coordinator.lineNumberGutter?.refresh()
            // F53: the pane's editor is the same NSTextView across a document swap, so the engine keeps
            // observing it; just reload the new document's language keywords.
            context.coordinator.applyAutoCompletionLanguage(for: document)

            // F05: lazy layout. Mark the swapped range dirty but force layout only for
            // the visible rect; the rest lays out on demand, matching Scintilla styling
            // only damaged/visible regions (Editor.cxx lazy StyleTo/IdleStyle).
            if let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {
                let fullRange = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
                layoutManager.invalidateLayout(forCharacterRange: fullRange, actualCharacterRange: nil)
                layoutManager.ensureLayout(forBoundingRect: textView.visibleRect, in: textContainer)
            }
            textView.needsDisplay = true

            // F25: ONE highlight pass on tab switch, visible range first then the rest
            // deferred. restoreState above has set the scroll position, so visibleRect now
            // reflects the destination, giving the correct visible range to style first.
            if syntaxHighlightingEnabled, let language = document.language {
                document.highlightVisibleThenRest(in: textView, language: language)
            }

            // Update coordinator reference
            context.coordinator.document = document

            // F01: focus the editor after a document swap so input lands in the new tab.
            textView.window?.makeFirstResponder(textView)
        }
        
        // F05: apply the font to the whole storage ONLY when it actually changed.
        // NSText.font restyles every character, so setting it on every SwiftUI update
        // was a full-document pass on each keystroke and each tab switch.
        if context.coordinator.lastFontName != fontName || context.coordinator.lastFontSize != fontSize {
            let font = NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            textView.font = font
            context.coordinator.lastFontName = fontName
            context.coordinator.lastFontSize = fontSize
        }
        
        // F17: only reset the text container when wordWrap actually changed. Resetting
        // containerSize and the resizable flags on every SwiftUI update (per keystroke) is
        // redundant; widthTracksTextView already tracks resizes. Track the last-applied
        // value on the coordinator and early-return otherwise.
        if let textContainer = textView.textContainer, context.coordinator.lastWordWrap != wordWrap {
            if wordWrap {
                textContainer.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = true
                textView.isHorizontallyResizable = false
            } else {
                textContainer.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = false
                textView.isHorizontallyResizable = true
            }
            context.coordinator.lastWordWrap = wordWrap
        }

        // F17: only toggle invisible-character display when it actually changes, so a
        // keystroke does not touch the layout manager when the setting is unchanged.
        if let layoutManager = textView.layoutManager {
            let showInvisibles = showWhitespace || showEndOfLine
            if layoutManager.showsInvisibleCharacters != showInvisibles {
                layoutManager.showsInvisibleCharacters = showInvisibles
            }
        }
        
        // Update coordinator settings
        // F06: capture the previous highlight-line setting/colour, apply the new ones, and if either
        // changed redraw or clear the caret-line band immediately. Toggling the setting off must clear
        // the last band (Scintilla stops filling the caret-line background when the element is cleared),
        // and a colour change must repaint it without waiting for the next caret move.
        let prevHighlightLine = context.coordinator.highlightCurrentLine
        let prevLineColor = context.coordinator.currentLineColor
        context.coordinator.highlightCurrentLine = highlightCurrentLine
        context.coordinator.currentLineColor = currentLineColor
        if prevHighlightLine != highlightCurrentLine || prevLineColor != currentLineColor {
            if highlightCurrentLine { context.coordinator.updateCurrentLineHighlight() }
            else { context.coordinator.clearCurrentLineHighlight() }
        }
        context.coordinator.showIndentGuides = showIndentGuides
        context.coordinator.scrollBeyondLastLine = scrollBeyondLastLine
        context.coordinator.tabSize = tabSize
        context.coordinator.replaceTabsBySpaces = replaceTabsBySpaces
        context.coordinator.maintainIndent = maintainIndent
        context.coordinator.autoIndent = autoIndent
        context.coordinator.smartIndent = smartIndent

        // F55/F56/F61: keep the EditorTextView caret + indent-guide settings, the gutter visibility
        // (Show Line Numbers), and scroll-beyond-last-line current when a setting changes.
        if let editorTextView = textView as? EditorTextView {
            editorTextView.caretPixelWidth = caretWidth
            editorTextView.caretSteady = caretBlinkRate <= 0
            editorTextView.showIndentGuidesFlag = showIndentGuides
            editorTextView.indentTabSize = tabSize
            editorTextView.needsDisplay = true
        }
        if container.gutterView.showGutter != showLineNumbers {
            container.gutterView.showGutter = showLineNumbers
        }
        context.coordinator.applyScrollBeyondLastLine(scrollView)
        context.coordinator.lineNumberGutter?.refresh()

        // Update indentation settings
        textView.configureIndentationSettings(
            tabSize: tabSize,
            replaceTabsBySpaces: replaceTabsBySpaces,
            maintainIndent: maintainIndent,
            autoIndent: autoIndent,
            smartIndent: smartIndent
        )

        // F50: consume a pending Find-in-Files reveal now that this document's storage is installed
        // in the editor (either the doc-swap above just ran, or this is already the active tab).
        // Defer one runloop so TextKit has laid out the swapped content before we centre on the
        // match; guard on storage identity so a fast re-render cannot reveal into the wrong document.
        if let range = document.pendingRevealRange {
            document.pendingRevealRange = nil
            DispatchQueue.main.async { [weak textView] in
                guard let textView, textView.textStorage === document.textStorage else { return }
                Self.reveal(range, in: textView)
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    static func dismantleNSView(_ container: EditorContainerView, coordinator: Coordinator) {
        // Deterministically park the view when its window/tab closes: detach the layout
        // manager from the document storage so the storage is not left wired to a dead
        // view, and drop the active-view handle if it pointed here (F01).
        let textView = coordinator.textView ?? (container.scrollView.documentView as? NSTextView)
        if let textView = textView {
            if Self.activeTextView === textView {
                Self.activeTextView = nil
            }
            if let layoutManager = textView.layoutManager {
                layoutManager.delegate = nil
                textView.textStorage?.removeLayoutManager(layoutManager)
            }
        }
        coordinator.stopFolding()
        // F53: drop the auto-completion engine; its deinit removes the NSText.didChangeNotification
        // observer it installed on the text view (an unsafe-unretained registration).
        coordinator.autoCompletionEngine = nil
        NotificationCenter.default.removeObserver(coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: DocumentTextEditor
        weak var textView: NSTextView?
        weak var document: Document?
        var isUpdating = false
        var highlightCurrentLine = true
        var currentLineColor = "#F0F0F0"
        var showIndentGuides = true
        var scrollBeyondLastLine = false
        var currentLineRange: NSRange?
        var tabSize = 4
        var replaceTabsBySpaces = false
        var maintainIndent = true
        var autoIndent = true
        var smartIndent = false
        var lastFontName: String?
        var lastFontSize: CGFloat?
        // F17: last-applied wordWrap so updateNSView only resets the text container when it
        // actually changes, instead of on every SwiftUI update (per keystroke).
        var lastWordWrap: Bool?
        // F12: pending debounced smart-highlight scan; cancelled and rescheduled per
        // selection change so the scan runs once after the selection settles.
        var smartHighlightWorkItem: DispatchWorkItem?
        // F49: the match ranges the Find bar is currently highlighting, so they can be cleared
        // precisely (and so textDidChange knows a search is active and should refresh the count).
        var searchHighlightRanges: [NSRange] = []

        // F52: the ranges currently painted by Mark All, so Clear Marks removes exactly them.
        var markedSearchRanges: [NSRange] = []

        // F06/F07: shared .backgroundColor colours for the DURABLE layers, reused everywhere they are
        // painted so a transient repaint (current line, brace) re-asserts the exact same colour and the
        // layers stay in sync. Priority bottom-to-top: caret-line band < brace < Mark All < search,
        // mirroring Scintilla drawing the caret-line background under the indicator layers.
        static let markAllColor = NSColor.systemGreen.withAlphaComponent(0.35)
        static let searchMatchColor = NSColor.systemYellow.withAlphaComponent(0.3)
        static let searchCurrentColor = NSColor.systemOrange.withAlphaComponent(0.5)
        // F49: index of the current match within searchHighlightRanges, so a durable reassert repaints
        // it with the stronger "current" colour rather than the plain match colour.
        var searchCurrentIndex: Int = 0
        // F61: the native line-number gutter (a plain sibling NSView, EditorGutterView) for this pane.
        weak var lineNumberGutter: EditorGutterView?
        // F19: hides collapsed fold ranges from layout; document repointed on a tab swap.
        let foldingDelegate = FoldingLayoutManagerDelegate()
        // F19: subscription to this document's collapsedLines so a fold toggle re-lays out the text.
        private var foldingCancellable: AnyCancellable?
        // F19: whether any lines are currently folded, so refoldLayout can skip the whole-document
        // glyph/layout invalidation entirely when nothing is (or was) folded - keeping the Phase 3
        // open path and normal typing free of any fold-related relayout.
        private var hasFoldedLines = false
        // F53: the auto-completion engine for this pane (word + keyword completion on the live editor).
        var autoCompletionEngine: AutoCompletionEngine?

        init(_ parent: DocumentTextEditor) {
            self.parent = parent
        }

        // F19: subscribe to the active document's fold-visibility changes. When collapsedLines
        // changes (chevron click, Fold All / Unfold All, or a fold recompute that carried collapse
        // state), invalidate glyphs + layout so the FoldingLayoutManagerDelegate re-hides the right
        // lines, and repaint the gutter markers. Cancels any prior subscription (tab swap).
        @MainActor
        func subscribeFolding(to document: Document) {
            foldingCancellable = document.foldingState.$collapsedLines
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.refoldLayout()
                        self?.lineNumberGutter?.refresh()
                    }
                }
        }

        func stopFolding() {
            foldingCancellable?.cancel()
            foldingCancellable = nil
        }

        // F53: load the active document's language keywords into the auto-completion engine so
        // keyword/API completion matches the current buffer. Word completion works regardless; this
        // adds the language keyword set (AutoCompletion::setLanguage). Called on open and tab swap.
        @MainActor
        func applyAutoCompletionLanguage(for document: Document) {
            guard let engine = autoCompletionEngine else { return }
            if let name = document.language?.name,
               let langType = LanguageManager.shared.langType(forDefinitionName: name) {
                _ = engine.setLanguage(langType)
            } else {
                _ = engine.setLanguage(.L_TEXT)
            }
        }

        // F19: force TextKit to re-query the folding delegate over the whole document (a fold toggle
        // is a user action, so a full glyph/layout invalidation is fine) and confine actual layout to
        // the visible rect, matching Scintilla only laying out the visible window.
        @MainActor
        func refoldLayout() {
            guard let textView = textView,
                  let layoutManager = textView.layoutManager,
                  let container = textView.textContainer else { return }
            // Nothing folded now and nothing folded before (initial subscribe emit, or typing in a
            // document with no collapsed regions): skip the whole-document invalidation entirely.
            let hasFolds = !(document?.foldingState.collapsedLines.isEmpty ?? true)
            guard hasFolds || hasFoldedLines else { return }
            hasFoldedLines = hasFolds
            let full = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
            layoutManager.invalidateGlyphs(forCharacterRange: full, changeInLength: 0, actualCharacterRange: nil)
            layoutManager.invalidateLayout(forCharacterRange: full, actualCharacterRange: nil)
            layoutManager.ensureLayout(forBoundingRect: textView.visibleRect, in: container)
            textView.needsDisplay = true
            lineNumberGutter?.needsDisplay = true
        }

        // F55: scroll-beyond-last-line. Notepad++ SCI_SETENDATLASTLINE(!scrollBeyondLastLine)
        // (Notepad_plus.cpp:317): when scrolling past the last line is allowed, add bottom room so the
        // last line can rise toward the top. Implemented as a bottom content inset on the scroll view.
        @MainActor
        func applyScrollBeyondLastLine(_ scrollView: NSScrollView) {
            if scrollBeyondLastLine {
                // Allow scrolling past the last line by adding bottom room so the last line can rise
                // toward the top (SCI_SETENDATLASTLINE(false), Notepad_plus.cpp:317).
                let visibleHeight = scrollView.contentView.bounds.height
                let lineHeight = (textView?.font?.boundingRectForFont.height ?? 16)
                let bottom = max(0, visibleHeight - lineHeight * 2)
                if !scrollView.automaticallyAdjustsContentInsets || abs(scrollView.contentInsets.bottom - bottom) > 0.5 {
                    scrollView.automaticallyAdjustsContentInsets = false
                    scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
                }
            } else if !scrollView.automaticallyAdjustsContentInsets {
                // Restore the default inset behaviour only if we previously took it over, so the
                // default (feature off) path never disturbs the scroll view's automatic insets.
                scrollView.automaticallyAdjustsContentInsets = true
                scrollView.contentInsets = NSEdgeInsets()
            }
        }
        
        // F09: feed ONLY the insert/delete delta of each storage edit to the CellBuffer,
        // never a whole-string reset. This is the exact Scintilla notification point (an
        // edit mutates the CellBuffer in place: BasicDeleteChars then BasicInsertString,
        // CellBuffer.cxx:1011,:840). Deliberately NOT gated on `isUpdating`: the re-entrant
        // indent insert from maintainIndentation (F14) is a real edit that must reach
        // _doc.cb. The programmatic-edit guard inside applyIncrementalEdit handles the
        // open/reload full-replace case so the delta does not double-apply.
        func textStorage(_ textStorage: NSTextStorage,
                         didProcessEditing editedMask: NSTextStorageEditActions,
                         range editedRange: NSRange,
                         changeInLength delta: Int) {
            guard editedMask.contains(.editedCharacters) else { return }
            // NSTextStorage processes edits synchronously on the main thread; assert that
            // isolation so the @MainActor Document can be mutated here in the same turn
            // (a dispatch would apply the delta a run loop late and desync the CellBuffer).
            MainActor.assumeIsolated {
                document?.applyIncrementalEdit(range: editedRange,
                                               changeInLength: delta,
                                               newText: textStorage.string as NSString)
                // F06: keep the tracked caret-line range aligned with the shifted text so the next
                // repaint removes exactly the shifted band, not a stale numeric range. Pure arithmetic
                // only; do NOT mutate storage attributes inside didProcessEditing.
                adjustCurrentLineRange(forEditedRange: editedRange, changeInLength: delta)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let document = document else { return }

            // Prevent recursive updates. This engages for the re-entrant textDidChange the
            // maintainIndentation indent insert triggers below (F14).
            if isUpdating {
                return
            }

            // Port of Notepad++ SCN_CHARADDED handling (NppNotification.cpp:196-204):
            // maintainIndentation runs AFTER the edit is committed, inside the notification.
            // Detect the just-typed character and run indentation FIRST, so the inserted indent
            // is already committed to textStorage (the canonical store) before we signal the
            // edit; the storage delegate applied both the typed-char and indent deltas to
            // _doc.cb (F14 fixes the old order that captured text BEFORE the indent and reverted
            // it). Use UTF-16 (NSString) indexing to stay in the caret's coordinate space (F15).
            let nsText = textView.string as NSString
            let currentPos = textView.selectedRange().location
            if AppSettings.shared.maintainIndent, currentPos > 0 && currentPos <= nsText.length {
                let unit = nsText.character(at: currentPos - 1)
                // Map the UTF-16 unit to a Character; a lone surrogate maps to NUL, which
                // maintainIndentation ignores (it only acts on '\n'/'\r', always BMP units).
                let lastChar: Character = Unicode.Scalar(unit).map { Character($0) } ?? "\0"

                // Port of: if (nppGui._maintainIndent != autoIndent_none)
                //             maintainIndentation(static_cast<wchar_t>(notification->ch));
                // Guard the re-entrant textDidChange the indent insert triggers so the outer
                // pass does not run twice; the storage delegate (F09) is NOT gated by this
                // and still applies the indent delta to _doc.cb.
                isUpdating = true
                textView.maintainIndentation(character: lastChar)
                isUpdating = false
            }

            // F16: the NSTextView edited textStorage (the single canonical store) in place, and
            // the storage delegate already applied the delta to the _doc.cb mirror. `content` is
            // derived from textStorage on demand, so there is no full-string copy to refresh
            // here. Just mark the edit and publish a lightweight change signal, removing the last
            // per-keystroke O(document) cost (the textView.string bridge and whole-string compare
            // the old updateContent path did on every keystroke). The just-inserted maintain-
            // indent characters are already in textStorage (indentation ran above, before this).
            document.noteTextEdited()

            // F06/F07: paint the caret-line band FIRST, then the brace on top of it, matching the
            // documented priority (caret-line band < brace < Mark All < search). updateBracketHighlighting
            // refills the band under any cell whose brace was cleared.
            updateCurrentLineHighlight()
            updateBracketHighlighting()

            // F61: line count / numbering may have changed; repaint and re-measure the gutter. The
            // ruler already tracks scrolling on its own; this covers content edits.
            lineNumberGutter?.refresh()

            // F49: keep the Find bar's n/m count from going stale after an edit, but only while a
            // search is actually highlighting (guarded by the non-empty highlighted-range set). The
            // Find bar responds by re-posting .highlightSearchResult, which only re-paints attributes
            // and does not re-enter this character-edit path.
            if !searchHighlightRanges.isEmpty {
                NotificationCenter.default.post(name: .documentContentChanged, object: nil)
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            // O(1), selection-paced: publish the caret position for the status bar
            // (Line/Column), computed from the CellBuffer index rather than by splitting the
            // whole text (F13). caretPosition is a UTF-16 offset (SCI_GETCURRENTPOS).
            if let textView = textView {
                document?.caretPosition = textView.selectedRange().location
            }

            // Brace highlight and current-line highlight are cheap now (O(1) UTF-16
            // CellBuffer brace scan; single-line background attribute), so keep them
            // synchronous. F06/F07: caret-line band FIRST, then brace on top (documented
            // priority: caret-line band < brace < Mark All < search).
            updateCurrentLineHighlight()
            updateBracketHighlighting()

            // Smart highlight scans a range and rewrites attributes, so coalesce it: cancel
            // any pending scan and run one ~150ms after the selection settles. Faithful to
            // N++ running smart highlight over the visible window, driven by the UI rather
            // than on every selection tick (SmartHighlighter.cpp:29-98, F12).
            smartHighlightWorkItem?.cancel()
            let work = DispatchWorkItem { [weak textView] in
                textView?.updateSmartHighlight()
            }
            smartHighlightWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
        
        // Direct port of Notepad_plus::braceMatch (Notepad_plus.cpp:3019-3050), wrapped to keep the layer
        // priority correct around the transient brace repaint (F07). The caret-line band is painted FIRST
        // (updateCurrentLineHighlight runs before this), so the priority is caret-line band < brace < Mark
        // All < search. performBraceMatch clears the previous brace paint and paints the new one; a cell
        // whose old brace was cleared with no new brace on it gets the caret-line band refilled (brace sat
        // above it), while new brace cells keep the brace paint. Durable layers (search/Mark All) are then
        // re-asserted on top of both so a brace overlapping a match/mark background never erases it.
        func updateBracketHighlighting() {
            guard let textView = textView else { return }
            guard AppSettings.shared.matchBraces else {
                // Setting off: drop any lingering brace paint, restoring the caret-line band (brace sat above
                // it) then the durable layers on top.
                let cleared = textView.clearBraceLight()
                if let storage = textView.textStorage {
                    for r in cleared {
                        reassertCurrentLineBackground(over: r, in: storage)
                        reassertDurableBackground(over: r, in: storage)
                    }
                }
                return
            }
            let before = textView.braceLightRanges
            // DIRECT PORT from Notepad_plus.cpp:3019-3050: clears the previous brace paint and paints the
            // new matched pair (SCI_BRACEHIGHLIGHT :3036) or the unmatched brace red (SCI_BRACEBADLIGHT :3031).
            textView.performBraceMatch()
            let after = textView.braceLightRanges
            guard let storage = textView.textStorage else { return }
            // Cells whose OLD brace was cleared and now carry NO brace: refill the caret-line band (brace is
            // above the band) then the durable layers on top.
            for r in before where !after.contains(where: { NSIntersectionRange($0, r).length > 0 }) {
                reassertCurrentLineBackground(over: r, in: storage)
                reassertDurableBackground(over: r, in: storage)
            }
            // New brace cells keep the brace paint; only re-assert the durable layers (search/Mark All) on top.
            for r in after {
                reassertDurableBackground(over: r, in: storage)
            }
        }
        
        // Handle bracket navigation (Cmd+M to jump to matching bracket)
        @objc func jumpToMatchingBracket(_ sender: Any?) {
            guard let textView = textView else { return }
            
            // Direct translation from NppCommands.cpp line 1784-1795
            var braceAtCaret: Int = -1
            var braceOpposite: Int = -1
            
            // Line 1786: findMatchingBracePos(braceAtCaret, braceOpposite);
            textView.findMatchingBracePos(&braceAtCaret, &braceOpposite)
            
            // Line 1788-1795: Jump to matching brace if found
            if braceOpposite != -1 {
                // Set cursor position to matching brace
                textView.setSelectedRange(NSRange(location: braceOpposite, length: 0))
                textView.scrollRangeToVisible(NSRange(location: braceOpposite, length: 1))
            }
        }

        // MARK: - Find bar highlighting + navigation (F49)

        // The Find bar posts .highlightSearchResult to paint all matches and, on Find Next/Previous,
        // to move to and centre a specific match. These handlers live on the Coordinator that owns the
        // live NSTextView, so Cmd+F navigation acts on the focused editor.
        @objc func handleHighlightSearchResults(_ notification: Notification) {
            guard let textView = textView,
                  let userInfo = notification.userInfo,
                  let ranges = userInfo["ranges"] as? [NSRange] else { return }

            let currentIndex = userInfo["currentIndex"] as? Int ?? 0
            applySearchHighlights(ranges, currentIndex: currentIndex, in: textView)

            // Only Find Next/Previous include a specific "range" to move to; typing in the Find
            // field highlights every match without stealing the caret. Faithful to Notepad++,
            // which only re-centres the view on an explicit find command.
            if let range = userInfo["range"] as? NSRange {
                revealMatch(range, in: textView)
            }
        }

        @objc func handleClearSearchHighlights(_ notification: Notification) {
            guard let textView = textView else { return }
            clearSearchHighlights(in: textView)
        }

        // Paint every match (current one stronger) as a single batched attribute edit. Attribute
        // edits carry the .editedAttributes mask, not .editedCharacters, so the storage delegate
        // (F09) skips them and _doc.cb is untouched; nothing re-enters textDidChange.
        private func applySearchHighlights(_ ranges: [NSRange], currentIndex: Int, in textView: NSTextView) {
            guard let storage = textView.textStorage else { return }

            // Remove the previous search paint first (bounded to the current storage).
            clearSearchHighlights(in: textView)

            let length = storage.length
            storage.beginEditing()
            for (i, range) in ranges.enumerated() {
                guard range.location >= 0, range.length >= 0,
                      range.location + range.length <= length else { continue }
                let color = (i == currentIndex) ? Self.searchCurrentColor : Self.searchMatchColor
                storage.addAttribute(.backgroundColor, value: color, range: range)
            }
            storage.endEditing()

            searchHighlightRanges = ranges
            // F06/F07: durable reassert (current line, brace) repaints the current match with the
            // stronger colour by tracking which match index is current.
            searchCurrentIndex = currentIndex
        }

        // Remove the search paint. Bounds-checks every stored range against the CURRENT storage so a
        // document swap between highlight and clear cannot raise NSRangeException (same guard as
        // clearSmartHighlight, F03).
        func clearSearchHighlights(in textView: NSTextView) {
            guard let storage = textView.textStorage, !searchHighlightRanges.isEmpty else { return }
            let length = storage.length
            storage.beginEditing()
            for range in searchHighlightRanges {
                guard range.location >= 0, range.length >= 0,
                      range.location + range.length <= length else { continue }
                storage.removeAttribute(.backgroundColor, range: range)
            }
            storage.endEditing()
            searchHighlightRanges = []
            // Repaint the current line so removing a match background on it leaves no gap.
            updateCurrentLineHighlight()
        }

        // Move to and centre a match (Find Next/Previous). Delegates to the shared reveal helper.
        private func revealMatch(_ range: NSRange, in textView: NSTextView) {
            DocumentTextEditor.reveal(range, in: textView)
        }

        // MARK: - Bookmarks (F51)

        // Cmd+B: toggle the bookmark on the caret's line. Port of Notepad_plus::bookmarkToggle(-1)
        // (Notepad_plus.h:547), which toggles MARK_BOOKMARK on getCurrentLineNumber().
        @objc func handleToggleBookmark(_ notification: Notification) {
            MainActor.assumeIsolated {
                guard let textView = textView, let document = document else { return }
                let line = document.lineIndex(forCharacterAt: textView.selectedRange().location)
                document.toggleBookmark(atLine: line)
                mirrorPanelBookmark(document: document, textView: textView, line: line)
                lineNumberGutter?.needsDisplay = true
            }
        }

        // Cmd+Shift+B / Cmd+Opt+B: go to the next / previous bookmark with wraparound. Port of
        // Notepad_plus::bookmarkNext (Notepad_plus.cpp:5143): SCI_MARKERNEXT/PREVIOUS then SCI_GOTOLINE.
        @objc func handleNextBookmark(_ notification: Notification) { gotoBookmark(forward: true) }
        @objc func handlePreviousBookmark(_ notification: Notification) { gotoBookmark(forward: false) }

        private func gotoBookmark(forward: Bool) {
            MainActor.assumeIsolated {
                guard let textView = textView, let document = document else { return }
                let caretLine = document.lineIndex(forCharacterAt: textView.selectedRange().location)
                guard let target = document.bookmarkLine(after: caretLine, forward: forward) else { return }
                let start = document.lineStartPosition(target)
                DocumentTextEditor.reveal(NSRange(location: start, length: 0), in: textView)
                textView.window?.makeFirstResponder(textView)
            }
        }

        // Mirror an in-editor bookmark into the persistent, cross-session Bookmarks panel for SAVED
        // files (AdvancedSearchManager.bookmarks is filePath-keyed). Untitled documents keep their
        // bookmarks in-editor only, matching Notepad++ where bookmarks live in the buffer.
        @MainActor
        private func mirrorPanelBookmark(document: Document, textView: NSTextView, line: Int) {
            guard let url = document.fileURL else { return }
            let present = document.isBookmarked(line: line)
            let ns = textView.string as NSString
            let anchor = min(document.lineStartPosition(line), ns.length)
            let lineRange = ns.lineRange(for: NSRange(location: anchor, length: 0))
            let content = ns.substring(with: lineRange).trimmingCharacters(in: .newlines)
            AdvancedSearchManager.shared.setPanelBookmark(url: url, lineNumber: line + 1,
                                                          lineContent: content, present: present)
        }

        // MARK: - Mark All / Clear Marks (F52)

        // Search menu Mark All: paint every occurrence of the current selection with a mark background,
        // attribute-only (so it never re-enters the character-edit path or touches _doc.cb, exactly like
        // the F49 search highlight). Port of FindReplaceDlg::markAll -> processAll ProcessMarkAll
        // (FindReplaceDlg.cpp:3279/3666), which fills an indicator over every found range.
        @objc func handleMarkAll(_ notification: Notification) {
            MainActor.assumeIsolated {
                guard let textView = textView else { return }
                let ns = textView.string as NSString
                // Mark the selection; with no selection, mark the word under the caret (like Notepad++
                // Mark All operating on the current word).
                var target = textView.selectedRange()
                if target.length == 0 {
                    target = textView.selectionRange(forProposedRange: target, granularity: .selectByWord)
                }
                guard target.length > 0, target.location + target.length <= ns.length else { return }
                let needle = ns.substring(with: target)
                guard !needle.isEmpty else { return }

                clearMarks(in: textView)
                var ranges: [NSRange] = []
                var searchStart = 0
                while searchStart < ns.length {
                    let found = ns.range(of: needle, options: [],
                                         range: NSRange(location: searchStart, length: ns.length - searchStart))
                    if found.location == NSNotFound { break }
                    ranges.append(found)
                    searchStart = found.location + max(1, found.length)
                }
                applyMarks(ranges, in: textView)
            }
        }

        @objc func handleClearMarks(_ notification: Notification) {
            MainActor.assumeIsolated {
                guard let textView = textView else { return }
                clearMarks(in: textView)
            }
        }

        private func applyMarks(_ ranges: [NSRange], in textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let length = storage.length
            storage.beginEditing()
            for range in ranges where range.location >= 0 && range.location + range.length <= length {
                storage.addAttribute(.backgroundColor, value: Self.markAllColor, range: range)
            }
            storage.endEditing()
            markedSearchRanges = ranges
            lineNumberGutter?.needsDisplay = true
        }

        // Remove Mark All backgrounds, bounds-checked against the CURRENT storage (a doc swap between
        // mark and clear cannot raise NSRangeException). Repaints the current line so no gap remains.
        func clearMarks(in textView: NSTextView) {
            guard let storage = textView.textStorage, !markedSearchRanges.isEmpty else { return }
            let length = storage.length
            storage.beginEditing()
            for range in markedSearchRanges where range.location >= 0 && range.location + range.length <= length {
                storage.removeAttribute(.backgroundColor, range: range)
            }
            storage.endEditing()
            markedSearchRanges = []
            updateCurrentLineHighlight()
        }

        // F04: undo lives in the Document (Scintilla model). Returning the current
        // document's own UndoManager means a tab switch swaps undo history and Cmd+Z
        // can never replay another document's edits.
        func undoManager(for view: NSTextView) -> UndoManager? {
            return document?.undoManager
        }

        // F03: clear all transient painted attributes (smart highlight, current line,
        // brace match/bad-light backgrounds) from the storage the view currently holds, and
        // reset the stored mark ranges. Called on the OUTGOING storage before a document swap.
        // Removing over the storage full range is always in bounds, so it cannot raise
        // NSRangeException.
        func clearPaintedAttributes(on textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            if storage.length > 0 {
                let fullRange = NSRange(location: 0, length: storage.length)
                storage.removeAttribute(.backgroundColor, range: fullRange)
            }
            currentLineRange = nil
            // F07: brace paint is tracked on the text view now; the full-range removeAttribute above
            // already wiped it, so drop the stale brace ranges so the next brace update starts clean.
            textView.braceLightRanges = []
            textView.clearSmartHighlight()
            // F49: the outgoing storage's search paint was just wiped by the full-range
            // removeAttribute above; drop the stale ranges so a later clear does not touch the new
            // document's storage with the old document's offsets.
            searchHighlightRanges = []
            // F52: same for Mark All ranges.
            markedSearchRanges = []
        }

        // Re-assert the durable layers (F49 search, F52 Mark All) over `range` so a transient repaint
        // (current line F06, brace F07) that cleared .backgroundColor there does not erase them. Search
        // draws on top of Mark All, both on top of the caret-line band, mirroring Scintilla indicators
        // painted over the caret-line background.
        func reassertDurableBackground(over range: NSRange, in storage: NSTextStorage) {
            guard range.length > 0, range.location >= 0, NSMaxRange(range) <= storage.length else { return }
            for r in markedSearchRanges {
                let inter = NSIntersectionRange(r, range)
                if inter.length > 0 { storage.addAttribute(.backgroundColor, value: Self.markAllColor, range: inter) }
            }
            for (i, r) in searchHighlightRanges.enumerated() {
                let inter = NSIntersectionRange(r, range)
                if inter.length > 0 {
                    storage.addAttribute(.backgroundColor,
                                         value: i == searchCurrentIndex ? Self.searchCurrentColor : Self.searchMatchColor,
                                         range: inter)
                }
            }
        }

        // Refill the caret-line band over `range` (its intersection with the current line). Used to restore
        // the band under a brace cell that was just cleared. Brace sits ABOVE the band, so callers run this
        // only for cells that no longer carry a brace paint.
        func reassertCurrentLineBackground(over range: NSRange, in storage: NSTextStorage) {
            guard highlightCurrentLine, let lineRange = currentLineRange else { return }
            let inter = NSIntersectionRange(lineRange, range)
            guard inter.length > 0, NSMaxRange(inter) <= storage.length else { return }
            let color = NSColor(hex: currentLineColor) ?? ThemeManager.shared.currentTheme.currentLineColor
            storage.addAttribute(.backgroundColor, value: color, range: inter)
        }

        // F06: the caret-line background band. Scintilla draws the caret-line background as a separate
        // layer under the indicators (SCI_SETCARETLINEBACK); here it is a single .backgroundColor band
        // that must always be cleared/redrawn on the RIGHT characters and must never erase the durable
        // search/Mark All paint underneath it.
        func updateCurrentLineHighlight() {
            guard let textView = textView, let storage = textView.textStorage else { return }
            // Toggle-off: clear the last band and stop, so disabling the setting does not leave a line
            // permanently highlighted (F06). Scintilla stops filling the caret-line background when the
            // element colour is cleared.
            guard highlightCurrentLine else { clearCurrentLineHighlight(); return }

            let text = textView.string as NSString
            let selectedRange = textView.selectedRange()
            let length = storage.length

            // Remove the previous band clamped to the CURRENT length (F06: a deletion that shrank the doc
            // below the stored range must still clear it, never skip), then re-assert durable search/Mark
            // All over the cleared span so leaving a line never erases a match/mark background on it.
            if let previous = currentLineRange {
                let clamped = NSIntersectionRange(previous, NSRange(location: 0, length: length))
                if clamped.length > 0 {
                    storage.removeAttribute(.backgroundColor, range: clamped)
                    reassertDurableBackground(over: clamped, in: storage)
                }
                currentLineRange = nil
            }

            guard selectedRange.location <= text.length else { return }
            var lineStart = 0, lineEnd = 0, contentsEnd = 0
            let safe = NSRange(location: min(selectedRange.location, text.length), length: 0)
            text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: safe)
            let lineRange = NSRange(location: lineStart, length: max(0, lineEnd - lineStart))
            guard NSMaxRange(lineRange) <= length else { return }

            let color = NSColor(hex: currentLineColor) ?? ThemeManager.shared.currentTheme.currentLineColor
            storage.addAttribute(.backgroundColor, value: color, range: lineRange)
            // Durable layers paint on top of the caret-line band (Scintilla indicators over caret-line back).
            reassertDurableBackground(over: lineRange, in: storage)
            currentLineRange = lineRange
        }

        // Remove the current-line band (clamped) and forget it, preserving durable paints underneath.
        func clearCurrentLineHighlight() {
            guard let textView = textView, let storage = textView.textStorage, let previous = currentLineRange else { return }
            let clamped = NSIntersectionRange(previous, NSRange(location: 0, length: storage.length))
            if clamped.length > 0 {
                storage.removeAttribute(.backgroundColor, range: clamped)
                reassertDurableBackground(over: clamped, in: storage)
            }
            currentLineRange = nil
        }

        // Keep currentLineRange aligned with the caret-line band after an edit shifts the text (F06). The
        // band's .backgroundColor already moves with the characters; this mirrors that so the next repaint
        // removes exactly the shifted range rather than a stale numeric range that would orphan the band or
        // strip another line's search/Mark All background.
        private func adjustCurrentLineRange(forEditedRange edited: NSRange, changeInLength delta: Int) {
            guard var range = currentLineRange else { return }
            let editStart = edited.location
            if editStart >= NSMaxRange(range) { return }              // edit at/after the band: unaffected
            if editStart <= range.location { range.location = max(0, range.location + delta) } // before: shift
            else { range.length = max(0, range.length + delta) }      // inside: grow/shrink
            currentLineRange = range
        }
    }
}

// Extension moved to PerformanceManager