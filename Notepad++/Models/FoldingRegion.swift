//
//  FoldingRegion.swift
//  Notepad++
//
//  Code folding region model for collapsible code blocks
//

import Foundation

struct FoldingRegion: Identifiable, Equatable {
    let id = UUID()
    let startLine: Int
    let endLine: Int
    let level: Int
    var isCollapsed: Bool = false
    let type: FoldingType
    
    enum FoldingType {
        case function
        case classType
        case method
        case block
        case comment
        case region
        case array
        case object
    }
    
    var lineRange: ClosedRange<Int> {
        startLine...endLine
    }
    
    func contains(line: Int) -> Bool {
        return line >= startLine && line <= endLine
    }
    
    func overlaps(with other: FoldingRegion) -> Bool {
        return startLine <= other.endLine && endLine >= other.startLine
    }
}

class FoldingState: ObservableObject {
    @Published var regions: [FoldingRegion] = []
    @Published var collapsedLines: Set<Int> = []
    
    func toggleFold(at line: Int) {
        if let regionIndex = regions.firstIndex(where: { $0.startLine == line }) {
            regions[regionIndex].isCollapsed.toggle()
            updateCollapsedLines()
        }
    }
    
    func foldAll() {
        for index in regions.indices {
            regions[index].isCollapsed = true
        }
        updateCollapsedLines()
    }
    
    func unfoldAll() {
        for index in regions.indices {
            regions[index].isCollapsed = false
        }
        updateCollapsedLines()
    }
    
    func isFoldableHeader(line: Int) -> Bool {
        return regions.contains { $0.startLine == line }
    }
    
    func isLineVisible(line: Int) -> Bool {
        return !collapsedLines.contains(line)
    }
    
    private func updateCollapsedLines() {
        collapsedLines.removeAll()
        
        for region in regions where region.isCollapsed {
            for line in (region.startLine + 1)...region.endLine {
                collapsedLines.insert(line)
            }
        }
    }
    
    func updateRegions(_ newRegions: [FoldingRegion]) {
        // F21: carry over collapsed state via an O(1) map keyed by (start,end), built once
        // from the OLD regions, instead of `regions.first(where:)` per new region, which was
        // O(old x new) on every fold recompute. Per-line fold state persistence mirrors
        // Document::SetLevel (scintilla-reference/src/Document.cxx:603).
        var collapsedByKey: [FoldKey: Bool] = [:]
        for region in regions {
            collapsedByKey[FoldKey(start: region.startLine, end: region.endLine)] = region.isCollapsed
        }

        var updatedRegions = newRegions
        for index in updatedRegions.indices {
            let key = FoldKey(start: updatedRegions[index].startLine, end: updatedRegions[index].endLine)
            if let wasCollapsed = collapsedByKey[key] {
                updatedRegions[index].isCollapsed = wasCollapsed
            }
        }

        self.regions = updatedRegions
        updateCollapsedLines()
    }
}

// F21: hashable (start,end) key for O(1) collapsed-state carry-over in updateRegions.
private struct FoldKey: Hashable {
    let start: Int
    let end: Int
}