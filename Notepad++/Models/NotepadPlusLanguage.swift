//
//  NotepadPlusLanguage.swift
//  Notepad++
//
//  Direct port of Notepad++ language definitions
//  This matches the exact structure from langs.model.xml
//

import Foundation

/// Complete language definition matching Notepad++ structure
struct NotepadPlusLanguage: Codable, Identifiable {
    var id = UUID()
    let name: String
    let extensions: [String]
    let commentLine: String?
    let commentStart: String?
    let commentEnd: String?
    
    // Keyword categories from Notepad++
    let keywords: LanguageKeywords
    
    struct LanguageKeywords: Codable {
        // Primary instruction sets
        let instre1: Set<String>?
        let instre2: Set<String>?
        
        // Type categories
        let type1: Set<String>?
        let type2: Set<String>?
        let type3: Set<String>?
        let type4: Set<String>?
        let type5: Set<String>? // Fold open keywords
        let type6: Set<String>? // Fold close keywords
        
        // Substyles for languages like C/C++
        let substyle1: Set<String>?
        let substyle2: Set<String>?
        let substyle3: Set<String>?
        let substyle4: Set<String>?
        let substyle5: Set<String>?
        let substyle6: Set<String>?
        let substyle7: Set<String>?
        let substyle8: Set<String>?
    }
    
    // Convert to our existing LanguageDefinition for compatibility
    func toLanguageDefinition() -> LanguageDefinition {
        var keywordSets: [KeywordSet] = []
        
        // Create keyword sets from different categories
        if let instre1 = keywords.instre1, !instre1.isEmpty {
            keywordSets.append(KeywordSet(
                name: "Instructions",
                keywords: Array(instre1),
                style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
            ))
        }
        
        if let instre2 = keywords.instre2, !instre2.isEmpty {
            keywordSets.append(KeywordSet(
                name: "Instructions 2",
                keywords: Array(instre2),
                style: SyntaxStyle(color: "0080FF", backgroundColor: nil, bold: false, italic: false, underline: false)
            ))
        }
        
        if let type1 = keywords.type1, !type1.isEmpty {
            keywordSets.append(KeywordSet(
                name: "Types",
                keywords: Array(type1),
                style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
            ))
        }
        
        if let type2 = keywords.type2, !type2.isEmpty {
            keywordSets.append(KeywordSet(
                name: "Types 2",
                keywords: Array(type2),
                style: SyntaxStyle(color: "FF8000", backgroundColor: nil, bold: false, italic: false, underline: false)
            ))
        }
        
        // Add substyles if present
        let substyles: [(Set<String>?, Int)] = [
            (keywords.substyle1, 1), (keywords.substyle2, 2), (keywords.substyle3, 3),
            (keywords.substyle4, 4), (keywords.substyle5, 5), (keywords.substyle6, 6),
            (keywords.substyle7, 7), (keywords.substyle8, 8)
        ]
        
        for (substyle, index) in substyles {
            if let style = substyle, !style.isEmpty {
                keywordSets.append(KeywordSet(
                    name: "Custom \(index)",
                    keywords: Array(style),
                    style: SyntaxStyle(color: "008080", backgroundColor: nil, bold: false, italic: true, underline: false)
                ))
            }
        }
        
        return LanguageDefinition(
            name: name,
            displayName: name.capitalized,
            extensions: extensions,
            commentLine: commentLine,
            commentStart: commentStart,
            commentEnd: commentEnd,
            keywords: keywordSets
        )
    }
}

// Language categories as organized in Notepad++
enum LanguageCategory: String, CaseIterable {
    case popular = "Popular"
    case web = "Web"
    case script = "Script"
    case markup = "Markup"
    case misc = "Misc"
    case custom = "User Defined"
    
    var languages: [String] {
        switch self {
        case .popular:
            return ["c", "cpp", "cs", "java", "javascript", "python", "swift"]
        case .web:
            return ["html", "xml", "css", "php", "asp", "jsp"]
        case .script:
            return ["bash", "batch", "powershell", "perl", "ruby", "lua"]
        case .markup:
            return ["markdown", "tex", "yaml", "json", "ini"]
        case .misc:
            return ["sql", "diff", "makefile", "cmake", "dockerfile"]
        case .custom:
            return [] // User-defined languages
        }
    }
}