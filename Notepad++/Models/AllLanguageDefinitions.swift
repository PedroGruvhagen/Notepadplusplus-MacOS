//
//  AllLanguageDefinitions.swift
//  Notepad++
//
//  Optimized version - loads language definitions on demand
//

import Foundation

// Lazy-loaded language definitions to prevent compilation hang
struct AllLanguages {
    // For now, just include essential languages to get the app working
    // The full 94 languages with thousands of keywords will be loaded from a resource file
    static let definitions: [NotepadPlusLanguage] = [
        // Swift
        NotepadPlusLanguage(
            name: "swift",
            extensions: ["swift"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "func", "var", "let", "class", "struct", "enum", "protocol", "extension", "import", "typealias", "associatedtype", "where", "guard", "defer", "repeat", "fallthrough", "throws", "throw", "try", "catch", "async", "await", "actor"]),
                instre2: nil,
                type1: Set(["Int", "Double", "Float", "String", "Bool", "Array", "Dictionary", "Set", "Optional", "Any", "AnyObject", "Void", "Self", "Protocol"]),
                type2: Set(["@available", "@objc", "@nonobjc", "@NSCopying", "@NSManaged", "@UIApplicationMain", "@NSApplicationMain", "@main", "@escaping", "@autoclosure", "@discardableResult", "@resultBuilder"]),
                type3: Set(["private", "fileprivate", "internal", "public", "open", "static", "final", "lazy", "weak", "unowned", "mutating", "nonmutating", "override", "required", "convenience"]),
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // JavaScript
        NotepadPlusLanguage(
            name: "javascript",
            extensions: ["js", "jsx", "mjs"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "function", "var", "let", "const", "class", "extends", "new", "this", "super", "import", "export", "async", "await", "try", "catch", "finally", "throw", "typeof", "instanceof", "in", "of", "delete", "void"]),
                instre2: nil,
                type1: Set(["Array", "Object", "String", "Number", "Boolean", "Function", "Promise", "Map", "Set", "WeakMap", "WeakSet", "Symbol", "Date", "RegExp", "Error", "JSON", "Math", "console", "window", "document", "undefined", "null", "NaN", "Infinity"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // Python
        NotepadPlusLanguage(
            name: "python",
            extensions: ["py", "pyw"],
            commentLine: "#",
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "elif", "else", "for", "while", "break", "continue", "return", "def", "class", "import", "from", "as", "try", "except", "finally", "raise", "with", "assert", "pass", "yield", "lambda", "global", "nonlocal", "del", "is", "in", "not", "and", "or", "True", "False", "None"]),
                instre2: nil,
                type1: Set(["int", "float", "str", "list", "dict", "tuple", "set", "bool", "bytes", "bytearray", "complex", "frozenset", "range", "type", "object", "property", "staticmethod", "classmethod", "super", "isinstance", "issubclass", "len", "print", "input", "open", "file"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // HTML
        NotepadPlusLanguage(
            name: "html",
            extensions: ["html", "htm", "xhtml"],
            commentLine: nil,
            commentStart: "<!--",
            commentEnd: "-->",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["html", "head", "body", "title", "div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th", "form", "input", "button", "select", "option", "textarea", "label", "header", "footer", "nav", "section", "article", "aside", "main"]),
                instre2: nil,
                type1: Set(["class", "id", "style", "href", "src", "alt", "width", "height", "type", "name", "value", "placeholder", "required", "disabled", "checked", "selected", "readonly", "multiple", "min", "max", "pattern", "title", "target", "rel", "method", "action"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // JSON
        NotepadPlusLanguage(
            name: "json",
            extensions: ["json"],
            commentLine: nil,
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["true", "false", "null"]),
                instre2: nil,
                type1: nil,
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // Plain text (default)
        NotepadPlusLanguage(
            name: "normal",
            extensions: ["txt"],
            commentLine: nil,
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: nil, instre2: nil,
                type1: nil, type2: nil, type3: nil, type4: nil, type5: nil, type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        )
    ]
}

// TODO: Load the full 94 languages from a resource file or database instead of compiling them all