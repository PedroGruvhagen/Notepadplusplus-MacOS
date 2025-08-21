//
//  LanguageManager.swift
//  Notepad++
//
//  Manages all language definitions and switching
//  Direct port of Notepad++ language system
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: NotepadPlusLanguage?
    @Published var availableLanguages: [NotepadPlusLanguage] = []
    
    // Language lookup by extension
    private var extensionMap: [String: NotepadPlusLanguage] = [:]
    
    // Categories matching Notepad++ menu structure
    var categorizedLanguages: [LanguageCategory: [NotepadPlusLanguage]] {
        var result: [LanguageCategory: [NotepadPlusLanguage]] = [:]
        
        // Popular languages (most commonly used)
        let popularNames = ["c", "cpp", "cs", "java", "javascript", "python", "swift", "go", "rust", "typescript"]
        result[.popular] = availableLanguages.filter { popularNames.contains($0.name) }
        
        // Web languages
        let webNames = ["html", "xml", "css", "php", "asp", "jsp", "javascript", "typescript"]
        result[.web] = availableLanguages.filter { webNames.contains($0.name) }
        
        // Script languages
        let scriptNames = ["bash", "batch", "powershell", "perl", "ruby", "lua", "python", "tcl", "autoit"]
        result[.script] = availableLanguages.filter { scriptNames.contains($0.name) }
        
        // Markup languages
        let markupNames = ["markdown", "tex", "yaml", "json", "ini", "xml", "html", "asn1"]
        result[.markup] = availableLanguages.filter { markupNames.contains($0.name) }
        
        // Misc/Other languages
        let miscNames = ["sql", "diff", "makefile", "cmake", "dockerfile", "fortran", "pascal", "vhdl", "verilog"]
        result[.misc] = availableLanguages.filter { miscNames.contains($0.name) }
        
        return result
    }
    
    // All languages alphabetically
    var alphabeticalLanguages: [NotepadPlusLanguage] {
        availableLanguages.sorted { $0.name < $1.name }
    }
    
    private init() {
        loadAllLanguages()
    }
    
    private func loadAllLanguages() {
        // Load all generated languages from AllLanguages struct
        // Convert LanguageDefinitions to NotepadPlusLanguages
        availableLanguages = AllLanguages.definitions.map { langDef in
            // Create empty keywords for now - will be populated from XML later
            let emptyKeywords = NotepadPlusLanguage.LanguageKeywords(
                instre1: nil,
                instre2: nil,
                type1: nil,
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil,
                substyle2: nil,
                substyle3: nil,
                substyle4: nil,
                substyle5: nil,
                substyle6: nil,
                substyle7: nil,
                substyle8: nil
            )
            
            return NotepadPlusLanguage(
                name: langDef.name,
                extensions: langDef.extensions,
                commentLine: langDef.commentLine,
                commentStart: langDef.commentStart,
                commentEnd: langDef.commentEnd,
                keywords: emptyKeywords
            )
        }
        
        // Build extension map for fast lookup
        for language in availableLanguages {
            for ext in language.extensions {
                extensionMap[ext.lowercased()] = language
            }
        }
        
        print("Loaded \(availableLanguages.count) languages")
    }
    
    /// Detect language from file extension
    func detectLanguage(for fileName: String) -> NotepadPlusLanguage? {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        if let language = extensionMap[ext] {
            return language
        }
        
        // Special cases
        if fileName == "Makefile" || fileName == "makefile" {
            return availableLanguages.first { $0.name == "makefile" }
        }
        
        if fileName == "Dockerfile" {
            return availableLanguages.first { $0.name == "dockerfile" }
        }
        
        if fileName.hasSuffix(".bashrc") || fileName.hasSuffix(".bash_profile") {
            return availableLanguages.first { $0.name == "bash" }
        }
        
        // Default to normal text
        return availableLanguages.first { $0.name == "normal" }
    }
    
    /// Set the current language
    func setLanguage(_ language: NotepadPlusLanguage) {
        currentLanguage = language
        NotificationCenter.default.post(
            name: .languageChanged,
            object: nil,
            userInfo: ["language": language]
        )
    }
    
    /// Get language by name
    func getLanguage(named name: String) -> NotepadPlusLanguage? {
        return availableLanguages.first { $0.name.lowercased() == name.lowercased() }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Menu Support
extension LanguageManager {
    /// Generate menu items for Language menu
    func createLanguageMenuItems() -> [NSMenuItem] {
        var items: [NSMenuItem] = []
        
        // Add category submenus
        for category in LanguageCategory.allCases {
            let submenu = NSMenu(title: category.rawValue)
            let submenuItem = NSMenuItem(title: category.rawValue, action: nil, keyEquivalent: "")
            submenuItem.submenu = submenu
            
            let languages = categorizedLanguages[category] ?? []
            for language in languages.sorted(by: { $0.name < $1.name }) {
                let item = NSMenuItem(
                    title: language.name.capitalized,
                    action: #selector(LanguageMenuHandler.selectLanguage(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = language.name
                item.state = currentLanguage?.name == language.name ? .on : .off
                submenu.addItem(item)
            }
            
            if !languages.isEmpty {
                items.append(submenuItem)
            }
        }
        
        items.append(NSMenuItem.separator())
        
        // Add "All Languages" submenu
        let allSubmenu = NSMenu(title: "All Languages")
        let allSubmenuItem = NSMenuItem(title: "All Languages", action: nil, keyEquivalent: "")
        allSubmenuItem.submenu = allSubmenu
        
        // Group by first letter
        var letterGroups: [Character: [NotepadPlusLanguage]] = [:]
        for language in alphabeticalLanguages {
            let firstLetter = language.name.uppercased().first ?? "#"
            if letterGroups[firstLetter] == nil {
                letterGroups[firstLetter] = []
            }
            letterGroups[firstLetter]?.append(language)
        }
        
        for letter in letterGroups.keys.sorted() {
            if let languages = letterGroups[letter] {
                allSubmenu.addItem(NSMenuItem.separator())
                allSubmenu.addItem(NSMenuItem(title: String(letter), action: nil, keyEquivalent: ""))
                
                for language in languages {
                    let item = NSMenuItem(
                        title: "  \(language.name.capitalized)",
                        action: #selector(LanguageMenuHandler.selectLanguage(_:)),
                        keyEquivalent: ""
                    )
                    item.representedObject = language.name
                    item.state = currentLanguage?.name == language.name ? .on : .off
                    allSubmenu.addItem(item)
                }
            }
        }
        
        items.append(allSubmenuItem)
        
        return items
    }
}

// Menu handler class for selector
@objc class LanguageMenuHandler: NSObject {
    @objc static func selectLanguage(_ sender: NSMenuItem) {
        if let languageName = sender.representedObject as? String,
           let language = LanguageManager.shared.getLanguage(named: languageName) {
            LanguageManager.shared.setLanguage(language)
        }
    }
}