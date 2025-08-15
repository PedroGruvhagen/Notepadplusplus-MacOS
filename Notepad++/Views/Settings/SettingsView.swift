//
//  SettingsView.swift
//  Notepad++
//
//  Main settings window with sidebar navigation
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedTab: SettingsManager.SettingsTab = .general
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with setting categories
            List(SettingsManager.SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        } detail: {
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(selectedTab.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Reset to Defaults") {
                            showResetConfirmation()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsView()
                        case .editing:
                            EditorSettingsView()
                        case .appearance:
                            AppearanceSettingsView()
                        case .tabsIndentation:
                            TabsIndentationView()
                        case .newDocument:
                            NewDocumentSettingsView()
                        case .backup:
                            BackupSettingsView()
                        case .autoCompletion:
                            AutoCompletionSettingsView()
                        case .search:
                            SearchSettingsView()
                        case .performance:
                            PerformanceSettingsView()
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .frame(minWidth: 600, minHeight: 500)
        }
        .frame(width: 900, height: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                HStack {
                    Button("Export Settings...") {
                        exportSettings()
                    }
                    
                    Button("Import Settings...") {
                        importSettings()
                    }
                }
            }
        }
    }
    
    private func showResetConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Reset \(selectedTab.rawValue) Settings"
        alert.informativeText = "Are you sure you want to reset all \(selectedTab.rawValue.lowercased()) settings to their default values?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            settingsManager.resetSettings(for: selectedTab)
        }
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "notepad-settings.json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let data = settingsManager.settings.exportSettings() {
                    try? data.write(to: url)
                }
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                if let data = try? Data(contentsOf: url) {
                    _ = settingsManager.settings.importSettings(from: data)
                }
            }
        }
    }
}