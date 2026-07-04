//
//  SearchSettingsView.swift
//  Notepad++
//
//  Search and replace settings
//

import SwiftUI

struct SearchSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var searchHistoryLimit: Int = UserDefaults.standard.integer(forKey: "searchHistoryLimit")
    @State private var replaceHistoryLimit: Int = UserDefaults.standard.integer(forKey: "replaceHistoryLimit")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Default Search Options
            GroupBox("Default Search Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("These settings will be used as defaults for new search operations:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Match case", isOn: $settings.searchMatchCase)
                        .help("Search is case-sensitive by default")
                    
                    Toggle("Match whole word only", isOn: $settings.searchWholeWord)
                        .help("Search matches whole words only by default")
                    
                    Toggle("Wrap around", isOn: $settings.searchWrapAround)
                        .help("Continue search from beginning when reaching end of document")
                    
                    Toggle("Use regular expressions", isOn: $settings.searchUseRegex)
                        .help("Enable regex search by default")
                    
                    HStack {
                        Text("Search Mode:")
                        Picker("", selection: Binding(
                            get: { UserDefaults.standard.integer(forKey: "defaultSearchMode") },
                            set: { UserDefaults.standard.set($0, forKey: "defaultSearchMode") }
                        )) {
                            Text("Normal").tag(0)
                            Text("Extended (\\n, \\r, \\t, \\0, \\x...)").tag(1)
                            Text("Regular Expression").tag(2)
                        }
                        .frame(width: 250)
                    }
                }
                .padding()
            }
            
            // Smart Highlighting
            GroupBox("Smart Highlighting") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable smart highlighting", isOn: $settings.smartHighlighting)
                        .help("Automatically highlight all occurrences of selected text")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smart highlighting options:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        Toggle("Match case", isOn: $settings.smartHighlightMatchCase)
                            .disabled(!settings.smartHighlighting)
                            .padding(.leading, 20)
                        
                        Toggle("Match whole word only", isOn: $settings.smartHighlightWholeWord)
                            .disabled(!settings.smartHighlighting)
                            .padding(.leading, 20)
                        
                        Toggle("Use find dialog settings", isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "smartHighlightUseFindSettings") },
                            set: { UserDefaults.standard.set($0, forKey: "smartHighlightUseFindSettings") }
                        ))
                            .disabled(!settings.smartHighlighting)
                            .padding(.leading, 20)
                            .help("Use the same settings as the Find dialog")
                        
                        Toggle("Highlight on another view", isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "smartHighlightAnotherView") },
                            set: { UserDefaults.standard.set($0, forKey: "smartHighlightAnotherView") }
                        ))
                            .disabled(!settings.smartHighlighting)
                            .padding(.leading, 20)
                            .help("Also highlight in split view")
                    }
                }
                .padding()
            }
            
            // Search History
            GroupBox("Search History") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum search history entries:")
                        TextField("", value: $searchHistoryLimit, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchHistoryLimit) {
                                UserDefaults.standard.set(searchHistoryLimit, forKey: "searchHistoryLimit")
                            }
                        Text("entries")
                    }
                    
                    HStack {
                        Text("Maximum replace history entries:")
                        TextField("", value: $replaceHistoryLimit, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: replaceHistoryLimit) {
                                UserDefaults.standard.set(replaceHistoryLimit, forKey: "replaceHistoryLimit")
                            }
                        Text("entries")
                    }
                    
                    HStack {
                        Button("Clear Search History") {
                            clearSearchHistory()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear Replace History") {
                            clearReplaceHistory()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            
            // Find Dialog Settings
            GroupBox("Find Dialog") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Dialog always visible", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "findDialogAlwaysVisible") },
                        set: { UserDefaults.standard.set($0, forKey: "findDialogAlwaysVisible") }
                    ))
                    .help("Keep find dialog open after search")
                    
                    HStack {
                        Text("Transparency:")
                        Slider(
                            value: Binding(
                                get: { Double(UserDefaults.standard.integer(forKey: "findDialogTransparency")) },
                                set: { UserDefaults.standard.set(Int($0), forKey: "findDialogTransparency") }
                            ),
                            in: 0...100,
                            step: 10
                        )
                        .frame(width: 150)
                        Text("\(UserDefaults.standard.integer(forKey: "findDialogTransparency"))%")
                            .frame(width: 50)
                    }
                    .help("Transparency when dialog loses focus")
                    
                    Toggle("Use 2-button mode", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "findDialog2ButtonMode") },
                        set: { UserDefaults.standard.set($0, forKey: "findDialog2ButtonMode") }
                    ))
                    .help("Show only Find Next and Close buttons")
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    @MainActor
    private func clearSearchHistory() {
        // Clear the REAL Find in Files history. AdvancedSearchManager (the @MainActor singleton
        // reached via .shared) owns the @Published searchHistory array and persists it under the
        // "SearchHistory" UserDefaults key (AdvancedSearchManager.swift:35,310-312). Its
        // clearSearchHistory() (AdvancedSearchManager.swift:298-301) empties the live array and
        // rewrites that key, so a Find in Files window open right now also loses its history.
        // The previous code removed a non-existent "searchHistory" (lowercase) key and never
        // touched the live array, so nothing was actually cleared.
        AdvancedSearchManager.shared.clearSearchHistory()

        let alert = NSAlert()
        alert.messageText = "Search History Cleared"
        alert.informativeText = "The Find in Files search history has been cleared."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func clearReplaceHistory() {
        // There is no replace-history store in this version: nothing in the codebase writes a
        // replace history to disk or memory, so there is nothing to clear. Say that plainly
        // instead of claiming a clear happened. The button is kept, not removed.
        let alert = NSAlert()
        alert.messageText = "Replace History"
        alert.informativeText = "Replace history is not stored in this version, so there is nothing to clear."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}