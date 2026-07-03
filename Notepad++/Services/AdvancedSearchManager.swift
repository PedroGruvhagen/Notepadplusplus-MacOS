//
//  SearchManager.swift
//  Notepad++
//
//  Service for advanced search features
//

import Foundation
import SwiftUI

/// A Sendable snapshot of the search parameters. SearchOptions is a reference-type ObservableObject
/// and cannot cross into the detached search task (F47); this value can. Taken on the main actor
/// before the scan starts.
struct SearchQuery: Sendable {
    let searchText: String
    let caseSensitive: Bool
    let wholeWord: Bool
    let useRegex: Bool
}

@MainActor
class AdvancedSearchManager: ObservableObject {
    static let shared = AdvancedSearchManager()
    
    // MARK: - Published Properties
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var bookmarks: [Bookmark] = []
    @Published var currentSearchResults: [FileSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var searchProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let maxHistoryItems = 50
    private let userDefaults = UserDefaults.standard
    private let historyKey = "SearchHistory"
    private let bookmarksKey = "Bookmarks"
    // F47: the in-flight Find-in-Files task. Cancel() is what the (previously stub) Cancel
    // button now calls; the detached search loop checks Task.isCancelled and bails out.
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadSearchHistory()
        loadBookmarks()
    }
    
    // MARK: - Find in Files

    func findInFiles(searchText: String, configuration: FindInFilesConfiguration, options: SearchOptions) async {
        // Replace any in-flight search.
        searchTask?.cancel()

        isSearching = true
        searchProgress = 0.0
        currentSearchResults = []

        guard let searchPath = configuration.searchPath else {
            isSearching = false
            return
        }

        // Snapshot the reference-type SearchOptions into a Sendable value BEFORE crossing to the
        // detached task; SearchOptions is an ObservableObject (a class) and cannot be captured by
        // a @Sendable closure. Same reason we pull the primitives we need out of configuration.
        let query = SearchQuery(searchText: searchText,
                                caseSensitive: options.caseSensitive,
                                wholeWord: options.wholeWord,
                                useRegex: options.useRegex)
        let config = configuration
        let contextLines = configuration.contextLines
        let maxResults = configuration.maxResults

        // F47: run the entire directory walk + per-file read + regex matching OFF the main actor.
        // Before, AdvancedSearchManager being @MainActor forced the whole scan (enumerator.allObjects,
        // every String(contentsOf:) read and all per-line matching) onto the main thread, beachballing
        // the UI for the full scan. Only progress/result publication hops back to the main actor.
        let task = Task.detached(priority: .userInitiated) { [self] in
            let fileURLs = getSearchableFiles(at: searchPath, configuration: config)
            let totalFiles = max(1, fileURLs.count)
            var results: [FileSearchResult] = []

            for (index, fileURL) in fileURLs.enumerated() {
                // Cooperative cancellation: the Cancel button cancels searchTask (F47).
                if Task.isCancelled { break }

                let progressValue = Double(index) / Double(totalFiles)
                await MainActor.run { self.searchProgress = progressValue }

                if let fileResult = searchInFile(fileURL: fileURL, query: query, contextLines: contextLines) {
                    results.append(fileResult)

                    // Stream results to the UI in batches so long scans show progress.
                    if results.count % 10 == 0 {
                        let snapshot = results
                        await MainActor.run { self.currentSearchResults = snapshot }
                    }
                }

                if results.count >= maxResults { break }
            }

            let finalResults = results
            let cancelled = Task.isCancelled
            await MainActor.run {
                self.currentSearchResults = finalResults
                self.isSearching = false
                self.searchProgress = cancelled ? 0.0 : 1.0
            }
        }
        searchTask = task
        await task.value
    }

    /// Stop an in-flight Find in Files scan. F47: previously the Cancel button only flipped
    /// isSearching, which the (main-thread) loop never checked, so a long scan could not be stopped
    /// short of force-quit. Now it cancels the detached task, which the loop observes.
    func cancelSearch() {
        searchTask?.cancel()
        // Reflect immediately for a responsive UI; the detached loop also flips isSearching off on
        // its next main hop after observing Task.isCancelled.
        isSearching = false
    }

    // Nonisolated so it can run on the detached search task without a main-actor hop. Uses the LAZY
    // enumerator (pulls one entry at a time) instead of enumerator.allObjects, which eagerly
    // materialised and prefetched the ENTIRE tree before any matching began (F47).
    nonisolated private func getSearchableFiles(at path: URL, configuration: FindInFilesConfiguration) -> [URL] {
        let fileManager = FileManager.default
        var files: [URL] = []

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        let options: FileManager.DirectoryEnumerationOptions = configuration.includeSubfolders ? [] : [.skipsSubdirectoryDescendants]

        guard let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: options) else {
            return files
        }

        for case let fileURL as URL in enumerator {
            if Task.isCancelled { break }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  resourceValues.isRegularFile == true else { continue }

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

        return files
    }

    nonisolated private func searchInFile(fileURL: URL, query: SearchQuery, contextLines: Int) -> FileSearchResult? {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            // Silently skip files that can't be read as UTF-8
            return nil
        }

        // Split into lines by Unicode line boundaries (.byLines) so the reported line number matches
        // the editor's own line counting AND FindInFilesView.revealRange, which maps that number back
        // to a character range the same way (F50). components(separatedBy: .newlines) splits \r and \n
        // as two separate delimiters, which inflates the count on CRLF files (each real line gains a
        // phantom empty line) and made jump-to-line land on the wrong line for Windows-EOL files.
        let ns = content as NSString
        var lines: [String] = []
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length),
                               options: [.byLines]) { substring, _, _, _ in
            lines.append(substring ?? "")
        }
        var matches: [LineMatch] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let matchRanges = findMatches(in: line, query: query)

            if !matchRanges.isEmpty {
                let contextBefore = index > 0 ? lines[max(0, index - contextLines)...index-1].joined(separator: "\n") : nil
                let contextAfter = index < lines.count - 1 ? lines[index+1...min(lines.count-1, index + contextLines)].joined(separator: "\n") : nil

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

        return nil
    }

    nonisolated private func findMatches(in text: String, query: SearchQuery) -> [NSRange] {
        var ranges: [NSRange] = []

        if query.useRegex {
            // Regex search
            do {
                let pattern = query.wholeWord ? "\\b\(query.searchText)\\b" : query.searchText
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: query.caseSensitive ? [] : .caseInsensitive
                )
                let nsText = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                ranges = matches.map { $0.range }
            } catch {
                // Invalid regex
            }
        } else {
            // Plain text search
            let searchOptions: String.CompareOptions = query.caseSensitive ? [] : .caseInsensitive
            var searchRange = text.startIndex..<text.endIndex

            while let range = text.range(of: query.searchText, options: searchOptions, range: searchRange) {
                if query.wholeWord {
                    // Check word boundaries
                    let nsRange = NSRange(range, in: text)
                    let nsText = text as NSString

                    let beforeOK: Bool = {
                        if nsRange.location == 0 { return true }
                        let charBefore = nsText.character(at: nsRange.location - 1)
                        // F48: character(at:) returns a raw UTF-16 code unit; a match sitting directly
                        // next to an emoji or other non-BMP character puts a lone surrogate half here,
                        // and Unicode.Scalar(UInt16) is nil for surrogates (0xD800-0xDFFF). The old `!`
                        // trapped and crashed the whole app. Treat a surrogate neighbour as part of a
                        // word (a grapheme continues there), so the boundary is NOT satisfied.
                        guard let scalar = Unicode.Scalar(charBefore) else { return false }
                        return !Foundation.CharacterSet.alphanumerics.contains(scalar)
                    }()

                    let afterOK: Bool = {
                        if NSMaxRange(nsRange) >= nsText.length { return true }
                        let charAfter = nsText.character(at: NSMaxRange(nsRange))
                        guard let scalar = Unicode.Scalar(charAfter) else { return false }
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
    
    nonisolated private func matchesWildcard(_ text: String, pattern: String) -> Bool {
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
    
    /// F51: mirror an in-editor bookmark (the Document's own bookmark set is the source of truth) into
    /// the persistent, filePath-keyed Bookmarks panel so the panel reflects the editor for saved files.
    /// `present` = the document's current bookmark state for that line, so this stays idempotent.
    func setPanelBookmark(url: URL, lineNumber: Int, lineContent: String, present: Bool) {
        let existing = bookmarks.first { $0.filePath == url && $0.lineNumber == lineNumber }
        if present {
            if existing == nil {
                addBookmark(Bookmark(filePath: url, lineNumber: lineNumber, lineContent: lineContent))
            }
        } else if let existing {
            removeBookmark(existing)
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

    // F52: the former markAllOccurrences/clearMarkedOccurrences re-post layer (and its markedRanges
    // property + .markAllOccurrences/.clearMarkedOccurrences notification names) was DEAD - it posted
    // to zero observers and had zero callers. Mark All / Clear Marks are now handled directly on the
    // live editor in DocumentTextEditor.Coordinator.handleMarkAll/handleClearMarks, so this dead layer
    // was deleted rather than left as phantom wiring.
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToBookmark = Notification.Name("navigateToBookmark")
}