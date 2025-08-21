//
//  AutoCompletionSettingsView.swift
//  Notepad++
//
//  Auto-completion and auto-insert settings
//

import SwiftUI

struct AutoCompletionSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    private let featureGates = FeatureGates.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Feature not implemented notice
            if !featureGates.isImplemented("enableAutoCompletion") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Auto-completion features are not yet implemented")
                        .font(.caption)
                    Spacer()
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Auto-Completion Settings
            GroupBox("Auto-Completion") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable auto-completion", isOn: $settings.enableAutoCompletion)
                        .disabled(!featureGates.isImplemented("enableAutoCompletion"))
                        .help(featureGates.getStatus("enableAutoCompletion").helpText ?? "Show completion suggestions while typing")
                    
                    HStack {
                        Text("Trigger from character:")
                        TextField("", value: $settings.autoCompletionMinChars, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!settings.enableAutoCompletion)
                        Text("characters")
                        
                        Spacer()
                        
                        Text("(minimum: 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Show function parameters hint", isOn: $settings.showFunctionParameters)
                        .disabled(!settings.enableAutoCompletion)
                        .help("Display parameter hints for functions")
                    
                    Toggle("Ignore numbers", isOn: $settings.autoCompletionIgnoreNumbers)
                        .disabled(!settings.enableAutoCompletion)
                        .help("Don't show completions for numeric values")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion sources:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Words from current document")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Language keywords")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• API/Function definitions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // Auto-Insert Settings
            GroupBox("Auto-Insert") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Automatically insert matching characters:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Insert matching parentheses ( )", isOn: $settings.autoInsertParentheses)
                        .help("Automatically insert closing parenthesis when typing opening parenthesis")
                    
                    Toggle("Insert matching brackets [ ]", isOn: $settings.autoInsertBrackets)
                        .help("Automatically insert closing bracket when typing opening bracket")
                    
                    Toggle("Insert matching braces { }", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "autoInsertBraces") },
                        set: { UserDefaults.standard.set($0, forKey: "autoInsertBraces") }
                    ))
                        .help("Automatically insert closing brace when typing opening brace")
                    
                    Toggle("Insert matching quotes \" \"", isOn: $settings.autoInsertQuotes)
                        .help("Automatically insert closing quote when typing opening quote")
                    
                    Toggle("Insert matching single quotes ' '", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "autoInsertSingleQuotes") },
                        set: { UserDefaults.standard.set($0, forKey: "autoInsertSingleQuotes") }
                    ))
                        .help("Automatically insert closing single quote when typing opening single quote")
                    
                    Toggle("Insert matching HTML/XML tags", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "autoInsertHtmlTags") },
                        set: { UserDefaults.standard.set($0, forKey: "autoInsertHtmlTags") }
                    ))
                        .help("Automatically close HTML/XML tags")
                }
                .padding()
            }
            
            // Advanced Settings
            GroupBox("Advanced") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Word completion behavior:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Selection behavior:")
                        Picker("", selection: Binding(
                            get: { UserDefaults.standard.integer(forKey: "completionSelectionBehavior") },
                            set: { UserDefaults.standard.set($0, forKey: "completionSelectionBehavior") }
                        )) {
                            Text("Tab or Enter").tag(0)
                            Text("Tab only").tag(1)
                            Text("Enter only").tag(2)
                        }
                        .frame(width: 150)
                    }
                    
                    Toggle("Case-sensitive completion", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "caseSensitiveCompletion") },
                        set: { UserDefaults.standard.set($0, forKey: "caseSensitiveCompletion") }
                    ))
                    .help("Match case when showing completions")
                    
                    Toggle("Sort completions alphabetically", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "sortCompletionsAlphabetically") },
                        set: { UserDefaults.standard.set($0, forKey: "sortCompletionsAlphabetically") }
                    ))
                    .help("Sort completion suggestions alphabetically instead of by relevance")
                }
                .padding()
            }
            
            Spacer()
        }
    }
}