//
//  AllLanguageDefinitions.swift
//  Notepad++
//
//  Simplified version with essential languages for v0.3.3
//

import Foundation

extension LanguageDefinition {
    // Basic set of 30 languages for initial release
    // Full 94 languages will be added in phases to avoid compilation issues
    static let allLanguages: [LanguageDefinition] = [
        LanguageDefinition(name: "Normal Text", displayName: "Normal Text", extensions: ["txt"], commentLine: nil, commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "PHP", displayName: "PHP", extensions: ["php", "php3", "php4", "php5"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "C", displayName: "C", extensions: ["c", "h"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "C++", displayName: "C++", extensions: ["cpp", "cxx", "cc", "hpp"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "C#", displayName: "C#", extensions: ["cs"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Objective-C", displayName: "Objective-C", extensions: ["m", "mm"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Java", displayName: "Java", extensions: ["java"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "HTML", displayName: "HTML", extensions: ["html", "htm"], commentLine: nil, commentStart: "<!--", commentEnd: "-->", keywords: []),
        LanguageDefinition(name: "XML", displayName: "XML", extensions: ["xml", "xaml", "xsl"], commentLine: nil, commentStart: "<!--", commentEnd: "-->", keywords: []),
        LanguageDefinition(name: "Makefile", displayName: "Makefile", extensions: ["mak", "mk", "makefile"], commentLine: "#", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Batch", displayName: "Batch", extensions: ["bat", "cmd"], commentLine: "REM", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "SQL", displayName: "SQL", extensions: ["sql"], commentLine: "--", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "CSS", displayName: "CSS", extensions: ["css", "scss", "sass"], commentLine: nil, commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Perl", displayName: "Perl", extensions: ["pl", "pm"], commentLine: "#", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Python", displayName: "Python", extensions: ["py", "pyw"], commentLine: "#", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Lua", displayName: "Lua", extensions: ["lua"], commentLine: "--", commentStart: "--[[", commentEnd: "]]", keywords: []),
        LanguageDefinition(name: "Shell", displayName: "Shell", extensions: ["sh", "bash", "zsh"], commentLine: "#", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Assembly", displayName: "Assembly", extensions: ["asm", "s"], commentLine: ";", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Diff", displayName: "Diff", extensions: ["diff", "patch"], commentLine: nil, commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Ruby", displayName: "Ruby", extensions: ["rb", "rbw"], commentLine: "#", commentStart: "=begin", commentEnd: "=end", keywords: []),
        LanguageDefinition(name: "PowerShell", displayName: "PowerShell", extensions: ["ps1", "psm1", "psd1"], commentLine: "#", commentStart: "<#", commentEnd: "#>", keywords: []),
        LanguageDefinition(name: "JavaScript", displayName: "JavaScript", extensions: ["js", "mjs", "jsx"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "JSON", displayName: "JSON", extensions: ["json", "jsonc", "json5"], commentLine: nil, commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Markdown", displayName: "Markdown", extensions: ["md", "markdown"], commentLine: nil, commentStart: "<!--", commentEnd: "-->", keywords: []),
        LanguageDefinition(name: "TypeScript", displayName: "TypeScript", extensions: ["ts", "tsx"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Go", displayName: "Go", extensions: ["go"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Rust", displayName: "Rust", extensions: ["rs"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "Swift", displayName: "Swift", extensions: ["swift"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: []),
        LanguageDefinition(name: "YAML", displayName: "YAML", extensions: ["yml", "yaml"], commentLine: "#", commentStart: nil, commentEnd: nil, keywords: []),
        LanguageDefinition(name: "Kotlin", displayName: "Kotlin", extensions: ["kt", "kts"], commentLine: "//", commentStart: "/*", commentEnd: "*/", keywords: [])
    ]
    
    // Map for quick language lookup by name
    static let languageByName: [String: LanguageDefinition] = {
        var map: [String: LanguageDefinition] = [:]
        for lang in allLanguages {
            map[lang.name] = lang
        }
        return map
    }()
}

// For compatibility with old code expecting AllLanguages
struct AllLanguages {
    static let definitions = LanguageDefinition.allLanguages
}