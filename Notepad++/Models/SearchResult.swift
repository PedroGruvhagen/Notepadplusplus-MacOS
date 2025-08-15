//
//  SearchResult.swift
//  Notepad++
//
//  Model for advanced search features
//

import Foundation

// MARK: - Search Result Models

struct FileSearchResult: Identifiable, Hashable {
    var id = UUID()
    let filePath: URL
    let fileName: String
    let matches: [LineMatch]
    
    var matchCount: Int {
        matches.count
    }
}

struct LineMatch: Identifiable, Hashable {
    var id = UUID()
    let lineNumber: Int
    let lineContent: String
    let matchRanges: [NSRange]
    let contextBefore: String?
    let contextAfter: String?
}

// MARK: - Bookmark Model

struct Bookmark: Identifiable, Codable, Hashable {
    var id = UUID()
    let filePath: URL
    let lineNumber: Int
    let lineContent: String
    let label: String?
    let dateCreated: Date
    
    init(filePath: URL, lineNumber: Int, lineContent: String, label: String? = nil) {
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.lineContent = lineContent
        self.label = label
        self.dateCreated = Date()
    }
}

// MARK: - Search History

struct SearchHistoryItem: Identifiable, Codable {
    var id = UUID()
    let searchText: String
    let isRegex: Bool
    let isCaseSensitive: Bool
    let isWholeWord: Bool
    let searchScope: SearchScope
    let dateSearched: Date
    
    enum SearchScope: String, Codable {
        case currentDocument
        case openDocuments
        case directory
        case project
    }
    
    init(searchText: String, isRegex: Bool = false, isCaseSensitive: Bool = false, 
         isWholeWord: Bool = false, searchScope: SearchScope = .currentDocument) {
        self.searchText = searchText
        self.isRegex = isRegex
        self.isCaseSensitive = isCaseSensitive
        self.isWholeWord = isWholeWord
        self.searchScope = searchScope
        self.dateSearched = Date()
    }
}

// MARK: - Search Configuration

struct FindInFilesConfiguration {
    var searchPath: URL?
    var includeSubfolders: Bool = true
    var fileFilters: [String] = [] // e.g., ["*.swift", "*.txt"]
    var excludeFilters: [String] = [] // e.g., ["*.log", "node_modules"]
    var maxResults: Int = 1000
    var contextLines: Int = 2 // Lines before/after match
}

// MARK: - Mark All Configuration

struct MarkAllConfiguration {
    var highlightColor: String = "#FFFF00" // Yellow
    var markStyle: MarkStyle = .highlight
    var clearOnTextChange: Bool = false
    
    enum MarkStyle {
        case highlight
        case underline
        case box
        case bookmark
    }
}