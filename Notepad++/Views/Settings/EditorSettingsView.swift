//
//  EditorSettingsView.swift
//  Notepad++
//
//  Editor settings tab
//

import SwiftUI

struct EditorSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Font Settings
            GroupBox("Font") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Font Family:")
                        Picker("", selection: $settings.fontName) {
                            ForEach(settingsManager.availableFonts, id: \.self) { font in
                                Text(font).tag(font)
                            }
                        }
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Font Size:")
                        Slider(value: $settings.fontSize, in: 8...24, step: 1)
                            .frame(width: 200)
                        Text("\(Int(settings.fontSize)) pt")
                            .frame(width: 50)
                    }
                    
                    // Font preview
                    Text("The quick brown fox jumps over the lazy dog")
                        .font(.custom(settings.fontName, size: CGFloat(settings.fontSize)))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding()
            }
            
            // Display Settings
            GroupBox("Display") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show line numbers", isOn: $settings.showLineNumbers)
                    Toggle("Show bookmarks margin", isOn: $settings.showBookmarks)
                    Toggle("Show indent guides", isOn: $settings.showIndentGuides)
                    Toggle("Highlight current line", isOn: $settings.highlightCurrentLine)
                    Toggle("Word wrap", isOn: $settings.wordWrap)
                    Toggle("Show whitespace", isOn: $settings.showWhitespace)
                    Toggle("Show end of line", isOn: $settings.showEndOfLine)
                    Toggle("Scroll beyond last line", isOn: $settings.scrollBeyondLastLine)
                }
                .padding()
            }
            
            // Caret Settings
            GroupBox("Caret") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Caret Width:")
                        Slider(value: $settings.caretWidth, in: 1...5, step: 1)
                            .frame(width: 150)
                        Text("\(Int(settings.caretWidth)) px")
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("Blink Rate:")
                        Slider(value: $settings.caretBlinkRate, in: 0...1200, step: 100)
                            .frame(width: 150)
                        Text("\(Int(settings.caretBlinkRate)) ms")
                            .frame(width: 60)
                    }
                    .help("0 = no blinking")
                    
                    Toggle("Enable multi-selection", isOn: $settings.enableMultiSelection)
                }
                .padding()
            }
            
            Spacer()
        }
    }
}