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
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true
    @State private var wordWrap = true
    
    var body: some View {
        VStack(spacing: 0) {
            if showLineNumbers {
                HStack(alignment: .top, spacing: 0) {
                    LineNumberView(text: document.content, fontSize: fontSize)
                        .frame(width: 50)
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    TextEditor(text: Binding(
                        get: { document.content },
                        set: { document.updateContent($0) }
                    ))
                    .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                    .focused($isEditorFocused)
                    .onAppear {
                        isEditorFocused = true
                    }
                }
            } else {
                TextEditor(text: Binding(
                    get: { document.content },
                    set: { document.updateContent($0) }
                ))
                .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                .focused($isEditorFocused)
                .onAppear {
                    isEditorFocused = true
                }
            }
            
            StatusBarView(document: document)
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showLineNumbers.toggle() }) {
                    Image(systemName: "number")
                }
                .help("Toggle Line Numbers")
                
                Button(action: { wordWrap.toggle() }) {
                    Image(systemName: "text.wrap")
                }
                .help("Toggle Word Wrap")
                
                Divider()
                
                Button(action: { if fontSize > 8 { fontSize -= 1 } }) {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("Decrease Font Size")
                
                Button(action: { if fontSize < 24 { fontSize += 1 } }) {
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
            
            Text("UTF-8")
                .font(.system(size: 11))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}