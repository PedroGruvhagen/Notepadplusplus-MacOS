//
//  BackupSettingsView.swift
//  Notepad++
//
//  Backup and auto-save settings
//

import SwiftUI

struct BackupSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedBackupFolder: String = ""
    private let featureGates = FeatureGates.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Backup Settings
            GroupBox("Backup") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable backup on save", isOn: $settings.enableBackup)
                        .help("Create backup copies of files before saving")
                    
                    HStack {
                        Text("Backup Type:")
                        Picker("", selection: $settings.backupMode) {
                            ForEach(AppSettings.BackupMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 250)
                        .disabled(!settings.enableBackup)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backup modes:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• None: No backup")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Simple: Create .bak file in same directory")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Verbose: Create timestamped backup in custom directory")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if settings.backupMode == .verbose {
                        HStack {
                            Text("Backup Directory:")
                            TextField("", text: $settings.backupDirectory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(!settings.enableBackup)
                            
                            Button("Browse...") {
                                selectBackupDirectory()
                            }
                            .disabled(!settings.enableBackup)
                        }
                    }
                }
                .padding()
            }
            
            // Auto-Save Settings
            GroupBox("Auto-Save") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable auto-save", isOn: $settings.enableAutoSave)
                        .help("Automatically save documents at regular intervals")
                    
                    HStack {
                        Text("Auto-save interval:")
                        TextField("", value: $settings.autoSaveInterval, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!settings.enableAutoSave)
                        Text("minutes")
                        
                        Spacer()
                        
                        Text("(minimum: 1 minute)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Note: Auto-save only applies to documents that have been saved at least once")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Session Snapshot Settings
            GroupBox("Session Snapshot & Periodic Backup") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle("Enable session snapshot and periodic backup", isOn: $settings.enableSessionSnapshot)
                            .disabled(!featureGates.getStatus("enableSessionSnapshot").isEnabled)
                            .help(featureGates.getStatus("enableSessionSnapshot").helpText ?? "Periodically save the current session and create backups")
                        if let badge = featureGates.getStatus("enableSessionSnapshot").badgeText {
                            Text(badge)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Text("Snapshot interval:")
                        TextField("", value: $settings.snapshotInterval, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!featureGates.getStatus("snapshotInterval").isEnabled)
                        Text("seconds")
                        
                        Spacer()
                        
                        Text("(recommended: 7 seconds)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Session snapshots help recover work after unexpected crashes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Open Backup Folder") {
                        openBackupFolder()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func selectBackupDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select backup directory"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                settings.backupDirectory = url.path
            }
        }
    }
    
    private func openBackupFolder() {
        let backupPath = settings.backupDirectory.isEmpty ? 
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Notepad++/Backups").path ?? "" :
            settings.backupDirectory
        
        if !backupPath.isEmpty {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: backupPath)
        }
    }
}