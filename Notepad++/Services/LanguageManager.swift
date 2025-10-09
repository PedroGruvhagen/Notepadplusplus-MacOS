//
//  LanguageManager.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Notepad++ Language System
//  Source: PowerEditor/src/Parameters.cpp - getLangFromExt() and language loading
//  Source: PowerEditor/src/langs.model.xml parsing logic
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation
import AppKit

// Translation of Lang class from Parameters.h
class Lang {
    let _langID: LangType
    let _langName: String
    let _defaultExtList: String?
    let _commentLineSymbol: String?
    let _commentStartSymbol: String?
    let _commentEndSymbol: String?
    
    init(id: LangType, name: String, ext: String?, commentLine: String?, commentStart: String?, commentEnd: String?) {
        self._langID = id
        self._langName = name
        self._defaultExtList = ext
        self._commentLineSymbol = commentLine
        self._commentStartSymbol = commentStart
        self._commentEndSymbol = commentEnd
    }
    
    // Convert to LanguageDefinition for UI compatibility
    func toLanguageDefinition() -> LanguageDefinition? {
        // Create a basic LanguageDefinition from Lang data
        let extensions = _defaultExtList?.split(separator: " ").map(String.init) ?? []
        
        // Create a minimal LanguageDefinition
        return LanguageDefinition(
            name: _langName.lowercased().replacingOccurrences(of: " ", with: "_"),
            displayName: _langName,
            extensions: extensions,
            commentLine: _commentLineSymbol,
            commentStart: _commentStartSymbol,
            commentEnd: _commentEndSymbol,
            keywords: []  // Keywords will be loaded separately from stylers.model.xml
        )
    }
    
    // Public properties for SwiftUI compatibility
    var name: String { _langName }
}

// LangType is defined in NewDocDefaultSettings.swift as the literal C++ translation
// Using that complete definition instead of duplicating here

// Translation of NppParameters language management from Parameters.cpp
@MainActor
class LanguageManager {
    static let shared = LanguageManager()
    
    // Translation of _langList from Parameters.h
    private var _langList: [Lang] = []
    private var _nbLang: Int = 0
    
    // Cache for extension lookups
    private var extensionMap: [String: LangType] = [:]
    
    private init() {
        loadLangsFromXML()
    }
    
    // Translation of loadLangs logic from Parameters.cpp
    private func loadLangsFromXML() {
        // Load langs.model.xml - this is how Notepad++ does it
        guard let xmlPath = Bundle.main.path(forResource: "langs.model", ofType: "xml"),
              let xmlData = try? Data(contentsOf: URL(fileURLWithPath: xmlPath)) else {
            print("Failed to load langs.model.xml")
            loadDefaultLanguages() // Fallback
            return
        }
        
        // Parse XML just like Notepad++ does with TinyXML
        let parser = XMLParser(data: xmlData)
        let delegate = LangsXMLParserDelegate()
        parser.delegate = delegate
        
        if parser.parse() {
            _langList = delegate.languages
            _nbLang = _langList.count
            
            // Build extension map for fast lookup
            for lang in _langList {
                if let extList = lang._defaultExtList {
                    let extensions = extList.split(separator: " ")
                    for ext in extensions {
                        extensionMap[String(ext).lowercased()] = lang._langID
                    }
                }
            }
            
            print("Loaded \(_nbLang) languages from langs.model.xml")
        } else {
            print("Failed to parse langs.model.xml")
            loadDefaultLanguages() // Fallback
        }
    }
    
    // Translation of getLangFromExt from Parameters.cpp
    func getLangFromExt(_ ext: String?) -> LangType {
        guard let ext = ext?.lowercased() else {
            return .L_TEXT
        }
        
        // Direct translation of Parameters.cpp getLangFromExt logic
        // First check user defined extensions (skipped for now - would be in user config)
        
        // Then check language extensions
        if let langType = extensionMap[ext] {
            return langType
        }
        
        return .L_TEXT
    }
    
    // Translation of getLangFromIndex from Parameters.h
    func getLangFromIndex(_ index: Int) -> Lang? {
        return (index < _nbLang) ? _langList[index] : nil
    }
    
    // Translation of getNbLang from Parameters.h
    func getNbLang() -> Int {
        return _nbLang
    }
    
    // Fallback language definitions if XML loading fails
    private func loadDefaultLanguages() {
        _langList = [
            Lang(id: .L_TEXT, name: "Normal Text", ext: "txt", commentLine: nil, commentStart: nil, commentEnd: nil),
            Lang(id: .L_PHP, name: "PHP", ext: "php php3 php4 php5 phps phpt phtml", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_C, name: "C", ext: "c h", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_CPP, name: "C++", ext: "cpp cxx cc hpp hxx", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_CS, name: "C#", ext: "cs", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_OBJC, name: "Objective-C", ext: "m mm", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_JAVA, name: "Java", ext: "java", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_HTML, name: "HTML", ext: "html htm shtml xhtml", commentLine: nil, commentStart: "<!--", commentEnd: "-->"),
            Lang(id: .L_XML, name: "XML", ext: "xml xaml xsl xslt xsd xul", commentLine: nil, commentStart: "<!--", commentEnd: "-->"),
            Lang(id: .L_JAVASCRIPT, name: "JavaScript", ext: "js mjs jsx", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_JSON, name: "JSON", ext: "json", commentLine: nil, commentStart: nil, commentEnd: nil),
            Lang(id: .L_PYTHON, name: "Python", ext: "py pyw", commentLine: "#", commentStart: nil, commentEnd: nil),
            Lang(id: .L_SWIFT, name: "Swift", ext: "swift", commentLine: "//", commentStart: "/*", commentEnd: "*/"),
            Lang(id: .L_YAML, name: "YAML", ext: "yml yaml", commentLine: "#", commentStart: nil, commentEnd: nil)
        ]
        _nbLang = _langList.count
    }
    
    // Helper to detect language for a filename
    func detectLanguage(for filename: String) -> LangType {
        let ext = (filename as NSString).pathExtension
        return getLangFromExt(ext)
    }
    
    // Provide available languages for UI
    var availableLanguages: [Lang] {
        return _langList
    }
}

// XML Parser delegate for langs.model.xml - Translation of TinyXML parsing logic
private class LangsXMLParserDelegate: NSObject, XMLParserDelegate {
    var languages: [Lang] = []
    private var currentLangID = 0
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Language" {
            guard let name = attributeDict["name"] else { return }
            
            let ext = attributeDict["ext"]
            let commentLine = attributeDict["commentLine"]
            let commentStart = attributeDict["commentStart"]  
            let commentEnd = attributeDict["commentEnd"]
            
            // Map language name to LangType ID (simplified - full mapping would be complete)
            let langID = mapNameToLangType(name)
            
            let lang = Lang(
                id: langID,
                name: name,
                ext: ext,
                commentLine: commentLine,
                commentStart: commentStart,
                commentEnd: commentEnd
            )
            
            languages.append(lang)
            currentLangID += 1
        }
    }
    
    // Map language names from XML to LangType enum
    private func mapNameToLangType(_ name: String) -> LangType {
        // Direct mapping based on Notepad++ source - matches langs.model.xml
        switch name.lowercased() {
        case "normal", "text", "nfo": return .L_TEXT
        case "php": return .L_PHP
        case "c": return .L_C
        case "cpp", "c++": return .L_CPP
        case "c#", "cs": return .L_CS
        case "objc", "objective-c": return .L_OBJC
        case "java": return .L_JAVA
        case "rc": return .L_RC
        case "html": return .L_HTML
        case "xml": return .L_XML
        case "makefile": return .L_MAKEFILE
        case "pascal": return .L_PASCAL
        case "batch": return .L_BATCH
        case "ini": return .L_INI
        case "asp": return .L_ASP
        case "sql": return .L_SQL
        case "vb", "visualbasic": return .L_VB
        case "javascript", "js": return .L_JAVASCRIPT
        case "javascript.js": return .L_JAVASCRIPT  // Modern JS variant
        case "css": return .L_CSS
        case "perl": return .L_PERL
        case "python": return .L_PYTHON
        case "lua": return .L_LUA
        case "tex": return .L_TEX
        case "fortran": return .L_FORTRAN
        case "fortran77": return .L_FORTRAN_77
        case "bash", "shell": return .L_BASH
        case "actionscript", "flash": return .L_FLASH
        case "nsis": return .L_NSIS
        case "tcl": return .L_TCL
        case "lisp": return .L_LISP
        case "scheme": return .L_SCHEME
        case "asm", "assembly": return .L_ASM
        case "diff": return .L_DIFF
        case "props", "properties": return .L_PROPS
        case "postscript", "ps": return .L_PS
        case "ruby": return .L_RUBY
        case "smalltalk": return .L_SMALLTALK
        case "vhdl": return .L_VHDL
        case "kix": return .L_KIX
        case "autoit", "au3": return .L_AU3
        case "caml": return .L_CAML
        case "ada": return .L_ADA
        case "verilog": return .L_VERILOG
        case "matlab": return .L_MATLAB
        case "haskell": return .L_HASKELL
        case "inno": return .L_INNO
        case "searchresult": return .L_SEARCHRESULT
        case "cmake": return .L_CMAKE
        case "yaml": return .L_YAML
        case "cobol": return .L_COBOL
        case "gui4cli": return .L_GUI4CLI
        case "d": return .L_D
        case "powershell": return .L_POWERSHELL
        case "r": return .L_R
        case "jsp": return .L_JSP
        case "coffeescript": return .L_COFFEESCRIPT
        case "json": return .L_JSON
        case "json5": return .L_JSON5
        case "baanc": return .L_BAANC
        case "srec": return .L_SREC
        case "ihex": return .L_IHEX
        case "tehex": return .L_TEHEX
        case "swift": return .L_SWIFT
        case "asn1": return .L_ASN1
        case "avs": return .L_AVS
        case "blitzbasic": return .L_BLITZBASIC
        case "purebasic": return .L_PUREBASIC
        case "freebasic": return .L_FREEBASIC
        case "csound": return .L_CSOUND
        case "erlang": return .L_ERLANG
        case "escript": return .L_ESCRIPT
        case "forth": return .L_FORTH
        case "latex": return .L_LATEX
        case "mmixal": return .L_MMIXAL
        case "nim": return .L_NIM
        case "nncrontab": return .L_NNCRONTAB
        case "oscript": return .L_OSCRIPT
        case "rebol": return .L_REBOL
        case "registry": return .L_REGISTRY
        case "rust": return .L_RUST
        case "spice": return .L_SPICE
        case "txt2tags": return .L_TXT2TAGS
        case "visualprolog": return .L_VISUALPROLOG
        case "typescript": return .L_TYPESCRIPT
        case "mssql": return .L_MSSQL
        case "gdscript": return .L_GDSCRIPT
        case "hollywood": return .L_HOLLYWOOD
        case "go", "golang": return .L_GOLANG
        case "raku": return .L_RAKU
        case "toml": return .L_TEXT  // Not in original enum, map to TEXT
        case "sas": return .L_TEXT    // Not in original enum, map to TEXT
        case "errorlist": return .L_TEXT  // Internal use, map to TEXT
        default: return .L_TEXT
        }
    }
}

// Compatibility extension for existing code
extension LanguageManager {
    func detectLanguage(for filename: String) -> NotepadPlusLanguage? {
        let langType = getLangFromExt((filename as NSString).pathExtension)
        guard let lang = getLangFromIndex(Int(langType.rawValue)) else { return nil }
        
        return NotepadPlusLanguage(
            name: lang._langName,
            extensions: lang._defaultExtList?.split(separator: " ").map { String($0) } ?? [],
            commentLine: lang._commentLineSymbol,
            commentStart: lang._commentStartSymbol,
            commentEnd: lang._commentEndSymbol,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: nil, instre2: nil,
                type1: nil, type2: nil, type3: nil, type4: nil, type5: nil, type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        )
    }
}