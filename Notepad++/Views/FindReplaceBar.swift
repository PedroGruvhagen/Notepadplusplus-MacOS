//
//  FindReplaceBar.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct FindReplaceBar: View {
    @ObservedObject var document: Document
    @ObservedObject private var settings = AppSettings.shared
    @Binding var showReplace: Bool
    @Binding var isVisible: Bool
    
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var currentMatch = 0
    @State private var totalMatches = 0
    @FocusState private var isFindFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Find bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Find", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .focused($isFindFocused)
                    .onSubmit {
                        findNext()
                    }
                    .onChange(of: searchText) {
                        updateSearchResults()
                    }
                
                if totalMatches > 0 {
                    Text("\(currentMatch)/\(totalMatches)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: findPrevious) {
                    Image(systemName: "chevron.up")
                }
                .help("Previous")
                
                Button(action: findNext) {
                    Image(systemName: "chevron.down")
                }
                .help("Next")
                
                Divider()
                    .frame(height: 20)
                
                Toggle("Aa", isOn: $settings.searchMatchCase)
                    .toggleStyle(.button)
                    .help("Case Sensitive")
                    .onChange(of: settings.searchMatchCase) {
                        updateSearchResults()
                    }
                
                Toggle("W", isOn: $settings.searchWholeWord)
                    .toggleStyle(.button)
                    .help("Whole Word")
                    .onChange(of: settings.searchWholeWord) {
                        updateSearchResults()
                    }
                
                Toggle(".*", isOn: $settings.searchUseRegex)
                    .toggleStyle(.button)
                    .help("Regex")
                    .onChange(of: settings.searchUseRegex) {
                        updateSearchResults()
                    }
                
                Spacer()
                
                Button(action: { showReplace.toggle() }) {
                    Image(systemName: showReplace ? "chevron.up" : "chevron.down")
                }
                .help("Toggle Replace")
                
                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark")
                }
                .help("Close")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            // Replace bar
            if showReplace {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.secondary)
                    
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    
                    Button("Replace") {
                        replaceNext()
                    }
                    
                    Button("Replace All") {
                        replaceAll()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
        .onAppear {
            isFindFocused = true
        }
        .onDisappear {
            // Clear highlights when search bar is closed
            NotificationCenter.default.post(
                name: .clearSearchHighlights,
                object: nil
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .findNext)) { _ in
            findNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .findPrevious)) { _ in
            findPrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentContentChanged)) { _ in
            // Recalculate search results when document content changes
            updateSearchResults()
        }
    }
    
    
    private func findAllMatches() -> [NSRange] {
        guard !searchText.isEmpty else { return [] }
        
        var pattern = searchText
        var options: NSRegularExpression.Options = []
        
        if !settings.searchUseRegex {
            pattern = NSRegularExpression.escapedPattern(for: searchText)
        }
        
        if settings.searchWholeWord {
            pattern = "\\b\(pattern)\\b"
        }
        
        if !settings.searchMatchCase {
            options.insert(.caseInsensitive)
        }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsString = document.content as NSString
            let matches = regex.matches(in: document.content, options: [], range: NSRange(location: 0, length: nsString.length))
            return matches.map { $0.range }
        } catch {
            return []
        }
    }
    
    private func findNext() {
        let matches = findAllMatches()
        guard !matches.isEmpty else { return }
        
        if currentMatch < matches.count {
            currentMatch += 1
        } else if settings.searchWrapAround {
            currentMatch = 1
        } else {
            return // Don't wrap if wrap around is disabled
        }
        
        // Send notification to highlight and scroll to match
        if currentMatch > 0 && currentMatch <= matches.count {
            NotificationCenter.default.post(
                name: .highlightSearchResult,
                object: nil,
                userInfo: [
                    "ranges": matches,
                    "currentIndex": currentMatch - 1,
                    "range": matches[currentMatch - 1]
                ]
            )
        }
    }
    
    private func findPrevious() {
        let matches = findAllMatches()
        guard !matches.isEmpty else { return }
        
        if currentMatch > 1 {
            currentMatch -= 1
        } else if settings.searchWrapAround {
            currentMatch = matches.count
        } else {
            return // Don't wrap if wrap around is disabled
        }
        
        // Send notification to highlight and scroll to match
        if currentMatch > 0 && currentMatch <= matches.count {
            NotificationCenter.default.post(
                name: .highlightSearchResult,
                object: nil,
                userInfo: [
                    "ranges": matches,
                    "currentIndex": currentMatch - 1,
                    "range": matches[currentMatch - 1]
                ]
            )
        }
    }
    
    private func updateSearchResults() {
        guard !searchText.isEmpty else {
            totalMatches = 0
            currentMatch = 0
            // Clear highlights
            NotificationCenter.default.post(name: .clearSearchHighlights, object: nil)
            return
        }
        
        let matches = findAllMatches()
        totalMatches = matches.count
        currentMatch = matches.isEmpty ? 0 : 1
        
        // Send notification to highlight all matches
        if !matches.isEmpty {
            NotificationCenter.default.post(
                name: .highlightSearchResult,
                object: nil,
                userInfo: [
                    "ranges": matches,
                    "currentIndex": 0
                ]
            )
        }
    }
    
    private func replaceNext() {
        let matches = findAllMatches()
        guard currentMatch > 0 && currentMatch <= matches.count else { return }
        
        let range = matches[currentMatch - 1]
        let nsString = document.content as NSString
        let newContent = nsString.replacingCharacters(in: range, with: replaceText)
        document.updateContent(newContent)
        
        updateSearchResults()
    }
    
    private func replaceAll() {
        let matches = findAllMatches()
        guard !matches.isEmpty else { return }
        
        var newContent = document.content as NSString
        
        // Replace from end to beginning to maintain indices
        for range in matches.reversed() {
            newContent = newContent.replacingCharacters(in: range, with: replaceText) as NSString
        }
        
        document.updateContent(newContent as String)
        updateSearchResults()
    }
}

extension Notification.Name {
    static let highlightSearchResult = Notification.Name("highlightSearchResult")
    static let clearSearchHighlights = Notification.Name("clearSearchHighlights")
    static let selectSearchResult = Notification.Name("selectSearchResult")
    static let showFind = Notification.Name("showFind")
    static let showReplace = Notification.Name("showReplace")
    static let documentContentChanged = Notification.Name("documentContentChanged")
}