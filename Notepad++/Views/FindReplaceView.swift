//
//  FindReplaceView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct FindReplaceView: View {
    @ObservedObject var document: Document
    @StateObject private var searchOptions = SearchOptions()
    @StateObject private var searchManager = SearchManager()
    @FocusState private var isFindFieldFocused: Bool
    @State private var matchRanges: [NSRange] = []
    
    var body: some View {
        VStack(spacing: 0) {
            if searchManager.isSearchVisible {
                VStack(spacing: 8) {
                    // Find bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Find", text: $searchOptions.searchText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFindFieldFocused)
                            .onSubmit {
                                findNext()
                            }
                            .onChange(of: searchOptions.searchText) {
                                performSearch()
                            }
                        
                        if searchManager.totalMatches > 0 {
                            Text("\(searchManager.currentMatchIndex) of \(searchManager.totalMatches)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 60)
                        }
                        
                        Button(action: findPrevious) {
                            Image(systemName: "chevron.up")
                        }
                        .keyboardShortcut("g", modifiers: [.command, .shift])
                        .help("Find Previous (⌘⇧G)")
                        
                        Button(action: findNext) {
                            Image(systemName: "chevron.down")
                        }
                        .keyboardShortcut("g", modifiers: .command)
                        .help("Find Next (⌘G)")
                        
                        Toggle("Aa", isOn: $searchOptions.caseSensitive)
                            .toggleStyle(.button)
                            .help("Case Sensitive")
                            .onChange(of: searchOptions.caseSensitive) {
                                performSearch()
                            }
                        
                        Toggle("W", isOn: $searchOptions.wholeWord)
                            .toggleStyle(.button)
                            .help("Whole Word")
                            .onChange(of: searchOptions.wholeWord) {
                                performSearch()
                            }
                        
                        Toggle(".*", isOn: $searchOptions.useRegex)
                            .toggleStyle(.button)
                            .help("Regular Expression")
                            .onChange(of: searchOptions.useRegex) {
                                performSearch()
                            }
                        
                        Button(action: {
                            searchManager.hide()
                        }) {
                            Image(systemName: "xmark")
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        .help("Close (Esc)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    // Replace bar
                    if searchManager.isReplaceVisible {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.secondary)
                            
                            TextField("Replace", text: $searchOptions.replaceText)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    replaceNext()
                                }
                            
                            Button("Replace") {
                                replaceNext()
                            }
                            .keyboardShortcut("r", modifiers: .command)
                            
                            Button("Replace All") {
                                replaceAll()
                            }
                            .keyboardShortcut("r", modifiers: [.command, .shift])
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .bottom
                )
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // This would be better handled by the app's menu system
        isFindFieldFocused = searchManager.isSearchVisible
    }
    
    private func performSearch() {
        matchRanges = searchManager.findAll(
            in: document.content,
            searchText: searchOptions.searchText,
            options: searchOptions
        )
        searchManager.totalMatches = matchRanges.count
        searchManager.currentMatchIndex = matchRanges.isEmpty ? 0 : 1
        
        // Notify the editor to highlight matches
        NotificationCenter.default.post(
            name: .highlightSearchResults,
            object: nil,
            userInfo: ["ranges": matchRanges]
        )
    }
    
    private func findNext() {
        guard !matchRanges.isEmpty else { return }
        
        if searchManager.currentMatchIndex < matchRanges.count {
            searchManager.currentMatchIndex += 1
        } else if searchOptions.wrapAround {
            searchManager.currentMatchIndex = 1
        }
        
        if searchManager.currentMatchIndex > 0 && searchManager.currentMatchIndex <= matchRanges.count {
            let range = matchRanges[searchManager.currentMatchIndex - 1]
            NotificationCenter.default.post(
                name: .selectSearchResult,
                object: nil,
                userInfo: ["range": range]
            )
        }
    }
    
    private func findPrevious() {
        guard !matchRanges.isEmpty else { return }
        
        if searchManager.currentMatchIndex > 1 {
            searchManager.currentMatchIndex -= 1
        } else if searchOptions.wrapAround {
            searchManager.currentMatchIndex = matchRanges.count
        }
        
        if searchManager.currentMatchIndex > 0 && searchManager.currentMatchIndex <= matchRanges.count {
            let range = matchRanges[searchManager.currentMatchIndex - 1]
            NotificationCenter.default.post(
                name: .selectSearchResult,
                object: nil,
                userInfo: ["range": range]
            )
        }
    }
    
    private func replaceNext() {
        guard searchManager.currentMatchIndex > 0,
              searchManager.currentMatchIndex <= matchRanges.count else { return }
        
        let range = matchRanges[searchManager.currentMatchIndex - 1]
        let newContent = searchManager.replace(in: document, at: range)
        document.updateContent(newContent)
        
        // Re-search after replacement
        performSearch()
    }
    
    private func replaceAll() {
        let (newContent, count) = searchManager.replaceAll(in: document)
        if count > 0 {
            document.updateContent(newContent)
            
            // Show confirmation
            NotificationCenter.default.post(
                name: .showMessage,
                object: nil,
                userInfo: ["message": "Replaced \(count) occurrences"]
            )
            
            // Clear search
            performSearch()
        }
    }
}

// Notification names
extension Notification.Name {
    static let highlightSearchResults = Notification.Name("highlightSearchResults")
    static let showMessage = Notification.Name("showMessage")
}