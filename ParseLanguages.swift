#!/usr/bin/env swift
//
//  ParseLanguages.swift
//  Notepad++
//
//  Command-line tool to parse langs.model.xml and generate Swift code
//  Usage: swift ParseLanguages.swift
//

import Foundation

// Copy the parser classes here for standalone execution
class LanguageXMLParser: NSObject {
    private var languages: [[String: Any]] = []
    private var currentLanguage: [String: Any] = [:]
    private var currentElement: String = ""
    private var currentKeywordType: String = ""
    private var currentKeywords: String = ""
    
    func parseLanguages(from xmlPath: String) -> [[String: Any]] {
        guard let xmlData = try? Data(contentsOf: URL(fileURLWithPath: xmlPath)) else {
            print("Failed to load XML file at path: \(xmlPath)")
            return []
        }
        
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        
        return languages
    }
}

extension LanguageXMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "Language" {
            currentLanguage = [:]
            currentLanguage["name"] = attributeDict["name"] ?? ""
            
            if let ext = attributeDict["ext"] {
                currentLanguage["extensions"] = ext.split(separator: " ").map { String($0) }
            } else {
                currentLanguage["extensions"] = []
            }
            
            currentLanguage["commentLine"] = attributeDict["commentLine"] ?? ""
            currentLanguage["commentStart"] = attributeDict["commentStart"] ?? ""
            currentLanguage["commentEnd"] = attributeDict["commentEnd"] ?? ""
            currentLanguage["keywords"] = [String: [String]]()
            
        } else if elementName == "Keywords" {
            currentKeywordType = attributeDict["name"] ?? ""
            currentKeywords = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "Keywords" && !currentKeywordType.isEmpty {
            currentKeywords += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Language" {
            languages.append(currentLanguage)
            currentLanguage = [:]
        } else if elementName == "Keywords" {
            let trimmedKeywords = currentKeywords.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKeywords.isEmpty {
                var keywords = currentLanguage["keywords"] as? [String: [String]] ?? [:]
                keywords[currentKeywordType] = trimmedKeywords.split(separator: " ").map { String($0) }
                currentLanguage["keywords"] = keywords
            }
            currentKeywordType = ""
            currentKeywords = ""
        }
    }
}

// Main execution
let parser = LanguageXMLParser()
let xmlPath = "../notepad-plus-plus-reference/PowerEditor/src/langs.model.xml"
let languages = parser.parseLanguages(from: xmlPath)

print("Parsed \(languages.count) languages from XML")

// Generate Swift code
var swiftCode = """
//
//  AllLanguageDefinitions.swift
//  Notepad++
//
//  AUTO-GENERATED from langs.model.xml - DO NOT EDIT
//  Generated on: \(Date())
//  Total languages: \(languages.count)
//

import Foundation

// Static storage for all language definitions
struct AllLanguages {
    static let definitions: [NotepadPlusLanguage] = [
"""

for language in languages {
    let name = language["name"] as? String ?? ""
    let extensions = language["extensions"] as? [String] ?? []
    let commentLine = language["commentLine"] as? String ?? ""
    let commentStart = language["commentStart"] as? String ?? ""
    let commentEnd = language["commentEnd"] as? String ?? ""
    let keywords = language["keywords"] as? [String: [String]] ?? [:]
    
    swiftCode += "\n        NotepadPlusLanguage(\n"
    swiftCode += "            name: \"\(name)\",\n"
    swiftCode += "            extensions: [\(extensions.map { "\"\($0)\"" }.joined(separator: ", "))],\n"
    // Properly escape comment delimiters
    let escapedCommentLine = commentLine
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    let escapedCommentStart = commentStart
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    let escapedCommentEnd = commentEnd
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    
    swiftCode += "            commentLine: \(commentLine.isEmpty ? "nil" : "\"\(escapedCommentLine)\""),\n"
    swiftCode += "            commentStart: \(commentStart.isEmpty ? "nil" : "\"\(escapedCommentStart)\""),\n"
    swiftCode += "            commentEnd: \(commentEnd.isEmpty ? "nil" : "\"\(escapedCommentEnd)\""),\n"
    swiftCode += "            keywords: NotepadPlusLanguage.LanguageKeywords(\n"
    
    // Add each keyword category
    let keywordCategories = ["instre1", "instre2", "type1", "type2", "type3", "type4", "type5", "type6",
                            "substyle1", "substyle2", "substyle3", "substyle4", "substyle5", "substyle6", "substyle7", "substyle8"]
    
    for (index, category) in keywordCategories.enumerated() {
        let isLast = index == keywordCategories.count - 1
        let categoryKeywords = keywords[category] ?? []
        
        if categoryKeywords.isEmpty {
            swiftCode += "                \(category): nil\(isLast ? "" : ",")\n"
        } else {
            // Escape special characters in keywords
            let escapedKeywords = categoryKeywords.map { keyword in
                let escaped = keyword
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "\r", with: "\\r")
                    .replacingOccurrences(of: "\t", with: "\\t")
                return "\"\(escaped)\""
            }
            
            // Format keywords nicely
            if escapedKeywords.count <= 5 {
                swiftCode += "                \(category): Set([\(escapedKeywords.joined(separator: ", "))])\(isLast ? "" : ",")\n"
            } else {
                swiftCode += "                \(category): Set([\n"
                for (kidx, kw) in escapedKeywords.enumerated() {
                    if kidx % 8 == 0 {
                        swiftCode += "                    "
                    }
                    swiftCode += kw
                    if kidx < escapedKeywords.count - 1 {
                        swiftCode += ", "
                        if (kidx + 1) % 8 == 0 {
                            swiftCode += "\n"
                        }
                    }
                }
                swiftCode += "\n                ])\(isLast ? "" : ",")\n"
            }
        }
    }
    
    swiftCode += "            )\n"
    swiftCode += "        ),\n"
}

swiftCode = String(swiftCode.dropLast(2)) // Remove last comma
swiftCode += """

    ]
}
"""

// Write to file
let outputPath = "Notepad++/Models/AllLanguageDefinitions.swift"
do {
    try swiftCode.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("Successfully generated Swift code to: \(outputPath)")
    print("Total size: \(swiftCode.count) characters")
} catch {
    print("Failed to write file: \(error)")
}

// Print summary
print("\n=== Language Summary ===")
for language in languages.prefix(10) {
    if let name = language["name"] as? String,
       let extensions = language["extensions"] as? [String] {
        print("- \(name): \(extensions.joined(separator: ", "))")
    }
}
print("... and \(languages.count - 10) more languages")