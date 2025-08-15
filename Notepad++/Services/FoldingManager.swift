//
//  FoldingManager.swift
//  Notepad++
//
//  Service for detecting and managing code folding regions
//

import Foundation

class FoldingManager {
    
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
        var regions: [FoldingRegion] = []
        var braceStack: [(line: Int, level: Int)] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip single-line comments
            if trimmed.hasPrefix("//") { continue }
            
            // Count braces
            for char in line {
                if char == "{" {
                    let level = braceStack.count
                    braceStack.append((line: index, level: level))
                } else if char == "}" && !braceStack.isEmpty {
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
            }
        }
        
        return regions
    }
    
    private static func detectSwiftFoldingRegions(lines: [String]) -> [FoldingRegion] {
        let regions = detectCStyleFoldingRegions(lines: lines)
        
        // Add Swift-specific patterns (closures, guard statements, etc.)
        var closureStack: [(line: Int, level: Int)] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect closure starts
            if line.contains(" in ") && (line.contains("{") || lines.indices.contains(index + 1) && lines[index + 1].contains("{")) {
                closureStack.append((line: index, level: 0))
            }
            
            // Detect computed property patterns
            if trimmed.contains("var ") && line.contains("{") {
                // Already handled by brace detection
            }
        }
        
        return regions
    }
    
    private static func detectPythonFoldingRegions(lines: [String]) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        _ = [(line: Int, indent: Int, type: FoldingRegion.FoldingType)]() // Variable type for reference
        
        for (index, line) in lines.enumerated() {
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty { continue }
            
            // Detect function/class definitions
            if trimmed.hasPrefix("def ") || trimmed.hasPrefix("class ") || 
               trimmed.hasPrefix("async def ") {
                let type: FoldingRegion.FoldingType = trimmed.hasPrefix("class ") ? .classType : .function
                
                // Find the end of this block
                var endLine = index
                for futureIndex in (index + 1)..<lines.count {
                    let futureLine = lines[futureIndex]
                    let futureSpaces = futureLine.prefix(while: { $0 == " " || $0 == "\t" }).count
                    let futureTrimmed = futureLine.trimmingCharacters(in: .whitespaces)
                    
                    if !futureTrimmed.isEmpty && futureSpaces <= leadingSpaces {
                        break
                    }
                    if !futureTrimmed.isEmpty {
                        endLine = futureIndex
                    }
                }
                
                if endLine > index {
                    regions.append(FoldingRegion(
                        startLine: index,
                        endLine: endLine,
                        level: leadingSpaces / 4,
                        type: type
                    ))
                }
            }
            
            // Detect if/for/while blocks
            if trimmed.hasPrefix("if ") || trimmed.hasPrefix("for ") || 
               trimmed.hasPrefix("while ") || trimmed.hasPrefix("with ") ||
               trimmed.hasPrefix("try:") || trimmed.hasPrefix("except") {
                
                var endLine = index
                for futureIndex in (index + 1)..<lines.count {
                    let futureLine = lines[futureIndex]
                    let futureSpaces = futureLine.prefix(while: { $0 == " " || $0 == "\t" }).count
                    let futureTrimmed = futureLine.trimmingCharacters(in: .whitespaces)
                    
                    if !futureTrimmed.isEmpty && futureSpaces <= leadingSpaces {
                        break
                    }
                    if !futureTrimmed.isEmpty {
                        endLine = futureIndex
                    }
                }
                
                if endLine > index {
                    regions.append(FoldingRegion(
                        startLine: index,
                        endLine: endLine,
                        level: leadingSpaces / 4,
                        type: .block
                    ))
                }
            }
        }
        
        return regions
    }
    
    private static func detectXMLFoldingRegions(lines: [String]) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        var tagStack: [(tag: String, line: Int)] = []
        
        let openingTagRegex = try! NSRegularExpression(pattern: "<([a-zA-Z0-9\\-_]+)[^>]*>", options: [])
        let closingTagRegex = try! NSRegularExpression(pattern: "</([a-zA-Z0-9\\-_]+)>", options: [])
        
        for (index, line) in lines.enumerated() {
            // Find opening tags
            let openingMatches = openingTagRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
            for match in openingMatches {
                if let tagRange = Range(match.range(at: 1), in: line) {
                    let tag = String(line[tagRange])
                    if !line.contains("</\(tag)>") { // Not self-closing on same line
                        tagStack.append((tag: tag, line: index))
                    }
                }
            }
            
            // Find closing tags
            let closingMatches = closingTagRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
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
        var regions: [FoldingRegion] = []
        _ = [(line: Int, level: Int)]() // Variable type for reference
        
        for (index, line) in lines.enumerated() {
            let spaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let level = spaces / indentSize
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty { continue }
            
            // Check if next line is more indented
            if index < lines.count - 1 {
                let nextLine = lines[index + 1]
                let nextSpaces = nextLine.prefix(while: { $0 == " " || $0 == "\t" }).count
                let nextLevel = nextSpaces / indentSize
                
                if nextLevel > level {
                    // Find where this indent block ends
                    var endLine = index + 1
                    for futureIndex in (index + 2)..<lines.count {
                        let futureLine = lines[futureIndex]
                        let futureSpaces = futureLine.prefix(while: { $0 == " " || $0 == "\t" }).count
                        let futureLevel = futureSpaces / indentSize
                        let futureTrimmed = futureLine.trimmingCharacters(in: .whitespaces)
                        
                        if !futureTrimmed.isEmpty && futureLevel <= level {
                            break
                        }
                        if !futureTrimmed.isEmpty {
                            endLine = futureIndex
                        }
                    }
                    
                    regions.append(FoldingRegion(
                        startLine: index,
                        endLine: endLine,
                        level: level,
                        type: .block
                    ))
                }
            }
        }
        
        return regions
    }
    
    private static func detectMultilineComments(lines: [String], language: LanguageDefinition?) -> [FoldingRegion] {
        var regions: [FoldingRegion] = []
        _ = lines.joined(separator: "\n") // Variable type for reference
        
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
                  trimmed.range(of: "\\w+\\s*\\(", options: .regularExpression) != nil {
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
        let sorted = regions.sorted { $0.startLine < $1.startLine }
        var cleaned: [FoldingRegion] = []
        
        for region in sorted {
            // Only add if it doesn't completely overlap with an existing region
            let overlapsCompletely = cleaned.contains { existing in
                existing.startLine == region.startLine && existing.endLine == region.endLine
            }
            
            if !overlapsCompletely && region.endLine > region.startLine {
                cleaned.append(region)
            }
        }
        
        return cleaned
    }
}