//
//  SearchOptions.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation

class SearchOptions: ObservableObject {
    @Published var searchText: String = ""
    @Published var replaceText: String = ""
    @Published var caseSensitive: Bool = false
    @Published var wholeWord: Bool = false
    @Published var useRegex: Bool = false
    @Published var wrapAround: Bool = true
    
    func reset() {
        searchText = ""
        replaceText = ""
        caseSensitive = false
        wholeWord = false
        useRegex = false
        wrapAround = true
    }
}

struct SimpleSearchResult {
    let range: NSRange
    let lineNumber: Int
    let preview: String
}

class SearchManager: ObservableObject {
    @Published var isSearchVisible = false
    @Published var isReplaceVisible = false
    @Published var currentMatchIndex = 0
    @Published var totalMatches = 0
    @Published var searchResults: [SimpleSearchResult] = []
    
    private var currentDocument: Document?
    private let searchOptions = SearchOptions()
    
    func showFind() {
        isSearchVisible = true
        isReplaceVisible = false
    }
    
    func showReplace() {
        isSearchVisible = true
        isReplaceVisible = true
    }
    
    func hide() {
        isSearchVisible = false
        isReplaceVisible = false
        searchResults.removeAll()
        currentMatchIndex = 0
        totalMatches = 0
    }
    
    func findAll(in text: String, searchText: String, options: SearchOptions) -> [NSRange] {
        guard !searchText.isEmpty else { return [] }
        
        var pattern = searchText
        var regexOptions: NSRegularExpression.Options = []
        
        if !options.useRegex {
            pattern = NSRegularExpression.escapedPattern(for: searchText)
        }
        
        if options.wholeWord {
            pattern = "\\b\(pattern)\\b"
        }
        
        if !options.caseSensitive {
            regexOptions.insert(.caseInsensitive)
        }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            return matches.map { $0.range }
        } catch {
            print("Regex error: \(error)")
            return []
        }
    }
    
    @MainActor
    func findNext(in document: Document, from position: Int) -> NSRange? {
        let ranges = findAll(in: document.content, searchText: searchOptions.searchText, options: searchOptions)
        
        guard !ranges.isEmpty else {
            totalMatches = 0
            return nil
        }
        
        totalMatches = ranges.count
        
        // Find next match after current position
        if let nextIndex = ranges.firstIndex(where: { $0.location > position }) {
            currentMatchIndex = nextIndex + 1
            return ranges[nextIndex]
        } else if searchOptions.wrapAround && !ranges.isEmpty {
            // Wrap around to beginning
            currentMatchIndex = 1
            return ranges[0]
        }
        
        return nil
    }
    
    @MainActor
    func findPrevious(in document: Document, from position: Int) -> NSRange? {
        let ranges = findAll(in: document.content, searchText: searchOptions.searchText, options: searchOptions)
        
        guard !ranges.isEmpty else {
            totalMatches = 0
            return nil
        }
        
        totalMatches = ranges.count
        
        // Find previous match before current position
        if let prevIndex = ranges.lastIndex(where: { $0.location < position }) {
            currentMatchIndex = prevIndex + 1
            return ranges[prevIndex]
        } else if searchOptions.wrapAround && !ranges.isEmpty {
            // Wrap around to end
            currentMatchIndex = ranges.count
            return ranges.last
        }
        
        return nil
    }
    
    @MainActor
    func replace(in document: Document, at range: NSRange) -> String {
        let nsString = document.content as NSString
        return nsString.replacingCharacters(in: range, with: searchOptions.replaceText)
    }
    
    @MainActor
    func replaceAll(in document: Document) -> (String, Int) {
        let ranges = findAll(in: document.content, searchText: searchOptions.searchText, options: searchOptions)
        
        guard !ranges.isEmpty else { return (document.content, 0) }
        
        var newContent = document.content as NSString
        
        // Replace from end to beginning to maintain indices
        for range in ranges.reversed() {
            let adjustedRange = NSRange(location: range.location, length: range.length)
            newContent = newContent.replacingCharacters(in: adjustedRange, with: searchOptions.replaceText) as NSString
        }
        
        return (newContent as String, ranges.count)
    }
}