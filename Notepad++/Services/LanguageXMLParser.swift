//
//  LanguageXMLParser.swift
//  Notepad++
//
//  Parser for Notepad++ langs.model.xml file
//  Converts XML language definitions to Swift models
//

import Foundation

class LanguageXMLParser: NSObject {
    private var languages: [NotepadPlusLanguage] = []
    private var currentLanguage: LanguageBuilder?
    private var currentElement: String = ""
    private var currentKeywordType: String = ""
    
    // Builder pattern for constructing languages
    private class LanguageBuilder {
        var name: String = ""
        var extensions: [String] = []
        var commentLine: String?
        var commentStart: String?
        var commentEnd: String?
        
        // Keyword storage
        var instre1: Set<String> = []
        var instre2: Set<String> = []
        var type1: Set<String> = []
        var type2: Set<String> = []
        var type3: Set<String> = []
        var type4: Set<String> = []
        var type5: Set<String> = []
        var type6: Set<String> = []
        var substyle1: Set<String> = []
        var substyle2: Set<String> = []
        var substyle3: Set<String> = []
        var substyle4: Set<String> = []
        var substyle5: Set<String> = []
        var substyle6: Set<String> = []
        var substyle7: Set<String> = []
        var substyle8: Set<String> = []
        
        func build() -> NotepadPlusLanguage {
            return NotepadPlusLanguage(
                name: name,
                extensions: extensions,
                commentLine: commentLine,
                commentStart: commentStart,
                commentEnd: commentEnd,
                keywords: NotepadPlusLanguage.LanguageKeywords(
                    instre1: instre1.isEmpty ? nil : instre1,
                    instre2: instre2.isEmpty ? nil : instre2,
                    type1: type1.isEmpty ? nil : type1,
                    type2: type2.isEmpty ? nil : type2,
                    type3: type3.isEmpty ? nil : type3,
                    type4: type4.isEmpty ? nil : type4,
                    type5: type5.isEmpty ? nil : type5,
                    type6: type6.isEmpty ? nil : type6,
                    substyle1: substyle1.isEmpty ? nil : substyle1,
                    substyle2: substyle2.isEmpty ? nil : substyle2,
                    substyle3: substyle3.isEmpty ? nil : substyle3,
                    substyle4: substyle4.isEmpty ? nil : substyle4,
                    substyle5: substyle5.isEmpty ? nil : substyle5,
                    substyle6: substyle6.isEmpty ? nil : substyle6,
                    substyle7: substyle7.isEmpty ? nil : substyle7,
                    substyle8: substyle8.isEmpty ? nil : substyle8
                )
            )
        }
        
        func setKeywords(_ keywords: String, for type: String) {
            let keywordSet = Set(keywords.split(separator: " ").map { String($0) })
            
            switch type {
            case "instre1": instre1 = keywordSet
            case "instre2": instre2 = keywordSet
            case "type1": type1 = keywordSet
            case "type2": type2 = keywordSet
            case "type3": type3 = keywordSet
            case "type4": type4 = keywordSet
            case "type5": type5 = keywordSet
            case "type6": type6 = keywordSet
            case "substyle1": substyle1 = keywordSet
            case "substyle2": substyle2 = keywordSet
            case "substyle3": substyle3 = keywordSet
            case "substyle4": substyle4 = keywordSet
            case "substyle5": substyle5 = keywordSet
            case "substyle6": substyle6 = keywordSet
            case "substyle7": substyle7 = keywordSet
            case "substyle8": substyle8 = keywordSet
            default:
                break
            }
        }
    }
    
    func parseLanguages(from xmlPath: String) -> [NotepadPlusLanguage] {
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

// MARK: - XMLParserDelegate
extension LanguageXMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "Language" {
            currentLanguage = LanguageBuilder()
            currentLanguage?.name = attributeDict["name"] ?? ""
            
            // Parse extensions
            if let ext = attributeDict["ext"] {
                currentLanguage?.extensions = ext.split(separator: " ").map { String($0) }
            }
            
            // Parse comment styles
            currentLanguage?.commentLine = attributeDict["commentLine"]
            currentLanguage?.commentStart = attributeDict["commentStart"]
            currentLanguage?.commentEnd = attributeDict["commentEnd"]
            
        } else if elementName == "Keywords" {
            currentKeywordType = attributeDict["name"] ?? ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedString.isEmpty && !currentKeywordType.isEmpty {
            currentLanguage?.setKeywords(trimmedString, for: currentKeywordType)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Language" {
            if let language = currentLanguage?.build() {
                languages.append(language)
            }
            currentLanguage = nil
        } else if elementName == "Keywords" {
            currentKeywordType = ""
        }
    }
}

// MARK: - Language Generator
extension LanguageXMLParser {
    /// Generates Swift code for all parsed languages
    static func generateSwiftCode(for languages: [NotepadPlusLanguage]) -> String {
        var code = """
        //
        //  GeneratedLanguages.swift
        //  Notepad++
        //
        //  AUTO-GENERATED from langs.model.xml
        //  DO NOT EDIT MANUALLY
        //  Generated on: \(Date())
        //
        
        import Foundation
        
        struct GeneratedLanguages {
            static let all: [NotepadPlusLanguage] = [
        """
        
        for language in languages {
            code += "\n        // \(language.name.uppercased())\n"
            code += "        NotepadPlusLanguage(\n"
            code += "            name: \"\(language.name)\",\n"
            code += "            extensions: \(language.extensions.map { "\"\($0)\"" }),\n"
            code += "            commentLine: \(language.commentLine != nil ? "\"\(language.commentLine!)\"" : "nil"),\n"
            code += "            commentStart: \(language.commentStart != nil ? "\"\(language.commentStart!)\"" : "nil"),\n"
            code += "            commentEnd: \(language.commentEnd != nil ? "\"\(language.commentEnd!)\"" : "nil"),\n"
            code += "            keywords: NotepadPlusLanguage.LanguageKeywords(\n"
            
            // Add keyword sets
            code += generateKeywordSet("instre1", language.keywords.instre1)
            code += generateKeywordSet("instre2", language.keywords.instre2)
            code += generateKeywordSet("type1", language.keywords.type1)
            code += generateKeywordSet("type2", language.keywords.type2)
            code += generateKeywordSet("type3", language.keywords.type3)
            code += generateKeywordSet("type4", language.keywords.type4)
            code += generateKeywordSet("type5", language.keywords.type5)
            code += generateKeywordSet("type6", language.keywords.type6)
            code += generateKeywordSet("substyle1", language.keywords.substyle1)
            code += generateKeywordSet("substyle2", language.keywords.substyle2)
            code += generateKeywordSet("substyle3", language.keywords.substyle3)
            code += generateKeywordSet("substyle4", language.keywords.substyle4)
            code += generateKeywordSet("substyle5", language.keywords.substyle5)
            code += generateKeywordSet("substyle6", language.keywords.substyle6)
            code += generateKeywordSet("substyle7", language.keywords.substyle7)
            code += generateKeywordSet("substyle8", language.keywords.substyle8, isLast: true)
            
            code += "            )\n"
            code += "        ),\n"
        }
        
        code = String(code.dropLast(2)) // Remove last comma and newline
        code += "\n    ]\n}\n"
        
        return code
    }
    
    private static func generateKeywordSet(_ name: String, _ keywords: Set<String>?, isLast: Bool = false) -> String {
        let comma = isLast ? "" : ","
        
        guard let keywords = keywords, !keywords.isEmpty else {
            return "                \(name): nil\(comma)\n"
        }
        
        // Split into chunks for readability
        let sortedKeywords = keywords.sorted()
        var result = "                \(name): Set([\n"
        
        var line = "                    "
        for (index, keyword) in sortedKeywords.enumerated() {
            let quotedKeyword = "\"\(keyword.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
            
            if index == sortedKeywords.count - 1 {
                line += quotedKeyword
                result += line + "\n"
            } else if line.count + quotedKeyword.count + 2 > 120 {
                result += line + ",\n"
                line = "                    " + quotedKeyword
            } else {
                line += quotedKeyword + ", "
            }
        }
        
        result += "                ])\(comma)\n"
        return result
    }
}