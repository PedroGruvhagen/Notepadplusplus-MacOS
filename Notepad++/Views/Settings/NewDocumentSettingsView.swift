//
//  NewDocumentSettingsView.swift
//  Notepad++
//
//  Settings for new document creation
//

import SwiftUI

struct NewDocumentSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Encoding Settings
            GroupBox("Default Encoding") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Character Encoding:")
                        Picker("", selection: $settings.defaultEncoding) {
                            Text("UTF-8").tag("UTF-8")
                            Text("UTF-8 with BOM").tag("UTF-8-BOM")
                            Text("UTF-16 BE").tag("UTF-16BE")
                            Text("UTF-16 LE").tag("UTF-16LE")
                            Text("ASCII").tag("ASCII")
                            Text("ISO-8859-1").tag("ISO-8859-1")
                            Text("Windows-1252").tag("Windows-1252")
                            Text("MacRoman").tag("MacRoman")
                        }
                        .frame(width: 200)
                    }
                    
                    Toggle("Open ANSI files as UTF-8", isOn: $settings.openAnsiAsUtf8)
                        .help("Automatically treat ANSI files as UTF-8 encoded")
                    
                    Text("Note: UTF-8 is recommended for maximum compatibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Line Ending Settings
            GroupBox("Line Endings") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Default Format:")
                        Picker("", selection: $settings.defaultLineEnding) {
                            ForEach(AppSettings.LineEnding.allCases, id: \.self) { ending in
                                Text(ending.rawValue).tag(ending)
                            }
                        }
                        .frame(width: 200)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Line ending formats:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Windows (CR LF): \\r\\n")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Unix/macOS (LF): \\n")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Classic Mac (CR): \\r")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // Default Language Settings
            GroupBox("Default Language") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Language:")
                        Picker("", selection: $settings.defaultLanguage) {
                            ForEach(settingsManager.availableLanguages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .frame(width: 200)
                    }
                    
                    Text("Sets the default syntax highlighting for new documents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Manage Language Definitions...") {
                        // TODO: Open language management window
                    }
                    .buttonStyle(.bordered)
                    .disabled(true) // For now
                }
                .padding()
            }
            
            Spacer()
        }
    }
}