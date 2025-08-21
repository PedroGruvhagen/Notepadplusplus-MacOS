#!/usr/bin/env swift

import Foundation

// Parse langs.model.xml to extract ALL language definitions
let xmlPath = "../notepad-plus-plus-reference/PowerEditor/src/langs.model.xml"
let xmlData = try! Data(contentsOf: URL(fileURLWithPath: xmlPath))

struct LanguageData {
    let id: Int
    let name: String
    let ext: String
    let commentLine: String?
    let commentStart: String?
    let commentEnd: String?
}

class LanguageParser: NSObject, XMLParserDelegate {
    var languages: [LanguageData] = []
    var currentLanguage: (id: Int, name: String, ext: String)?
    var currentCommentLine: String?
    var currentCommentStart: String?
    var currentCommentEnd: String?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Language" {
            if let name = attributeDict["name"],
               let idStr = attributeDict["id"],
               let id = Int(idStr) {
                let ext = attributeDict["ext"] ?? ""  // ext can be empty
                currentLanguage = (id, name, ext)
                currentCommentLine = attributeDict["commentLine"]
                currentCommentStart = attributeDict["commentStart"]
                currentCommentEnd = attributeDict["commentEnd"]
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Language" {
            if let lang = currentLanguage {
                languages.append(LanguageData(
                    id: lang.id,
                    name: lang.name,
                    ext: lang.ext,
                    commentLine: currentCommentLine,
                    commentStart: currentCommentStart,
                    commentEnd: currentCommentEnd
                ))
            }
            currentLanguage = nil
            currentCommentLine = nil
            currentCommentStart = nil
            currentCommentEnd = nil
        }
    }
}

let parser = XMLParser(data: xmlData)
let delegate = LanguageParser()
parser.delegate = delegate
parser.parse()

// Sort languages by ID
let sortedLanguages = delegate.languages.sorted { $0.id < $1.id }

print("Found \(sortedLanguages.count) languages from Notepad++!")
print("IDs range from \(sortedLanguages.first?.id ?? 0) to \(sortedLanguages.last?.id ?? 0)")

// Split into parts for easier compilation (25 per file)
let chunkSize = 25
var chunks: [[LanguageData]] = []
var currentIndex = 0
while currentIndex < sortedLanguages.count {
    let end = min(currentIndex + chunkSize, sortedLanguages.count)
    chunks.append(Array(sortedLanguages[currentIndex..<end]))
    currentIndex = end
}

print("Splitting into \(chunks.count) files...")

// Generate a file for each chunk
for (index, chunk) in chunks.enumerated() {
    let partNumber = index + 1
    var output = """
//
//  AllLanguageDefinitions_Part\(partNumber).swift
//  Notepad++
//
//  Auto-generated from langs.model.xml - Part \(partNumber) of \(chunks.count)
//  Contains \(chunk.count) languages (IDs \(chunk.first?.id ?? 0)-\(chunk.last?.id ?? 0))
//

import Foundation

extension LanguageDefinition {
    static let allLanguagesPart\(partNumber): [LanguageDefinition] = [
"""
    
    for (idx, lang) in chunk.enumerated() {
        let extensions = lang.ext.isEmpty ? [] : lang.ext.split(separator: " ").map { "\"\($0)\"" }
        let extensionsStr = extensions.joined(separator: ", ")
        let commentLine = lang.commentLine.map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\"))\"" } ?? "nil"
        let commentStart = lang.commentStart.map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\"))\"" } ?? "nil"
        let commentEnd = lang.commentEnd.map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\"))\"" } ?? "nil"
        
        output += """

        LanguageDefinition(
            name: "\(lang.name.replacingOccurrences(of: "\"", with: "\\\""))",
            displayName: "\(lang.name.replacingOccurrences(of: "\"", with: "\\\""))",
            extensions: [\(extensionsStr)],
            commentLine: \(commentLine),
            commentStart: \(commentStart),
            commentEnd: \(commentEnd),
            keywords: []
        )\(idx < chunk.count - 1 ? "," : "")
"""
    }
    
    output += """

    ]
}
"""
    
    let fileName = "Notepad++/Models/AllLanguageDefinitions_Part\(partNumber).swift"
    try! output.write(to: URL(fileURLWithPath: fileName), atomically: true, encoding: .utf8)
    print("✓ Generated \(fileName) with \(chunk.count) languages")
}

// Generate the main file that combines all parts
var mainOutput = """
//
//  AllLanguageDefinitions.swift
//  Notepad++
//
//  Combines all language definition parts
//  Total: \(sortedLanguages.count) languages from Notepad++
//

import Foundation

extension LanguageDefinition {
    // Combine all language parts into one array
    // ALL 94+ LANGUAGES FROM NOTEPAD++ ARE INCLUDED
    static let allLanguages: [LanguageDefinition] = {
        var languages: [LanguageDefinition] = []
"""

for i in 1...chunks.count {
    mainOutput += """

        languages.append(contentsOf: allLanguagesPart\(i))
"""
}

mainOutput += """

        return languages
    }()
    
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
"""

try! mainOutput.write(to: URL(fileURLWithPath: "Notepad++/Models/AllLanguageDefinitions.swift"), atomically: true, encoding: .utf8)
print("\n✓ Generated main AllLanguageDefinitions.swift")
print("✓ Total languages: \(sortedLanguages.count)")

// Print language list
print("\n=== ALL NOTEPAD++ LANGUAGES ===")
for lang in sortedLanguages {
    let exts = lang.ext.isEmpty ? "no extensions" : lang.ext
    print("  \(String(format: "%2d", lang.id)). \(lang.name) [\(exts)]")
}