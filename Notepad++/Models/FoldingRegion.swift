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
        // Preserve collapsed state for existing regions at same locations
        var updatedRegions = newRegions
        
        for (index, newRegion) in updatedRegions.enumerated() {
            if let existingRegion = regions.first(where: { 
                $0.startLine == newRegion.startLine && 
                $0.endLine == newRegion.endLine 
            }) {
                updatedRegions[index].isCollapsed = existingRegion.isCollapsed
            }
        }
        
        self.regions = updatedRegions
        updateCollapsedLines()
    }
}