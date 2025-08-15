//
//  AppearanceSettingsView.swift
//  Notepad++
//
//  Appearance and theme settings
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Theme Settings
            GroupBox("Theme") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Dark Mode", isOn: $settings.enableDarkMode)
                        .help("Use system appearance or force dark mode")
                    
                    HStack {
                        Text("Color Theme:")
                        Picker("", selection: $settings.theme) {
                            ForEach(settingsManager.availableThemes, id: \.self) { theme in
                                Text(theme).tag(theme)
                            }
                        }
                        .frame(width: 200)
                    }
                    
                    Button("Customize Theme...") {
                        // TODO: Open theme customization
                    }
                    .buttonStyle(.bordered)
                    .disabled(true) // For now
                }
                .padding()
            }
            
            // Syntax Highlighting
            GroupBox("Syntax Highlighting") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable syntax highlighting", isOn: $settings.syntaxHighlighting)
                    Toggle("Match braces", isOn: $settings.matchBraces)
                        .disabled(!settings.syntaxHighlighting)
                    Toggle("Highlight matching tags", isOn: $settings.highlightMatchingTags)
                        .disabled(!settings.syntaxHighlighting)
                    
                    HStack {
                        Text("Current Line Color:")
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: settings.currentLineColor) ?? .gray },
                            set: { settings.currentLineColor = $0.toHex() ?? "#F0F0F0" }
                        ))
                        .labelsHidden()
                        .disabled(!settings.highlightCurrentLine)
                    }
                }
                .padding()
            }
            
            // Smart Highlighting
            GroupBox("Smart Highlighting") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable smart highlighting", isOn: $settings.smartHighlighting)
                        .help("Automatically highlight all occurrences of selected word")
                    
                    Toggle("Match case", isOn: $settings.smartHighlightMatchCase)
                        .disabled(!settings.smartHighlighting)
                    
                    Toggle("Match whole word only", isOn: $settings.smartHighlightWholeWord)
                        .disabled(!settings.smartHighlighting)
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

// Color extension for hex conversion
extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}