#!/usr/bin/env swift

import Foundation

// Parse the langs.model.xml file and generate Swift code for all languages

let xmlPath = "/Users/pedrogruvhagen/Work/Notebook++/notepad-plus-plus-reference/PowerEditor/src/langs.model.xml"
let xmlData = try! Data(contentsOf: URL(fileURLWithPath: xmlPath))

class LanguageXMLDelegate: NSObject, XMLParserDelegate {
    var languages: [String] = []
    var currentLanguage: [String: Any] = [:]
    var currentElement = ""
    var currentKeywords: [String: String] = [:]
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "Language" {
            currentLanguage = [:]
            currentLanguage["name"] = attributeDict["name"] ?? ""
            currentLanguage["ext"] = attributeDict["ext"] ?? ""
            currentLanguage["commentLine"] = attributeDict["commentLine"]
            currentLanguage["commentStart"] = attributeDict["commentStart"]
            currentLanguage["commentEnd"] = attributeDict["commentEnd"]
            currentKeywords = [:]
        } else if elementName == "Keywords" {
            let name = attributeDict["name"] ?? ""
            currentKeywords[name] = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "Keywords" && !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            for (key, _) in currentKeywords {
                currentKeywords[key] = (currentKeywords[key] ?? "") + string
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Language" {
            currentLanguage["keywords"] = currentKeywords
            generateLanguageCode()
        }
        currentElement = ""
    }
    
    func generateLanguageCode() {
        guard let name = currentLanguage["name"] as? String,
              !name.isEmpty else { return }
        
        let ext = currentLanguage["ext"] as? String ?? ""
        let commentLine = currentLanguage["commentLine"] as? String
        let commentStart = currentLanguage["commentStart"] as? String
        let commentEnd = currentLanguage["commentEnd"] as? String
        let keywords = currentLanguage["keywords"] as? [String: String] ?? [:]
        
        // Parse extensions
        let extensions = ext.split(separator: " ").map { "\"\($0)\"" }.joined(separator: ", ")
        
        // Helper function to escape Swift string literals
        func escapeForSwift(_ str: String) -> String {
            return str
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
        }
        
        // Generate keyword sets
        var keywordSets: [String: String] = [:]
        for (keyName, keywordString) in keywords {
            let words = keywordString.split(separator: " ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { "\"\(escapeForSwift(String($0)))\"" }
            
            if !words.isEmpty {
                keywordSets[keyName] = "Set([\(words.joined(separator: ", "))])"
            }
        }
        
        // Map Notepad++ keyword names to our structure
        let instre1 = keywordSets["instre1"] ?? "nil"
        let instre2 = keywordSets["instre2"] ?? "nil"
        let type1 = keywordSets["type1"] ?? "nil"
        let type2 = keywordSets["type2"] ?? "nil"
        let type3 = keywordSets["type3"] ?? "nil"
        let type4 = keywordSets["type4"] ?? "nil"
        let type5 = keywordSets["type5"] ?? "nil"
        let type6 = keywordSets["type6"] ?? "nil"
        
        // Generate Swift code
        let code = """
        
        // \(name.uppercased())
        NotepadPlusLanguage(
            name: "\(name.lowercased())",
            extensions: [\(extensions)],
            commentLine: \(commentLine != nil ? "\"\(escapeForSwift(commentLine!))\"" : "nil"),
            commentStart: \(commentStart != nil ? "\"\(escapeForSwift(commentStart!))\"" : "nil"),
            commentEnd: \(commentEnd != nil ? "\"\(escapeForSwift(commentEnd!))\"" : "nil"),
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: \(instre1),
                instre2: \(instre2),
                type1: \(type1),
                type2: \(type2),
                type3: \(type3),
                type4: \(type4),
                type5: \(type5),
                type6: \(type6),
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        """
        
        languages.append(code)
    }
}

let parser = XMLParser(data: xmlData)
let delegate = LanguageXMLDelegate()
parser.delegate = delegate
parser.parse()

// Generate the complete Swift file
let header = """
//
//  AllLanguageDefinitions.swift
//  Notepad++
//
//  AUTO-GENERATED from langs.model.xml - DO NOT EDIT MANUALLY
//  Total languages: \(delegate.languages.count)
//

import Foundation

struct AllLanguages {
    static let definitions: [NotepadPlusLanguage] = [
"""

let footer = """
    ]
}
"""

let fullCode = header + delegate.languages.joined(separator: "") + footer

// Write to file
let outputPath = "/Users/pedrogruvhagen/Work/Notebook++/Notepad++/Notepad++/Models/AllLanguageDefinitions.swift"
try! fullCode.write(toFile: outputPath, atomically: true, encoding: .utf8)

print("Generated \(delegate.languages.count) language definitions")
print("Output written to: \(outputPath)")