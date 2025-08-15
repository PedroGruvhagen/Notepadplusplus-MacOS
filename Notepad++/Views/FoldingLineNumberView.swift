//
//  FoldingLineNumberView.swift
//  Notepad++
//
//  Line number view with code folding indicators
//

import SwiftUI

struct FoldingLineNumberView: View {
    let text: String
    let fontSize: CGFloat
    @ObservedObject var foldingState: FoldingState
    @State private var hoveredLine: Int? = nil
    
    private var lines: [String] {
        text.isEmpty ? [""] : text.components(separatedBy: .newlines)
    }
    
    private var visibleLines: [(lineNumber: Int, isHeader: Bool, isCollapsed: Bool)] {
        var result: [(Int, Bool, Bool)] = []
        
        for lineIndex in 0..<lines.count {
            if foldingState.isLineVisible(line: lineIndex) {
                let isHeader = foldingState.isFoldableHeader(line: lineIndex)
                let region = foldingState.regions.first { $0.startLine == lineIndex }
                let isCollapsed = region?.isCollapsed ?? false
                result.append((lineIndex + 1, isHeader, isCollapsed))
            }
        }
        
        return result
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(visibleLines, id: \.lineNumber) { item in
                        HStack(spacing: 2) {
                            // Folding indicator
                            if item.isHeader {
                                Button(action: {
                                    foldingState.toggleFold(at: item.lineNumber - 1)
                                }) {
                                    Image(systemName: item.isCollapsed ? "chevron.right" : "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: 12, height: 12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help(item.isCollapsed ? "Unfold" : "Fold")
                            } else {
                                Spacer()
                                    .frame(width: 12, height: 12)
                            }
                            
                            // Line number
                            Text("\(item.lineNumber)")
                                .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                                .foregroundColor(hoveredLine == item.lineNumber ? .primary : .secondary)
                                .frame(minWidth: 30, alignment: .trailing)
                                .onHover { isHovered in
                                    hoveredLine = isHovered ? item.lineNumber : nil
                                }
                        }
                        .padding(.horizontal, 4)
                        .frame(height: fontSize * 1.5)
                        .id(item.lineNumber)
                    }
                }
            }
        }
        .frame(width: 65)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// Update the existing LineNumberView to support folding
struct EnhancedLineNumberView: View {
    let document: Document
    let fontSize: CGFloat
    @State private var foldingRegions: [FoldingRegion] = []
    
    var body: some View {
        Group {
            if AppSettings.shared.codeFolding {
                FoldingLineNumberView(
                    text: document.content,
                    fontSize: fontSize,
                    foldingState: document.foldingState
                )
                .onAppear {
                    updateFoldingRegions()
                }
                .onChange(of: document.content) {
                    updateFoldingRegions()
                }
            } else {
                // Original line number view
                LineNumberView(
                    text: document.content,
                    fontSize: fontSize
                )
            }
        }
    }
    
    private func updateFoldingRegions() {
        let regions = FoldingManager.detectFoldingRegions(
            in: document.content,
            language: document.language
        )
        document.foldingState.updateRegions(regions)
    }
}