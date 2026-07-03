//
//  FoldingManager.swift
//  Notepad++
//
//  Service for detecting and managing code folding regions.
//
//  Fold detection follows the lexilla folder model: a SINGLE forward pass that maintains a
//  running fold level incrementally, never scanning ahead per header, and (for C-style
//  braces) counts a brace only when it is lexed as an operator, excluding braces inside
//  strings and comments. See lexilla/lexers/LexCPP.cxx LexerCPP::Fold (:1507), its
//  SCE_C_OPERATOR brace gate (:1593-1603) and per-line styler.SetLevelIfDifferent (:1616),
//  and scintilla-reference/src/Document.cxx Document::SetLevel (:603).
//

import Foundation

class FoldingManager {

    // F21: NSRegularExpressions are compiled ONCE (static let) instead of per detection
    // invocation on the hot path.
    private static let xmlOpeningTagRegex = try! NSRegularExpression(pattern: "<([a-zA-Z0-9\\-_]+)[^>]*>", options: [])
    private static let xmlClosingTagRegex = try! NSRegularExpression(pattern: "</([a-zA-Z0-9\\-_]+)>", options: [])
    private static let functionCallRegex = try! NSRegularExpression(pattern: "\\w+\\s*\\(", options: [])

    // F21: hashable key for O(1) exact-duplicate detection in cleanupRegions.
    private struct RegionKey: Hashable {
        let start: Int
        let end: Int
    }

    static func detectFoldingRegions(in text: String, language: LanguageDefinition?) -> [FoldingRegion] {
        guard let language = language else {
            return detectGenericFoldingRegions(in: text)
        }

        let lines = text.components(separatedBy: .newlines)
        var regions: [FoldingRegion] = []

        // Language-specific folding patterns
        switch language.name.lowercased() {
        case "swift":
            regions = detectSwiftFoldingRegions(lines: lines)
        case "c++", "c", "java", "javascript", "typescript", "c#", "go", "rust":
            regions = detectCStyleFoldingRegions(lines: lines)
        case "python":
            regions = detectPythonFoldingRegions(lines: lines)
        case "html", "xml":
            regions = detectXMLFoldingRegions(lines: lines)
        case "ruby":
            regions = detectRubyFoldingRegions(lines: lines)
        case "yaml":
            regions = detectIndentationBasedFolding(lines: lines, indentSize: 2)
        default:
            regions = detectGenericFoldingRegions(in: text)
        }

        // Add multiline comment folding
        regions.append(contentsOf: detectMultilineComments(lines: lines, language: language))

        // Sort by start line and remove overlapping regions
        regions = cleanupRegions(regions)

        return regions
    }

    private static func detectCStyleFoldingRegions(lines: [String]) -> [FoldingRegion] {
        // LITERAL TRANSLATION of lexilla LexerCPP::Fold (LexCPP.cxx:1507): a single forward
        // pass that maintains the brace level incrementally (levelNext++/-- at :1600-1602),
        // counting a brace ONLY when it is lexed as SCE_C_OPERATOR (:1593), which excludes
        // braces inside string literals, char literals, and comments. Notepad++/Scintilla
        // gets that style gate from the lexer; FoldingManager folds from RAW text, so we
        // approximate the SCE_C_OPERATOR gate with an inline string/comment state machine
        // (inString / inChar / line-comment / inBlockComment) and count braces only when in
        // none of those states (this is the F22 fix). Levels persist per open brace like
        // styler.SetLevelIfDifferent (:1616) / Document::SetLevel (Document.cxx:603).
        var regions: [FoldingRegion] = []
        var braceStack: [(line: Int, level: Int)] = []

        // inBlockComment persists ACROSS lines: a /* ... */ can span multiple lines, exactly
        // like LexCPP carries comment style across the newline (LexCPP.cxx:1537-1544, 1626).
        var inBlockComment = false

        for (index, line) in lines.enumerated() {
            // String / char / line-comment state is per line (a raw-text approximation: an
            // unterminated string is treated as ending at the line break).
            var inString = false
            var inChar = false
            let chars = Array(line)
            var i = 0
            while i < chars.count {
                let ch = chars[i]
                let next: Character? = i + 1 < chars.count ? chars[i + 1] : nil

                if inBlockComment {
                    if ch == "*" && next == "/" {
                        inBlockComment = false
                        i += 2
                        continue
                    }
                    i += 1
                    continue
                }
                if inString {
                    if ch == "\\" { i += 2; continue }   // escaped char
                    if ch == "\"" { inString = false }
                    i += 1
                    continue
                }
                if inChar {
                    if ch == "\\" { i += 2; continue }   // escaped char
                    if ch == "'" { inChar = false }
                    i += 1
                    continue
                }

                // Not inside any string/comment: detect openers first.
                if ch == "/" && next == "/" { break }    // rest of line is a line comment
                if ch == "/" && next == "*" {
                    inBlockComment = true
                    i += 2
                    continue
                }
                if ch == "\"" { inString = true; i += 1; continue }
                if ch == "'" { inChar = true; i += 1; continue }

                // SCE_C_OPERATOR brace gate (LexCPP.cxx:1593-1603): count real braces only.
                if ch == "{" {
                    braceStack.append((line: index, level: braceStack.count))
                } else if ch == "}" && !braceStack.isEmpty {
                    let start = braceStack.removeLast()
                    if index > start.line {
                        let type = determineFoldingType(startLine: lines[start.line])
                        regions.append(FoldingRegion(
                            startLine: start.line,
                            endLine: index,
                            level: start.level,
                            type: type
                        ))
                    }
                }
                i += 1
            }
        }

        return regions
    }

    private static func detectSwiftFoldingRegions(lines: [String]) -> [FoldingRegion] {
        // F22: the previous closureStack loop built a stack from `line.contains(" in ")` that
        // was NEVER read (the function returned the unmodified C-style result), pure dead
        // per-keystroke work. Swift braces fold exactly like C-style braces, so delegate.
        return detectCStyleFoldingRegions(lines: lines)
    }

    private static func detectPythonFoldingRegions(lines: [String]) -> [FoldingRegion] {
        // F21: single forward pass with an indentation stack (headerLine, headerIndent, type)
        // instead of a forward scan to end-of-block for EVERY header (which was O(n^2) line
        // visits with a trimmed-String allocation each). Same incremental model as lexilla
        // LexerCPP::Fold (LexCPP.cxx:1507, levelNext at :1600) and the Ruby detector's
        // blockStack below; each line is visited once and the pop loop is amortized O(n).
        var regions: [FoldingRegion] = []
        var stack: [(headerLine: Int, headerIndent: Int, type: FoldingRegion.FoldingType)] = []
        var lastNonBlankLine = 0

        for (index, line) in lines.enumerated() {
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { continue }

            // Indentation returned to or above open headers -> close them, emitting
            // headerLine..lastNonBlankLine (level = remaining stack depth). Amortized O(n).
            while let top = stack.last, top.headerIndent >= indent {
                stack.removeLast()
                if lastNonBlankLine > top.headerLine {
                    regions.append(FoldingRegion(
                        startLine: top.headerLine,
                        endLine: lastNonBlankLine,
                        level: stack.count,
                        type: top.type
                    ))
                }
            }

            // Classify this line as a fold header, if any.
            var headerType: FoldingRegion.FoldingType? = nil
            if trimmed.hasPrefix("def ") || trimmed.hasPrefix("async def ") {
                headerType = .function
            } else if trimmed.hasPrefix("class ") {
                headerType = .classType
            } else if trimmed.hasPrefix("if ") || trimmed.hasPrefix("for ") ||
                      trimmed.hasPrefix("while ") || trimmed.hasPrefix("with ") ||
                      trimmed.hasPrefix("try:") || trimmed.hasPrefix("except") {
                headerType = .block
            }

            if let type = headerType {
                stack.append((headerLine: index, headerIndent: indent, type: type))
            }

            lastNonBlankLine = index
        }

        // Close all remaining open headers at end of document.
        while let top = stack.last {
            stack.removeLast()
            if lastNonBlankLine > top.headerLine {
                regions.append(FoldingRegion(
                    startLine: top.headerLine,
                    endLine: lastNonBlankLine,
                    level: stack.count,
                    type: top.type
                ))
            }
        }

        return regions
    }

    private static func detectXMLFoldingRegions(lines: [String]) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        var tagStack: [(tag: String, line: Int)] = []

        for (index, line) in lines.enumerated() {
            // F21: match against (line as NSString).length (UTF-16 units), NOT line.count
            // (grapheme count). For a line with characters that occupy more than one UTF-16
            // unit, line.count < utf16.length would truncate the range and silently miss
            // tags near the end of the line, producing wrong/unclosed fold regions.
            let nsRange = NSRange(location: 0, length: (line as NSString).length)

            // Find opening tags
            let openingMatches = Self.xmlOpeningTagRegex.matches(in: line, options: [], range: nsRange)
            for match in openingMatches {
                if let tagRange = Range(match.range(at: 1), in: line) {
                    let tag = String(line[tagRange])
                    if !line.contains("</\(tag)>") { // Not self-closing on same line
                        tagStack.append((tag: tag, line: index))
                    }
                }
            }

            // Find closing tags
            let closingMatches = Self.xmlClosingTagRegex.matches(in: line, options: [], range: nsRange)
            for match in closingMatches {
                if let tagRange = Range(match.range(at: 1), in: line) {
                    let tag = String(line[tagRange])
                    if let lastIndex = tagStack.lastIndex(where: { $0.tag == tag }) {
                        let start = tagStack[lastIndex]
                        if index > start.line {
                            regions.append(FoldingRegion(
                                startLine: start.line,
                                endLine: index,
                                level: lastIndex,
                                type: .block
                            ))
                        }
                        tagStack.remove(at: lastIndex)
                    }
                }
            }
        }

        return regions
    }

    private static func detectRubyFoldingRegions(lines: [String]) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        var blockStack: [(keyword: String, line: Int, indent: Int)] = []

        let startKeywords = ["def", "class", "module", "if", "unless", "while", "for", "begin", "do", "case"]
        let endKeyword = "end"

        for (index, line) in lines.enumerated() {
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for start keywords
            for keyword in startKeywords {
                if trimmed.hasPrefix("\(keyword) ") || trimmed == keyword {
                    blockStack.append((keyword: keyword, line: index, indent: indent))
                    break
                }
            }

            // Check for end keyword
            if trimmed == endKeyword || trimmed.hasPrefix("end ") {
                if let last = blockStack.last {
                    if index > last.line {
                        let type: FoldingRegion.FoldingType = {
                            switch last.keyword {
                            case "class": return .classType
                            case "def": return .function
                            case "module": return .block
                            default: return .block
                            }
                        }()

                        regions.append(FoldingRegion(
                            startLine: last.line,
                            endLine: index,
                            level: blockStack.count - 1,
                            type: type
                        ))
                    }
                    blockStack.removeLast()
                }
            }
        }

        return regions
    }

    private static func detectIndentationBasedFolding(lines: [String], indentSize: Int) -> [FoldingRegion] {
        // F21: single forward pass with an indent stack instead of a forward scan to
        // end-of-block per line (which was O(n^2)). Same incremental model as lexilla
        // LexerCPP::Fold (LexCPP.cxx:1507) and per-line Document::SetLevel (Document.cxx:603).
        // A pushed line becomes a real fold header only if a deeper-indented child line
        // followed it (endLine > startLine), so childless lines produce nothing.
        var regions: [FoldingRegion] = []
        var stack: [(startLine: Int, level: Int)] = []
        var lastNonBlankLine = 0

        for (index, line) in lines.enumerated() {
            let spaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let level = spaces / indentSize
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { continue }

            // Indentation returned to or above a candidate -> its block is complete. Emit a
            // region only when a deeper-indented child was seen (lastNonBlank > start).
            while let top = stack.last, top.level >= level {
                stack.removeLast()
                if lastNonBlankLine > top.startLine {
                    regions.append(FoldingRegion(
                        startLine: top.startLine,
                        endLine: lastNonBlankLine,
                        level: top.level,
                        type: .block
                    ))
                }
            }

            stack.append((startLine: index, level: level))
            lastNonBlankLine = index
        }

        // Close remaining candidates at end of document.
        while let top = stack.last {
            stack.removeLast()
            if lastNonBlankLine > top.startLine {
                regions.append(FoldingRegion(
                    startLine: top.startLine,
                    endLine: lastNonBlankLine,
                    level: top.level,
                    type: .block
                ))
            }
        }

        return regions
    }

    private static func detectMultilineComments(lines: [String], language: LanguageDefinition?) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []

        // C-style comments /* */
        if let _ = language?.name.lowercased(),
           ["c", "c++", "java", "javascript", "swift", "go", "rust", "c#", "typescript"].contains(language?.name.lowercased()) {

            var inComment = false
            var startLine = 0

            for (index, line) in lines.enumerated() {
                if !inComment && line.contains("/*") {
                    inComment = true
                    startLine = index
                }

                if inComment && line.contains("*/") {
                    if index > startLine {
                        regions.append(FoldingRegion(
                            startLine: startLine,
                            endLine: index,
                            level: 0,
                            type: .comment
                        ))
                    }
                    inComment = false
                }
            }
        }

        // Python docstrings
        if language?.name.lowercased() == "python" {
            var inDocstring = false
            var startLine = 0
            var delimiter = ""

            for (index, line) in lines.enumerated() {
                if !inDocstring && (line.contains("\"\"\"") || line.contains("'''")) {
                    delimiter = line.contains("\"\"\"") ? "\"\"\"" : "'''"
                    inDocstring = true
                    startLine = index

                    // Check if it closes on the same line
                    let components = line.components(separatedBy: delimiter)
                    if components.count > 2 {
                        inDocstring = false
                    }
                } else if inDocstring && line.contains(delimiter) {
                    if index > startLine {
                        regions.append(FoldingRegion(
                            startLine: startLine,
                            endLine: index,
                            level: 0,
                            type: .comment
                        ))
                    }
                    inDocstring = false
                }
            }
        }

        return regions
    }

    private static func detectGenericFoldingRegions(in text: String) -> [FoldingRegion] {
        let lines = text.components(separatedBy: .newlines)
        return detectCStyleFoldingRegions(lines: lines)
    }

    private static func determineFoldingType(startLine: String) -> FoldingRegion.FoldingType {
        let trimmed = startLine.trimmingCharacters(in: .whitespaces)

        if trimmed.contains("class ") || trimmed.contains("struct ") || trimmed.contains("interface ") {
            return .classType
        } else if trimmed.contains("func ") || trimmed.contains("function ") ||
                  trimmed.contains("def ") || trimmed.contains("void ") ||
                  // F21: test with the pre-compiled static regex instead of compiling
                  // "\\w+\\s*\\(" on every closing brace.
                  functionCallRegex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: (trimmed as NSString).length)) != nil {
            return .function
        } else if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("#") {
            return .comment
        } else if trimmed.contains("[") || trimmed.contains("= [") {
            return .array
        } else if trimmed.contains("{") || trimmed.contains("= {") {
            return .object
        } else {
            return .block
        }
    }

    private static func cleanupRegions(_ regions: [FoldingRegion]) -> [FoldingRegion] {
        // F21: O(r log r) sort + O(r) dedup via a Set, instead of the previous O(r^2)
        // `cleaned.contains { ... }` scan of all kept regions per region. Same result: drop
        // exact (start,end) duplicates and zero-length regions.
        let sorted = regions.sorted { $0.startLine < $1.startLine }
        var cleaned: [FoldingRegion] = []
        var seen = Set<RegionKey>()

        for region in sorted {
            guard region.endLine > region.startLine else { continue }
            let key = RegionKey(start: region.startLine, end: region.endLine)
            if seen.contains(key) { continue }
            seen.insert(key)
            cleaned.append(region)
        }

        return cleaned
    }
}
