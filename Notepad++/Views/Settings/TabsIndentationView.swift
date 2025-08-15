//
//  TabsIndentationView.swift
//  Notepad++
//
//  Tab and indentation settings
//

import SwiftUI

struct TabsIndentationView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Tab Settings
            GroupBox("Tab Settings") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tab Size:")
                        Picker("", selection: $settings.tabSize) {
                            Text("2").tag(2)
                            Text("4").tag(4)
                            Text("8").tag(8)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                        Text("spaces")
                    }
                    
                    Toggle("Replace tabs with spaces", isOn: $settings.replaceTabsBySpaces)
                        .help("Insert spaces instead of tab characters")
                    
                    // Visual example
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let tabDisplay = settings.replaceTabsBySpaces ? 
                            String(repeating: "·", count: settings.tabSize) : 
                            "→"
                        Text("if (condition) {\n\(tabDisplay)statement;\n}")
                            .font(.custom("SF Mono", size: 11))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding()
            }
            
            // Indentation Settings
            GroupBox("Indentation") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Maintain indentation", isOn: $settings.maintainIndent)
                        .help("New lines will start at the same indentation level")
                    
                    Toggle("Auto indent", isOn: $settings.autoIndent)
                        .help("Automatically indent new lines based on syntax")
                    
                    Toggle("Smart indent", isOn: $settings.smartIndent)
                        .help("Use language-specific smart indentation rules")
                        .disabled(!settings.autoIndent)
                }
                .padding()
            }
            
            // Per-Language Settings
            GroupBox("Language-Specific Settings") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Override tab settings for specific languages:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("(Language-specific settings coming soon)")
                        .foregroundColor(.secondary)
                        .italic()
                    
                    // TODO: Add language-specific overrides
                }
                .padding()
            }
            
            Spacer()
        }
    }
}