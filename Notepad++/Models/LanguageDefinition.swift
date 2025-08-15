//
//  LanguageDefinition.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI

// MARK: - Language Definition Model
struct LanguageDefinition: Identifiable, Codable {
    let id = UUID()
    let name: String
    let displayName: String
    let extensions: [String]
    let commentLine: String?
    let commentStart: String?
    let commentEnd: String?
    let keywords: [KeywordSet]
    
    enum CodingKeys: String, CodingKey {
        case name, displayName, extensions, commentLine, commentStart, commentEnd, keywords
    }
}

struct KeywordSet: Codable {
    let name: String
    let keywords: [String]
    let style: SyntaxStyle
}

struct SyntaxStyle: Codable {
    let color: String
    let backgroundColor: String?
    let bold: Bool
    let italic: Bool
    let underline: Bool
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .primary
    }
    
    var swiftUIBackgroundColor: Color? {
        guard let backgroundColor = backgroundColor else { return nil }
        return Color(hex: backgroundColor)
    }
}

// MARK: - Old Language Manager (deprecated - use Services/LanguageManager instead)
class OldLanguageManager: ObservableObject {
    static let shared = OldLanguageManager()
    
    @Published var languages: [LanguageDefinition] = []
    
    init() {
        loadBuiltInLanguages()
    }
    
    private func loadBuiltInLanguages() {
        // Start with a few core languages, we'll expand this from Notepad++ XML
        languages = [
            createSwiftLanguage(),
            createPythonLanguage(),
            createJavaScriptLanguage(),
            createHTMLLanguage(),
            createCSSLanguage(),
            createJSONLanguage(),
            createMarkdownLanguage(),
            createCPlusPlusLanguage(),
            createJavaLanguage(),
            createGoLanguage()
        ]
    }
    
    func detectLanguage(for filePath: URL) -> LanguageDefinition? {
        let fileExtension = filePath.pathExtension.lowercased()
        return languages.first { language in
            language.extensions.contains(fileExtension)
        }
    }
    
    // MARK: - Language Definitions (Based on Notepad++ keywords)
    
    private func createSwiftLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "swift",
            displayName: "Swift",
            extensions: ["swift"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["class", "struct", "enum", "protocol", "extension", "func", "var", "let", "if", "else", "for", "while", "switch", "case", "default", "break", "continue", "return", "import", "public", "private", "internal", "fileprivate", "open", "static", "final", "lazy", "weak", "unowned", "guard", "defer", "init", "deinit", "self", "super", "nil", "true", "false", "try", "catch", "throw", "throws", "async", "await", "actor"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Types",
                    keywords: ["Int", "Double", "Float", "Bool", "String", "Character", "Array", "Dictionary", "Set", "Optional", "Any", "AnyObject", "Void", "Never", "Result", "Error"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Attributes",
                    keywords: ["@objc", "@IBOutlet", "@IBAction", "@IBDesignable", "@IBInspectable", "@available", "@escaping", "@autoclosure", "@discardableResult", "@main", "@UIApplicationMain", "@NSApplicationMain", "@propertyWrapper", "@resultBuilder", "@MainActor", "@Published", "@State", "@Binding", "@ObservedObject", "@StateObject", "@EnvironmentObject", "@Environment"],
                    style: SyntaxStyle(color: "FF8000", backgroundColor: nil, bold: false, italic: true, underline: false)
                )
            ]
        )
    }
    
    private func createPythonLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "python",
            displayName: "Python",
            extensions: ["py", "pyw", "pyc", "pyo", "pyd"],
            commentLine: "#",
            commentStart: "'''",
            commentEnd: "'''",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try", "while", "with", "yield"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Built-in Functions",
                    keywords: ["abs", "all", "any", "ascii", "bin", "bool", "breakpoint", "bytearray", "bytes", "callable", "chr", "classmethod", "compile", "complex", "delattr", "dict", "dir", "divmod", "enumerate", "eval", "exec", "filter", "float", "format", "frozenset", "getattr", "globals", "hasattr", "hash", "help", "hex", "id", "input", "int", "isinstance", "issubclass", "iter", "len", "list", "locals", "map", "max", "memoryview", "min", "next", "object", "oct", "open", "ord", "pow", "print", "property", "range", "repr", "reversed", "round", "set", "setattr", "slice", "sorted", "staticmethod", "str", "sum", "super", "tuple", "type", "vars", "zip"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createJavaScriptLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "javascript",
            displayName: "JavaScript",
            extensions: ["js", "jsx", "mjs", "cjs"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["async", "await", "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do", "else", "export", "extends", "finally", "for", "function", "if", "import", "in", "instanceof", "let", "new", "return", "super", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with", "yield", "of", "static", "get", "set"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Literals",
                    keywords: ["true", "false", "null", "undefined", "NaN", "Infinity"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createHTMLLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "html",
            displayName: "HTML",
            extensions: ["html", "htm", "xhtml", "xml"],
            commentLine: nil,
            commentStart: "<!--",
            commentEnd: "-->",
            keywords: [
                KeywordSet(
                    name: "Tags",
                    keywords: ["html", "head", "title", "body", "div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th", "form", "input", "button", "select", "option", "textarea", "label", "header", "footer", "nav", "main", "section", "article", "aside", "h1", "h2", "h3", "h4", "h5", "h6", "br", "hr", "meta", "link", "script", "style"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Attributes",
                    keywords: ["id", "class", "style", "src", "href", "alt", "title", "type", "name", "value", "placeholder", "required", "disabled", "checked", "selected", "readonly", "multiple", "accept", "autocomplete", "autofocus", "contenteditable", "data-", "role", "aria-", "tabindex"],
                    style: SyntaxStyle(color: "FF8000", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createCSSLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "css",
            displayName: "CSS",
            extensions: ["css", "scss", "sass", "less"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Properties",
                    keywords: ["color", "background", "background-color", "background-image", "border", "margin", "padding", "width", "height", "display", "position", "top", "left", "right", "bottom", "font", "font-size", "font-family", "font-weight", "text-align", "line-height", "flex", "grid", "justify-content", "align-items", "z-index", "overflow", "opacity", "transform", "transition", "animation"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Values",
                    keywords: ["auto", "none", "block", "inline", "inline-block", "flex", "grid", "absolute", "relative", "fixed", "static", "inherit", "initial", "unset", "center", "left", "right", "top", "bottom", "bold", "normal", "italic", "underline", "solid", "dashed", "dotted", "hidden", "visible", "scroll", "pointer", "default"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createJSONLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "json",
            displayName: "JSON",
            extensions: ["json", "jsonc", "json5"],
            commentLine: "//",
            commentStart: nil,
            commentEnd: nil,
            keywords: [
                KeywordSet(
                    name: "Values",
                    keywords: ["true", "false", "null"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createMarkdownLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "markdown",
            displayName: "Markdown",
            extensions: ["md", "markdown", "mdown", "mkd", "mdwn", "mdtxt", "mdtext"],
            commentLine: nil,
            commentStart: "<!--",
            commentEnd: "-->",
            keywords: []
        )
    }
    
    private func createCPlusPlusLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "cpp",
            displayName: "C++",
            extensions: ["cpp", "cxx", "cc", "c++", "hpp", "hxx", "h++", "h", "c"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", "case", "catch", "char", "char16_t", "char32_t", "class", "compl", "const", "constexpr", "const_cast", "continue", "decltype", "default", "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator", "or", "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local", "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "STL",
                    keywords: ["std", "string", "vector", "map", "set", "list", "deque", "queue", "stack", "pair", "iterator", "algorithm", "iostream", "fstream", "sstream", "iomanip", "memory", "unique_ptr", "shared_ptr", "weak_ptr"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createJavaLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "java",
            displayName: "Java",
            extensions: ["java"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const", "continue", "default", "do", "double", "else", "enum", "extends", "final", "finally", "float", "for", "goto", "if", "implements", "import", "instanceof", "int", "interface", "long", "native", "new", "package", "private", "protected", "public", "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "try", "var", "void", "volatile", "while"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Literals",
                    keywords: ["true", "false", "null"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
    
    private func createGoLanguage() -> LanguageDefinition {
        LanguageDefinition(
            name: "go",
            displayName: "Go",
            extensions: ["go"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: [
                KeywordSet(
                    name: "Keywords",
                    keywords: ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for", "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select", "struct", "switch", "type", "var"],
                    style: SyntaxStyle(color: "0000FF", backgroundColor: nil, bold: true, italic: false, underline: false)
                ),
                KeywordSet(
                    name: "Built-in",
                    keywords: ["append", "cap", "close", "complex", "copy", "delete", "imag", "len", "make", "new", "panic", "print", "println", "real", "recover", "bool", "byte", "complex64", "complex128", "error", "float32", "float64", "int", "int8", "int16", "int32", "int64", "rune", "string", "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "true", "false", "iota", "nil"],
                    style: SyntaxStyle(color: "8000FF", backgroundColor: nil, bold: false, italic: false, underline: false)
                )
            ]
        )
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}