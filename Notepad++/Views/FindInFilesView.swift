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
                // TODO: Implement search cancellation
                searchManager.isSearching = false
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
                FileResultDetailView(result: selected)
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
                    NSWorkspace.shared.open(result.filePath)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Matches list
            List(selection: $selectedMatch) {
                ForEach(result.matches) { match in
                    MatchRow(match: match)
                        .tag(match)
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