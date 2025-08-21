//
//  ThemeManager.swift
//  Notepad++
//
//  Manages syntax highlighting themes and appearance settings
//

import Foundation
import AppKit
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    
    init() {
        // Initialize with default theme based on settings
        self.currentTheme = ThemeManager.getTheme(named: AppSettings.shared.theme)
        
        // Observe settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .settingsDidChange,
            object: nil
        )
    }
    
    @objc private func settingsChanged() {
        let settings = AppSettings.shared
        
        // Update theme
        currentTheme = ThemeManager.getTheme(named: settings.theme)
        
        // Apply dark mode if enabled
        if settings.enableDarkMode {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        
        // Notify views to update
        objectWillChange.send()
    }
    
    static func getTheme(named name: String) -> Theme {
        switch name {
        case "Dark":
            return .dark
        case "Light":
            return .light
        case "Monokai":
            return .monokai
        case "Solarized":
            return .solarized
        case "VSCode":
            return .vscode
        default:
            return .defaultTheme
        }
    }
    
    static var availableThemes: [String] {
        ["Default", "Dark", "Light", "Monokai", "Solarized", "VSCode"]
    }
}

struct Theme {
    let name: String
    let backgroundColor: NSColor
    let textColor: NSColor
    let selectionColor: NSColor
    let currentLineColor: NSColor
    
    // Syntax colors
    let keywordColor: NSColor
    let stringColor: NSColor
    let commentColor: NSColor
    let numberColor: NSColor
    let functionColor: NSColor
    let typeColor: NSColor
    let operatorColor: NSColor
    let bracketColor: NSColor
    
    static let defaultTheme = Theme(
        name: "Default",
        backgroundColor: NSColor.white,  // Explicit white background
        textColor: NSColor.black,  // Explicit black text for guaranteed contrast
        selectionColor: NSColor.selectedTextBackgroundColor,
        currentLineColor: NSColor(white: 0.95, alpha: 1.0),
        keywordColor: .systemPurple,
        stringColor: .systemRed,
        commentColor: .systemGreen,
        numberColor: .systemOrange,
        functionColor: .systemIndigo,
        typeColor: .systemBlue,
        operatorColor: .systemPink,
        bracketColor: .systemYellow
    )
    
    static let dark = Theme(
        name: "Dark",
        backgroundColor: NSColor(hex: "#1e1e1e") ?? .black,
        textColor: NSColor(hex: "#d4d4d4") ?? .white,
        selectionColor: NSColor(hex: "#264f78") ?? .blue,
        currentLineColor: NSColor(hex: "#2a2a2a") ?? .darkGray,
        keywordColor: NSColor(hex: "#569cd6") ?? .systemBlue,
        stringColor: NSColor(hex: "#ce9178") ?? .systemOrange,
        commentColor: NSColor(hex: "#6a9955") ?? .systemGreen,
        numberColor: NSColor(hex: "#b5cea8") ?? .systemMint,
        functionColor: NSColor(hex: "#dcdcaa") ?? .systemYellow,
        typeColor: NSColor(hex: "#4ec9b0") ?? .systemTeal,
        operatorColor: NSColor(hex: "#d4d4d4") ?? .white,
        bracketColor: NSColor(hex: "#ffd700") ?? .systemYellow
    )
    
    static let light = Theme(
        name: "Light",
        backgroundColor: .white,
        textColor: .black,
        selectionColor: NSColor(hex: "#add6ff") ?? .systemBlue,
        currentLineColor: NSColor(hex: "#f0f0f0") ?? .lightGray,
        keywordColor: NSColor(hex: "#0000ff") ?? .blue,
        stringColor: NSColor(hex: "#a31515") ?? .red,
        commentColor: NSColor(hex: "#008000") ?? .green,
        numberColor: NSColor(hex: "#098658") ?? .systemTeal,
        functionColor: NSColor(hex: "#795e26") ?? .brown,
        typeColor: NSColor(hex: "#267f99") ?? .systemCyan,
        operatorColor: .black,
        bracketColor: NSColor(hex: "#ff8c00") ?? .orange
    )
    
    static let monokai = Theme(
        name: "Monokai",
        backgroundColor: NSColor(hex: "#272822") ?? .black,
        textColor: NSColor(hex: "#f8f8f2") ?? .white,
        selectionColor: NSColor(hex: "#49483e") ?? .darkGray,
        currentLineColor: NSColor(hex: "#3e3d32") ?? .darkGray,
        keywordColor: NSColor(hex: "#f92672") ?? .systemPink,
        stringColor: NSColor(hex: "#e6db74") ?? .systemYellow,
        commentColor: NSColor(hex: "#75715e") ?? .gray,
        numberColor: NSColor(hex: "#ae81ff") ?? .systemPurple,
        functionColor: NSColor(hex: "#a6e22e") ?? .systemGreen,
        typeColor: NSColor(hex: "#66d9ef") ?? .systemCyan,
        operatorColor: NSColor(hex: "#f92672") ?? .systemPink,
        bracketColor: NSColor(hex: "#f8f8f2") ?? .white
    )
    
    static let solarized = Theme(
        name: "Solarized",
        backgroundColor: NSColor(hex: "#002b36") ?? .black,
        textColor: NSColor(hex: "#839496") ?? .lightGray,
        selectionColor: NSColor(hex: "#073642") ?? .darkGray,
        currentLineColor: NSColor(hex: "#073642") ?? .darkGray,
        keywordColor: NSColor(hex: "#859900") ?? .systemGreen,
        stringColor: NSColor(hex: "#2aa198") ?? .systemCyan,
        commentColor: NSColor(hex: "#586e75") ?? .gray,
        numberColor: NSColor(hex: "#d33682") ?? .systemPink,
        functionColor: NSColor(hex: "#268bd2") ?? .systemBlue,
        typeColor: NSColor(hex: "#b58900") ?? .systemYellow,
        operatorColor: NSColor(hex: "#839496") ?? .lightGray,
        bracketColor: NSColor(hex: "#cb4b16") ?? .systemOrange
    )
    
    static let vscode = Theme(
        name: "VSCode",
        backgroundColor: NSColor(hex: "#1e1e1e") ?? .black,
        textColor: NSColor(hex: "#d4d4d4") ?? .white,
        selectionColor: NSColor(hex: "#add6ff26") ?? .blue.withAlphaComponent(0.15),
        currentLineColor: NSColor(hex: "#2a2d2e") ?? .darkGray,
        keywordColor: NSColor(hex: "#569cd6") ?? .systemBlue,
        stringColor: NSColor(hex: "#ce9178") ?? .systemOrange,
        commentColor: NSColor(hex: "#6a9955") ?? .systemGreen,
        numberColor: NSColor(hex: "#b5cea8") ?? .systemMint,
        functionColor: NSColor(hex: "#dcdcaa") ?? .systemYellow,
        typeColor: NSColor(hex: "#4ec9b0") ?? .systemTeal,
        operatorColor: NSColor(hex: "#d4d4d4") ?? .white,
        bracketColor: NSColor(hex: "#d7ba7d") ?? .systemYellow
    )
}

// Extension to apply theme to syntax highlighter
extension Theme {
    func colorForTokenType(_ type: String) -> NSColor {
        switch type.lowercased() {
        case "keyword", "keywords", "instruction":
            return keywordColor
        case "string", "strings":
            return stringColor
        case "comment", "comments":
            return commentColor
        case "number", "numbers", "literal", "literals":
            return numberColor
        case "function", "functions":
            return functionColor
        case "type", "types":
            return typeColor
        case "operator", "operators":
            return operatorColor
        case "bracket", "brackets":
            return bracketColor
        default:
            return textColor
        }
    }
}