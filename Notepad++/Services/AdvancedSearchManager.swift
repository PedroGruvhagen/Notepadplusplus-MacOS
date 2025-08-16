//
//  SearchManager.swift
//  Notepad++
//
//  Service for advanced search features
//

import Foundation
import SwiftUI

@MainActor
class AdvancedSearchManager: ObservableObject {
    static let shared = AdvancedSearchManager()
    
    // MARK: - Published Properties
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var bookmarks: [Bookmark] = []
    @Published var currentSearchResults: [FileSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var searchProgress: Double = 0.0
    @Published var markedRanges: [NSRange] = []
    
    // MARK: - Private Properties
    private let maxHistoryItems = 50
    private let userDefaults = UserDefaults.standard
    private let historyKey = "SearchHistory"
    private let bookmarksKey = "Bookmarks"
    
    init() {
        loadSearchHistory()
        loadBookmarks()
    }
    
    // MARK: - Find in Files
    
    func findInFiles(searchText: String, configuration: FindInFilesConfiguration, options: SearchOptions) async {
        await MainActor.run {
            isSearching = true
            searchProgress = 0.0
            currentSearchResults = []
        }
        
        guard let searchPath = configuration.searchPath else { return }
        
        do {
            let fileURLs = try await getSearchableFiles(at: searchPath, configuration: configuration)
            let totalFiles = fileURLs.count
            var results: [FileSearchResult] = []
            
            for (index, fileURL) in fileURLs.enumerated() {
                // Update progress
                let progressValue = Double(index) / Double(totalFiles)
                await MainActor.run {
                    searchProgress = progressValue
                }
                
                // Search in file
                if let fileResult = await searchInFile(fileURL: fileURL, searchText: searchText, options: options, configuration: configuration) {
                    results.append(fileResult)
                    
                    // Update results incrementally
                    if results.count % 10 == 0 {
                        let currentResults = results
                        await MainActor.run {
                            currentSearchResults = currentResults
                        }
                    }
                }
                
                // Check max results limit
                if results.count >= configuration.maxResults {
                    break
                }
            }
            
            let finalResults = results
            await MainActor.run {
                currentSearchResults = finalResults
                isSearching = false
                searchProgress = 1.0
            }
            
        } catch {
            print("Error finding in files: \(error)")
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func getSearchableFiles(at path: URL, configuration: FindInFilesConfiguration) async throws -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []
        
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        let options: FileManager.DirectoryEnumerationOptions = configuration.includeSubfolders ? [] : [.skipsSubdirectoryDescendants]
        
        if let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: options) {
            let urls = enumerator.allObjects.compactMap { $0 as? URL }
            for fileURL in urls {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                guard resourceValues.isRegularFile == true else { continue }
                
                let fileName = fileURL.lastPathComponent
                
                // Apply filters
                if !configuration.fileFilters.isEmpty {
                    let matchesFilter = configuration.fileFilters.contains { filter in
                        matchesWildcard(fileName, pattern: filter)
                    }
                    if !matchesFilter { continue }
                }
                
                // Apply exclusions
                let shouldExclude = configuration.excludeFilters.contains { filter in
                    matchesWildcard(fileName, pattern: filter) ||
                    fileURL.path.contains(filter)
                }
                if shouldExclude { continue }
                
                files.append(fileURL)
            }
        }
        
        return files
    }
    
    private func searchInFile(fileURL: URL, searchText: String, options: SearchOptions, configuration: FindInFilesConfiguration) async -> FileSearchResult? {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            var matches: [LineMatch] = []
            
            for (index, line) in lines.enumerated() {
                let lineNumber = index + 1
                let matchRanges = findMatches(in: line, searchText: searchText, options: options)
                
                if !matchRanges.isEmpty {
                    let contextBefore = index > 0 ? lines[max(0, index - configuration.contextLines)...index-1].joined(separator: "\n") : nil
                    let contextAfter = index < lines.count - 1 ? lines[index+1...min(lines.count-1, index + configuration.contextLines)].joined(separator: "\n") : nil
                    
                    let match = LineMatch(
                        lineNumber: lineNumber,
                        lineContent: line,
                        matchRanges: matchRanges,
                        contextBefore: contextBefore,
                        contextAfter: contextAfter
                    )
                    matches.append(match)
                }
            }
            
            if !matches.isEmpty {
                return FileSearchResult(
                    filePath: fileURL,
                    fileName: fileURL.lastPathComponent,
                    matches: matches
                )
            }
            
        } catch {
            // Silently skip files that can't be read
        }
        
        return nil
    }
    
    private func findMatches(in text: String, searchText: String, options: SearchOptions) -> [NSRange] {
        var ranges: [NSRange] = []
        
        if options.useRegex {
            // Regex search
            do {
                let pattern = options.wholeWord ? "\\b\(searchText)\\b" : searchText
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: options.caseSensitive ? [] : .caseInsensitive
                )
                let nsText = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                ranges = matches.map { $0.range }
            } catch {
                // Invalid regex
            }
        } else {
            // Plain text search
            let searchOptions: String.CompareOptions = options.caseSensitive ? [] : .caseInsensitive
            var searchRange = text.startIndex..<text.endIndex
            
            while let range = text.range(of: searchText, options: searchOptions, range: searchRange) {
                if options.wholeWord {
                    // Check word boundaries
                    let nsRange = NSRange(range, in: text)
                    let nsText = text as NSString
                    
                    let beforeOK: Bool = {
                        if nsRange.location == 0 { return true }
                        let charBefore = nsText.character(at: nsRange.location - 1)
                        let scalar = Unicode.Scalar(charBefore)!
                        return !Foundation.CharacterSet.alphanumerics.contains(scalar)
                    }()
                    
                    let afterOK: Bool = {
                        if NSMaxRange(nsRange) >= nsText.length { return true }
                        let charAfter = nsText.character(at: NSMaxRange(nsRange))
                        let scalar = Unicode.Scalar(charAfter)!
                        return !Foundation.CharacterSet.alphanumerics.contains(scalar)
                    }()
                    
                    if beforeOK && afterOK {
                        ranges.append(nsRange)
                    }
                } else {
                    ranges.append(NSRange(range, in: text))
                }
                
                searchRange = range.upperBound..<text.endIndex
            }
        }
        
        return ranges
    }
    
    private func matchesWildcard(_ text: String, pattern: String) -> Bool {
        let predicate = NSPredicate(format: "SELF LIKE %@", pattern)
        return predicate.evaluate(with: text)
    }
    
    // MARK: - Search History
    
    func addToHistory(_ item: SearchHistoryItem) {
        // Remove duplicates
        searchHistory.removeAll { $0.searchText == item.searchText }
        
        // Add to beginning
        searchHistory.insert(item, at: 0)
        
        // Limit history size
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
    }
    
    func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            searchHistory = decoded
        }
    }
    
    private func saveSearchHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    // MARK: - Bookmarks
    
    func addBookmark(_ bookmark: Bookmark) {
        bookmarks.append(bookmark)
        saveBookmarks()
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func toggleBookmark(for document: Document, at lineNumber: Int) {
        if let existingBookmark = bookmarks.first(where: { 
            $0.filePath == document.fileURL && $0.lineNumber == lineNumber 
        }) {
            removeBookmark(existingBookmark)
        } else if let filePath = document.fileURL {
            let lines = document.content.components(separatedBy: .newlines)
            let lineContent = lineNumber <= lines.count ? lines[lineNumber - 1] : ""
            
            let bookmark = Bookmark(
                filePath: filePath,
                lineNumber: lineNumber,
                lineContent: lineContent
            )
            addBookmark(bookmark)
        }
    }
    
    func isBookmarked(filePath: URL?, lineNumber: Int) -> Bool {
        guard let filePath = filePath else { return false }
        return bookmarks.contains { $0.filePath == filePath && $0.lineNumber == lineNumber }
    }
    
    func clearBookmarks() {
        bookmarks = []
        saveBookmarks()
    }
    
    private func loadBookmarks() {
        if let data = userDefaults.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            userDefaults.set(encoded, forKey: bookmarksKey)
        }
    }
    
    // MARK: - Mark All Occurrences
    
    func markAllOccurrences(in text: String, searchText: String, options: SearchOptions) {
        markedRanges = findMatches(in: text, searchText: searchText, options: options)
        NotificationCenter.default.post(
            name: .markAllOccurrences,
            object: nil,
            userInfo: ["ranges": markedRanges]
        )
    }
    
    func clearMarkedOccurrences() {
        markedRanges = []
        NotificationCenter.default.post(name: .clearMarkedOccurrences, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let markAllOccurrences = Notification.Name("markAllOccurrences")
    static let clearMarkedOccurrences = Notification.Name("clearMarkedOccurrences")
    static let navigateToBookmark = Notification.Name("navigateToBookmark")
}