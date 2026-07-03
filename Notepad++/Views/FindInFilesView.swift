//
//  FindInFilesView.swift
//  Notepad++
//
//  Find in Files interface
//

import SwiftUI
import UniformTypeIdentifiers

struct FindInFilesView: View {
    @StateObject private var searchManager = AdvancedSearchManager.shared
    @State private var searchText = ""
    @State private var searchPath = ""
    @State private var fileFilter = "*.*"
    @State private var options = SearchOptions()
    @State private var configuration = FindInFilesConfiguration()
    @State private var selectedResult: FileSearchResult?
    @State private var isSelectingFolder = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            searchHeaderView
            
            Divider()
            
            // Search Results
            if searchManager.isSearching {
                searchProgressView
            } else if searchManager.currentSearchResults.isEmpty {
                emptyStateView
            } else {
                searchResultsView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .navigationTitle("Find in Files")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    private var searchHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search text field
            HStack {
                Text("Find what:")
                    .frame(width: 100, alignment: .trailing)
                
                TextField("Enter search text", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Search history menu
                Menu {
                    ForEach(searchManager.searchHistory.prefix(10)) { item in
                        Button(item.searchText) {
                            searchText = item.searchText
                            options.caseSensitive = item.isCaseSensitive
                            options.wholeWord = item.isWholeWord
                            options.useRegex = item.isRegex
                        }
                    }
                    
                    if !searchManager.searchHistory.isEmpty {
                        Divider()
                        Button("Clear History") {
                            searchManager.clearSearchHistory()
                        }
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help("Search History")
            }
            
            // Search path
            HStack {
                Text("In folder:")
                    .frame(width: 100, alignment: .trailing)
                
                TextField("Select folder to search", text: $searchPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                
                Button("Browse...") {
                    selectFolder()
                }
            }
            
            // File filters
            HStack {
                Text("File types:")
                    .frame(width: 100, alignment: .trailing)
                
                TextField("*.swift, *.txt", text: $fileFilter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: fileFilter) {
                        configuration.fileFilters = fileFilter
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                    }
                
                Menu {
                    Button("All files (*.*)") { fileFilter = "*.*" }
                    Button("Swift files (*.swift)") { fileFilter = "*.swift" }
                    Button("Text files (*.txt, *.md)") { fileFilter = "*.txt, *.md" }
                    Button("Code files") { fileFilter = "*.swift, *.m, *.h, *.c, *.cpp" }
                    Button("Web files") { fileFilter = "*.html, *.css, *.js, *.json" }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            
            // Search options
            HStack {
                Text("Options:")
                    .frame(width: 100, alignment: .trailing)
                
                Toggle("Case sensitive", isOn: $options.caseSensitive)
                Toggle("Whole word", isOn: $options.wholeWord)
                Toggle("Regex", isOn: $options.useRegex)
                Toggle("Include subfolders", isOn: $configuration.includeSubfolders)
                
                Spacer()
                
                Button("Find All") {
                    performSearch()
                }
                .keyboardShortcut(.return)
                .disabled(searchText.isEmpty || configuration.searchPath == nil)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var searchProgressView: some View {
        VStack(spacing: 20) {
            ProgressView(value: searchManager.searchProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 300)
            
            Text("Searching... \(Int(searchManager.searchProgress * 100))%")
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                searchManager.cancelSearch()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Enter search criteria and click 'Find All'")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsView: some View {
        HSplitView {
            // Results list
            List(selection: $selectedResult) {
                ForEach(searchManager.currentSearchResults) { result in
                    FileResultRow(result: result)
                        .tag(result)
                }
            }
            .frame(minWidth: 300)
            
            // Result details
            if let selected = selectedResult {
                FileResultDetailView(result: selected) { filePath, match in
                    openResult(filePath, match: match)
                }
                .frame(minWidth: 400)
            } else {
                Text("Select a file to view matches")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select folder to search in"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                configuration.searchPath = url
                searchPath = url.path
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty, let _ = configuration.searchPath else { return }
        
        // Add to history
        let historyItem = SearchHistoryItem(
            searchText: searchText,
            isRegex: options.useRegex,
            isCaseSensitive: options.caseSensitive,
            isWholeWord: options.wholeWord,
            searchScope: .directory
        )
        searchManager.addToHistory(historyItem)
        
        // Perform search
        Task {
            await searchManager.findInFiles(
                searchText: searchText,
                configuration: configuration,
                options: options
            )
        }
    }

    // F50: open a result inside THIS editor at the matched line instead of launching the system
    // default app (the old NSWorkspace.shared.open). Port of Notepad++ opening the found file in the
    // editor and centring the matched section (FindReplaceDlg.cpp:614/637/663). openDocument reuses
    // the Phase 6 dedup + file monitor; revealRange selects and centres the match once the tab is on
    // screen. Callers pass the match to reveal (a double-clicked row's match, or the file's first
    // match for the Open File button); a nil match is a defensive fallback that reveals line 1.
    private func openResult(_ filePath: URL, match: LineMatch?) {
        dismiss()
        Task {
            await DocumentManager.shared.openDocument(from: filePath)
            guard let document = DocumentManager.shared.activeTab?.document else { return }
            let targetLine = match?.lineNumber ?? 1
            let matchRanges = match?.matchRanges ?? []
            let range = FindInFilesView.revealRange(in: document.content,
                                                    lineNumber: targetLine,
                                                    matchRanges: matchRanges)
            document.revealRange(range)
        }
    }

    // Map a 1-based line number + line-local match range to a document character range. Counts lines
    // with .byLines, the SAME Unicode-line-boundary enumeration searchInFile now uses to produce the
    // line number, so the reveal target and the reported line always agree (including CRLF/CR files,
    // F50). Selects the exact match when it fits within the line, else the whole line's content.
    static func revealRange(in content: String, lineNumber: Int, matchRanges: [NSRange]) -> NSRange {
        let ns = content as NSString
        var lineContentRange: NSRange?
        var index = 0
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length),
                               options: [.byLines, .substringNotRequired]) { _, substringRange, _, stop in
            index += 1
            if index == lineNumber {
                lineContentRange = substringRange
                stop.pointee = true
            }
        }

        guard let lineRange = lineContentRange else {
            return NSRange(location: 0, length: 0)
        }

        if let first = matchRanges.first,
           first.location >= 0,
           first.location + first.length <= lineRange.length {
            return NSRange(location: lineRange.location + first.location, length: first.length)
        }
        return lineRange
    }
}

struct FileResultRow: View {
    let result: FileSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentColor)
                
                Text(result.fileName)
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text("\(result.matchCount) match\(result.matchCount == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.filePath.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct FileResultDetailView: View {
    let result: FileSearchResult
    // F50: open the file inside this editor (optionally at a specific match), not the system app.
    let onOpen: (URL, LineMatch?) -> Void
    @State private var selectedMatch: LineMatch?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            HStack {
                Image(systemName: "doc.text.fill")
                Text(result.fileName)
                    .font(.headline)
                Spacer()
                Button("Open File") {
                    // Open at the file's first match, like Notepad++ centring the found
                    // section on activation (FindReplaceDlg.cpp:663). A displayed result always
                    // has at least one match (searchInFile returns nil when matches is empty).
                    onOpen(result.filePath, result.matches.first)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Matches list. Double-click a match to open the file at that line (F50).
            List(selection: $selectedMatch) {
                ForEach(result.matches) { match in
                    MatchRow(match: match)
                        .tag(match)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            onOpen(result.filePath, match)
                        }
                }
            }
        }
    }
}

struct MatchRow: View {
    let match: LineMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Line \(match.lineNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Show context if available
            if let contextBefore = match.contextBefore, !contextBefore.isEmpty {
                Text(contextBefore)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Highlighted match line
            Text(highlightedLine)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            
            if let contextAfter = match.contextAfter, !contextAfter.isEmpty {
                Text(contextAfter)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var highlightedLine: AttributedString {
        var attributedString = AttributedString(match.lineContent)
        
        for range in match.matchRanges {
            if let swiftRange = Range(range, in: match.lineContent) {
                if let attrRange = attributedString.range(of: match.lineContent[swiftRange]) {
                    attributedString[attrRange].backgroundColor = .yellow.opacity(0.3)
                    attributedString[attrRange].foregroundColor = .primary
                }
            }
        }
        
        return attributedString
    }
}