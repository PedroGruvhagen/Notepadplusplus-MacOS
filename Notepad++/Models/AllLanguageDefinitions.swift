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
        // C (from langs.model.xml line 127)
        NotepadPlusLanguage(
            name: "c",
            extensions: ["c", "h", "m"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "else", "switch", "case", "default", "break", "goto", "return", "for", "while", "do", "continue", "typedef", "sizeof", "NULL"]),
                instre2: nil,
                type1: Set(["void", "struct", "union", "enum", "char", "short", "int", "long", "double", "float", "signed", "unsigned", "const", "static", "extern", "auto", "register", "volatile"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // C++ (from langs.model.xml line 149)
        NotepadPlusLanguage(
            name: "cpp",
            extensions: ["cpp", "cxx", "cc", "h", "hh", "hpp", "hxx", "ino"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "else", "switch", "case", "default", "break", "goto", "return", "for", "while", "do", "continue", "typedef", "sizeof", "nullptr", "new", "delete", "throw", "try", "catch", "namespace", "using", "class", "struct", "enum", "union", "public", "private", "protected", "friend", "virtual", "override", "final", "explicit", "export", "template", "typename"]),
                instre2: nil,
                type1: Set(["void", "bool", "char", "wchar_t", "short", "int", "long", "float", "double", "signed", "unsigned", "const", "static", "extern", "auto", "register", "volatile", "mutable", "inline", "constexpr"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
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
        
        // JavaScript (from langs.model.xml line 297)
        NotepadPlusLanguage(
            name: "javascript",
            extensions: ["js", "jsm", "jsx", "mjs"],
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
        
        // Python (from langs.model.xml line 458)
        NotepadPlusLanguage(
            name: "python",
            extensions: ["py", "pyw", "pyx", "pxd", "pxi", "pyi"],
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
        
        // HTML (from langs.model.xml line 263)
        NotepadPlusLanguage(
            name: "html",
            extensions: ["html", "htm", "shtml", "shtm", "xhtml", "xht", "hta"],
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
        
        // CSS (from langs.model.xml line 156)
        NotepadPlusLanguage(
            name: "css",
            extensions: ["css"],
            commentLine: nil,
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["color", "background", "font", "margin", "padding", "border", "display", "position", "width", "height", "top", "left", "right", "bottom", "float", "clear", "text-align", "vertical-align", "line-height", "z-index", "overflow", "visibility", "opacity"]),
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
        
        // XML (from langs.model.xml line 519)
        NotepadPlusLanguage(
            name: "xml",
            extensions: ["xml", "xsl", "xslt", "xsd", "xul", "kml", "svg", "mxml", "xsml", "wsdl", "xlf", "xliff", "xbl", "sxbl", "sitemap", "gml", "gpx", "plist", "vcxproj", "csproj", "props", "targets"],
            commentLine: nil,
            commentStart: "<!--",
            commentEnd: "-->",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: nil,
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
        
        // Java (from langs.model.xml line 280)
        NotepadPlusLanguage(
            name: "java",
            extensions: ["java"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["abstract", "assert", "break", "case", "catch", "class", "const", "continue", "default", "do", "else", "enum", "extends", "final", "finally", "for", "goto", "if", "implements", "import", "instanceof", "interface", "native", "new", "package", "private", "protected", "public", "return", "static", "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "try", "volatile", "while"]),
                instre2: nil,
                type1: Set(["void", "boolean", "char", "byte", "short", "int", "long", "float", "double", "String", "Integer", "Boolean", "Character", "Byte", "Short", "Long", "Float", "Double"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // TypeScript (from langs.model.xml line 495)
        NotepadPlusLanguage(
            name: "typescript",
            extensions: ["ts", "tsx"],
            commentLine: "//",
            commentStart: "/*",
            commentEnd: "*/",
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "function", "var", "let", "const", "class", "interface", "type", "enum", "extends", "implements", "new", "this", "super", "import", "export", "async", "await", "try", "catch", "finally", "throw", "typeof", "instanceof", "in", "of", "delete", "void", "namespace", "module", "declare", "abstract", "as", "from", "get", "set", "readonly", "static", "public", "private", "protected"]),
                instre2: nil,
                type1: Set(["string", "number", "boolean", "any", "unknown", "never", "void", "null", "undefined", "object", "symbol", "bigint", "Array", "Object", "Function", "Promise", "Map", "Set", "WeakMap", "WeakSet", "Date", "RegExp", "Error"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // Shell/Bash (from langs.model.xml line 119)
        NotepadPlusLanguage(
            name: "bash",
            extensions: ["sh", "bash", "zsh", "fish"],
            commentLine: "#",
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "function", "return", "break", "continue", "exit", "export", "source", "alias", "unalias", "set", "unset", "local", "readonly", "declare", "typeset", "shift", "getopts"]),
                instre2: nil,
                type1: Set(["echo", "printf", "read", "cd", "pwd", "ls", "cp", "mv", "rm", "mkdir", "rmdir", "touch", "cat", "grep", "sed", "awk", "find", "sort", "uniq", "cut", "paste", "tr", "head", "tail", "less", "more"]),
                type2: nil,
                type3: nil,
                type4: nil,
                type5: nil,
                type6: nil,
                substyle1: nil, substyle2: nil, substyle3: nil, substyle4: nil,
                substyle5: nil, substyle6: nil, substyle7: nil, substyle8: nil
            )
        ),
        
        // Makefile (from langs.model.xml line 336)
        NotepadPlusLanguage(
            name: "makefile",
            extensions: ["mak", "mk", "makefile", "gnumakefile"],
            commentLine: "#",
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: Set(["all", "clean", "install", "uninstall", "depend", "distclean", "check", "test"]),
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
        
        // Markdown (from langs.model.xml line 339)
        NotepadPlusLanguage(
            name: "markdown",
            extensions: ["md", "markdown", "mdown", "mkdn", "mkd", "mdwn", "mdtxt", "mdtext"],
            commentLine: nil,
            commentStart: nil,
            commentEnd: nil,
            keywords: NotepadPlusLanguage.LanguageKeywords(
                instre1: nil,
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