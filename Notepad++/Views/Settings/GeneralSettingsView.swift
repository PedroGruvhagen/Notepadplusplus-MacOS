//
//  GeneralSettingsView.swift
//  Notepad++
//
//  General settings tab
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // UI Components
            GroupBox("User Interface") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show Toolbar", isOn: $settings.showToolbar)
                    Toggle("Show Status Bar", isOn: $settings.showStatusBar)
                    Toggle("Show Tab Bar", isOn: $settings.showTabBar)
                    
                    HStack {
                        Text("Tab Bar Position:")
                        Picker("", selection: $settings.tabBarPosition) {
                            ForEach(AppSettings.TabPosition.allCases, id: \.self) { position in
                                Text(position.rawValue).tag(position)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                .padding()
            }
            
            // Session
            GroupBox("Session") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Remember last session", isOn: $settings.rememberLastSession)
                        .help("Restore opened files when launching Notepad++")
                    
                    HStack {
                        Text("Maximum recent files:")
                        TextField("", value: $settings.maxRecentFiles, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("files")
                    }
                    
                    Toggle("Show recent files in submenu", isOn: $settings.showRecentFilesInSubmenu)
                }
                .padding()
            }
            
            // Updates
            GroupBox("Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Check for updates automatically", isOn: $settings.checkForUpdates)
                    
                    HStack {
                        Text("Check interval:")
                        TextField("", value: $settings.updateIntervalDays, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!settings.checkForUpdates)
                        Text("days")
                    }
                    
                    Button("Check for Updates Now") {
                        checkForUpdatesNow()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func checkForUpdatesNow() {
        // TODO: Implement update check
        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "You are using the latest version of Notepad++ for macOS."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}