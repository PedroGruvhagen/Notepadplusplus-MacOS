//
//  GeneralSettingsView.swift
//  Notepad++
//
//  General settings tab
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var updaterManager = UpdaterManager.shared
    private let featureGates = FeatureGates.shared
    
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
                    HStack {
                        Toggle("Remember last session", isOn: $settings.rememberLastSession)
                            .disabled(!featureGates.isImplemented("rememberLastSession"))
                            .help(featureGates.getStatus("rememberLastSession").helpText ?? "Restore opened files when launching Notepad++")
                        if let badge = featureGates.getStatus("rememberLastSession").badgeText {
                            Text(badge)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Text("Maximum recent files:")
                        TextField("", value: $settings.maxRecentFiles, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!featureGates.isImplemented("maxRecentFiles"))
                        Text("files")
                        if let badge = featureGates.getStatus("maxRecentFiles").badgeText {
                            Text(badge)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Toggle("Show recent files in submenu", isOn: $settings.showRecentFilesInSubmenu)
                            .disabled(!featureGates.isImplemented("showRecentFilesInSubmenu"))
                            .help(featureGates.getStatus("showRecentFilesInSubmenu").helpText ?? "")
                        if let badge = featureGates.getStatus("showRecentFilesInSubmenu").badgeText {
                            Text(badge)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding()
            }
            
            // Updates
            GroupBox("Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle("Check for updates automatically", isOn: $settings.checkForUpdates)
                            .onChange(of: settings.checkForUpdates) { _, newValue in
                                updaterManager.automaticallyChecksForUpdates = newValue
                            }
                    }

                    HStack {
                        Text("Check interval:")
                        TextField("", value: $settings.updateIntervalDays, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: settings.updateIntervalDays) { _, newValue in
                                updaterManager.updateCheckInterval = UpdaterManager.clampedInterval(days: newValue)
                            }
                        Text("days")
                    }

                    Button("Check for Updates Now") {
                        updaterManager.checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!updaterManager.canCheckForUpdates)
                }
                .padding()
            }

            Spacer()
        }
    }
}