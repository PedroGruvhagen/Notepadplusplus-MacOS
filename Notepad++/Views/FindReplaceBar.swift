//
//  FindReplaceBar.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct FindReplaceBar: View {
    @ObservedObject var document: Document
    @Binding var showReplace: Bool
    @Binding var isVisible: Bool
    
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var caseSensitive = false
    @State private var wholeWord = false
    @State private var useRegex = false
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
                    .onChange(of: searchText) { _ in
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
                
                Toggle("Aa", isOn: $caseSensitive)
                    .toggleStyle(.button)
                    .help("Case Sensitive")
                    .onChange(of: caseSensitive) { _ in
                        updateSearchResults()
                    }
                
                Toggle("W", isOn: $wholeWord)
                    .toggleStyle(.button)
                    .help("Whole Word")
                    .onChange(of: wholeWord) { _ in
                        updateSearchResults()
                    }
                
                Toggle(".*", isOn: $useRegex)
                    .toggleStyle(.button)
                    .help("Regex")
                    .onChange(of: useRegex) { _ in
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
    }
    
    private func updateSearchResults() {
        guard !searchText.isEmpty else {
            totalMatches = 0
            currentMatch = 0
            return
        }
        
        let matches = findAllMatches()
        totalMatches = matches.count
        currentMatch = matches.isEmpty ? 0 : 1
    }
    
    private func findAllMatches() -> [NSRange] {
        guard !searchText.isEmpty else { return [] }
        
        var pattern = searchText
        var options: NSRegularExpression.Options = []
        
        if !useRegex {
            pattern = NSRegularExpression.escapedPattern(for: searchText)
        }
        
        if wholeWord {
            pattern = "\\b\(pattern)\\b"
        }
        
        if !caseSensitive {
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
        } else {
            currentMatch = 1
        }
        
        // Here we would scroll to and select the match
        // This needs integration with the text editor
    }
    
    private func findPrevious() {
        let matches = findAllMatches()
        guard !matches.isEmpty else { return }
        
        if currentMatch > 1 {
            currentMatch -= 1
        } else {
            currentMatch = matches.count
        }
        
        // Here we would scroll to and select the match
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