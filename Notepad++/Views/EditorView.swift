//
//  EditorView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct EditorView: View {
    @ObservedObject var document: Document
    @FocusState private var isEditorFocused: Bool
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var searchManager = AdvancedSearchManager.shared
    
    // Performance optimizations
    private var optimizedSettings: OptimizedSettings {
        document.getOptimizedSettings()
    }
    @State private var showFindReplace = false
    @State private var showReplaceBar = false
    @State private var showFindInFiles = false
    @State private var showBookmarks = false
    @State private var localContent: String = ""
    // F19/F20: debounced fold-region detection. Moved here from the removed gutter view.
    @State private var foldDetectWork: DispatchWorkItem?
    
    // Each document gets its own syntax highlighter instance
    // This mirrors Notepad++ where each buffer has its own lexer state
    private var syntaxHighlighter: SyntaxHighlighter {
        document.syntaxHighlighter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Find/Replace bar
            if showFindReplace {
                FindReplaceBar(
                    document: document,
                    showReplace: $showReplaceBar,
                    isVisible: $showFindReplace
                )
            }
            
            // F61: the line-number gutter is EditorGutterView, a plain NSView laid out beside the
            // editor's scroll view inside DocumentTextEditor's EditorContainerView, so it scrolls with
            // the text by construction (see EditorLineNumberRulerView.swift's header comment for the
            // full history: an even older sibling SwiftUI gutter, then an NSRulerView-based gutter that
            // was purged and rebuilt as this plain-NSView design). showLineNumbers toggles the gutter.
            // Keeping ONE DocumentTextEditor call site means the representable identity never flips, so
            // the editor and its Coordinator are not torn down and recreated (F01).
            DocumentTextEditor(
                document: document,
                fontSize: CGFloat(settings.fontSize),
                fontName: settings.fontName,
                wordWrap: settings.wordWrap,
                showWhitespace: settings.showWhitespace,
                showEndOfLine: settings.showEndOfLine,
                highlightCurrentLine: settings.highlightCurrentLine,
                currentLineColor: settings.currentLineColor,
                showIndentGuides: settings.showIndentGuides,
                caretWidth: CGFloat(settings.caretWidth),
                caretBlinkRate: settings.caretBlinkRate,
                scrollBeyondLastLine: settings.scrollBeyondLastLine,
                showLineNumbers: optimizedSettings.showLineNumbers,
                tabSize: settings.tabSize,
                replaceTabsBySpaces: settings.replaceTabsBySpaces,
                maintainIndent: settings.maintainIndent,
                autoIndent: settings.autoIndent,
                smartIndent: settings.smartIndent,
                syntaxHighlightingEnabled: optimizedSettings.syntaxHighlighting
            )
            .focused($isEditorFocused)
            .onAppear {
                isEditorFocused = true
                scheduleFoldDetection()
            }
            
            if settings.showStatusBar {
                StatusBarView(document: document)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFind)) { _ in
            showFindReplace = true
            showReplaceBar = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .showReplace)) { _ in
            showFindReplace = true
            showReplaceBar = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .foldAll)) { _ in
            // F20: only fold when folding is actually enabled for this document (setting on AND not a
            // large file, via the cached OptimizedSettings). Fold All on a large file must be inert.
            if optimizedSettings.codeFolding { document.foldingState.foldAll() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .unfoldAll)) { _ in
            document.foldingState.unfoldAll()
        }
        // F19/F20: recompute fold regions when the text settles (debounced). Gated inside on the
        // document's OptimizedSettings.codeFolding so large files (fold detection disabled) pay nothing.
        .onChange(of: document.textVersion) {
            scheduleFoldDetection()
        }
        // F20 / live setting toggles: the OptimizedSettings cache feeds the fold gate, Show Line
        // Numbers, and syntax highlighting; invalidate it so toggling these View-menu items takes
        // effect immediately instead of only after the next save.
        .onChange(of: settings.codeFolding) {
            document.invalidateOptimizedSettings()
            scheduleFoldDetection()
        }
        .onChange(of: settings.showLineNumbers) {
            document.invalidateOptimizedSettings()
        }
        .onChange(of: settings.syntaxHighlighting) {
            document.invalidateOptimizedSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFindInFiles)) { _ in
            showFindInFiles = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBookmarks)) { _ in
            showBookmarks = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .convertEOL)) { notification in
            if let eolType = notification.object as? EOLType {
                document.convertEOL(to: eolType)
            }
        }
        .sheet(isPresented: $showFindInFiles) {
            FindInFilesView()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView()
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { settings.showLineNumbers.toggle() }) {
                    Image(systemName: settings.showLineNumbers ? "number.square.fill" : "number.square")
                }
                .help("Toggle Line Numbers")
                
                Button(action: { settings.wordWrap.toggle() }) {
                    Image(systemName: settings.wordWrap ? "text.alignleft" : "arrow.right.to.line")
                }
                .help("Toggle Word Wrap")
                
                Button(action: { settings.syntaxHighlighting.toggle() }) {
                    Image(systemName: settings.syntaxHighlighting ? "paintbrush.fill" : "paintbrush")
                }
                .help("Toggle Syntax Highlighting")
                
                Divider()
                
                Button(action: { if settings.fontSize > 8 { settings.fontSize -= 1 } }) {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("Decrease Font Size")
                
                Button(action: { if settings.fontSize < 24 { settings.fontSize += 1 } }) {
                    Image(systemName: "textformat.size.larger")
                }
                .help("Increase Font Size")
            }
        }
    }

    // F19/F20: coalesce fold-region detection ~250 ms after typing settles (moved here from the
    // removed EnhancedLineNumberView). Gated on the document's OptimizedSettings.codeFolding so a
    // large file (fold detection disabled) never runs the scan; when folding is off, any stale
    // regions are cleared so the folding layout delegate shows every line (F20).
    private func scheduleFoldDetection() {
        guard optimizedSettings.codeFolding else {
            if !document.foldingState.regions.isEmpty {
                document.foldingState.updateRegions([])
            }
            return
        }
        foldDetectWork?.cancel()
        let doc = document
        let work = DispatchWorkItem {
            let regions = FoldingManager.detectFoldingRegions(in: doc.content, language: doc.language)
            doc.foldingState.updateRegions(regions)
        }
        foldDetectWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}

struct StatusBarView: View {
    @ObservedObject var document: Document

    var body: some View {
        HStack {
            Text(document.fileName)
                .font(.system(size: 11))

            if document.isModified {
                Text("Modified")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }

            Spacer()

            // F13: the CARET line/column from the CellBuffer index (O(log n) binary search),
            // not by splitting the whole content per render. Shows the caret position
            // (SCI_LINEFROMPOSITION(SCI_GETCURRENTPOS) / SCI_GETCOLUMN), not total lines and
            // last-line length. caretPosition is @Published so this refreshes on caret moves.
            Text("Line \(document.statusLineColumn.line), Column \(document.statusLineColumn.column)")
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)
            
            Text(document.eolType.shortName)
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)

            // F34: the encoding is a user-changeable property (Notepad++ Encoding menu / Buffer.cpp
            // setEncoding). Surfacing it as a menu here gives a discoverable escape hatch: if a file
            // cannot be written in its current encoding, the user can switch it to UTF-8 (or another
            // encoding) and re-save, instead of being stuck. changeEncoding marks the buffer dirty.
            Menu {
                ForEach(FileEncoding.allCases, id: \.self) { enc in
                    Button {
                        document.changeEncoding(enc)
                    } label: {
                        if enc == document.encoding {
                            Label(enc.displayName, systemImage: "checkmark")
                        } else {
                            Text(enc.displayName)
                        }
                    }
                }
            } label: {
                Text(document.encoding.displayName)
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Change file encoding")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}