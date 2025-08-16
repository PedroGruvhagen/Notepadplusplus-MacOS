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
            
            if optimizedSettings.showLineNumbers {
                HStack(alignment: .top, spacing: 0) {
                    EnhancedLineNumberView(document: document, fontSize: CGFloat(settings.fontSize))
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
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
                        scrollBeyondLastLine: settings.scrollBeyondLastLine,
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
                    }
                }
            } else {
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
                    scrollBeyondLastLine: settings.scrollBeyondLastLine,
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
                }
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
            document.foldingState.foldAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .unfoldAll)) { _ in
            document.foldingState.unfoldAll()
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
}

struct LineNumberView: View {
    let text: String
    let fontSize: CGFloat
    
    private var lineCount: Int {
        text.isEmpty ? 1 : text.filter { $0 == "\n" }.count + 1
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...lineCount, id: \.self) { lineNumber in
                    Text("\(lineNumber)")
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .disabled(true)
    }
}

struct StatusBarView: View {
    @ObservedObject var document: Document
    
    private var lineColumn: (Int, Int) {
        // Simplified line/column calculation
        let lines = document.content.components(separatedBy: "\n")
        return (lines.count, lines.last?.count ?? 0)
    }
    
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
            
            Text("Line \(lineColumn.0), Column \(lineColumn.1)")
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)
            
            Text(document.eolType.shortName)
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)
            
            Text(document.encoding.displayName)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}