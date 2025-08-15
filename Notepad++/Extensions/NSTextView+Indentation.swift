//
//  NSTextView+Indentation.swift
//  Notepad++
//
//  Extension to handle indentation settings for NSTextView
//

import AppKit

extension NSTextView {
    
    func configureIndentationSettings(tabSize: Int, replaceTabsBySpaces: Bool, maintainIndent: Bool, autoIndent: Bool, smartIndent: Bool) {
        // Store settings in the text view
        self.setValue(tabSize, forKey: "tabSize")
        self.setValue(replaceTabsBySpaces, forKey: "replaceTabsBySpaces")
        self.setValue(maintainIndent, forKey: "maintainIndent")
        self.setValue(autoIndent, forKey: "autoIndent")
        self.setValue(smartIndent, forKey: "smartIndent")
    }
    
    override open func insertTab(_ sender: Any?) {
        let settings = AppSettings.shared
        
        if settings.replaceTabsBySpaces {
            // Insert spaces instead of tab
            let spaces = String(repeating: " ", count: settings.tabSize)
            self.insertText(spaces, replacementRange: self.selectedRange())
        } else {
            super.insertTab(sender)
        }
    }
    
    override open func insertNewline(_ sender: Any?) {
        let settings = AppSettings.shared
        
        if !settings.maintainIndent && !settings.autoIndent {
            super.insertNewline(sender)
            return
        }
        
        // Get current line indentation
        let text = self.string as NSString
        let selectedRange = self.selectedRange()
        
        // Find the start of the current line
        var lineStart = 0
        var lineEnd = 0
        text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil,
                         for: NSRange(location: selectedRange.location, length: 0))
        
        // Extract current line
        let currentLine = text.substring(with: NSRange(location: lineStart, length: selectedRange.location - lineStart))
        
        // Calculate indentation
        var indentation = ""
        for char in currentLine {
            if char == " " || char == "\t" {
                indentation.append(char)
            } else {
                break
            }
        }
        
        // Smart indent: Check if we should increase indentation
        if settings.smartIndent {
            let trimmedLine = currentLine.trimmingCharacters(in: .whitespaces)
            
            // Check for common patterns that should increase indentation
            let increasePatterns = [
                ":", // Python, Ruby
                "{", // C-like languages
                "then", // Shell, Ruby
                "do", // Shell, Ruby
                "begin", // Ruby, Pascal
                "class", // Most OOP languages
                "def", // Python, Ruby
                "function", // JavaScript, Lua
                "if", // Most languages (when ending with :)
                "for", // Most languages (when ending with :)
                "while", // Most languages (when ending with :)
                "switch", // C-like languages
                "case" // C-like languages
            ]
            
            var shouldIncreaseIndent = false
            for pattern in increasePatterns {
                if trimmedLine.hasPrefix(pattern) || trimmedLine.hasSuffix(pattern) {
                    shouldIncreaseIndent = true
                    break
                }
            }
            
            if shouldIncreaseIndent {
                if settings.replaceTabsBySpaces {
                    indentation += String(repeating: " ", count: settings.tabSize)
                } else {
                    indentation += "\t"
                }
            }
        }
        
        // Insert newline and indentation
        super.insertNewline(sender)
        if !indentation.isEmpty {
            self.insertText(indentation, replacementRange: self.selectedRange())
        }
    }
    
    func increaseIndentation() {
        let settings = AppSettings.shared
        let selectedRange = self.selectedRange()
        let text = self.string as NSString
        
        // Get line range for selection
        let lineRange = text.lineRange(for: selectedRange)
        let lines = text.substring(with: lineRange)
        
        // Add indentation to each line
        let indentString = settings.replaceTabsBySpaces ? 
            String(repeating: " ", count: settings.tabSize) : "\t"
        
        let indentedLines = lines.components(separatedBy: "\n").map { line in
            if !line.isEmpty {
                return indentString + line
            }
            return line
        }.joined(separator: "\n")
        
        // Replace the text
        if self.shouldChangeText(in: lineRange, replacementString: indentedLines) {
            self.replaceCharacters(in: lineRange, with: indentedLines)
            self.didChangeText()
        }
    }
    
    func decreaseIndentation() {
        let settings = AppSettings.shared
        let selectedRange = self.selectedRange()
        let text = self.string as NSString
        
        // Get line range for selection
        let lineRange = text.lineRange(for: selectedRange)
        let lines = text.substring(with: lineRange)
        
        // Remove indentation from each line
        let unindentedLines = lines.components(separatedBy: "\n").map { line in
            if settings.replaceTabsBySpaces {
                // Remove up to tabSize spaces
                var spacesToRemove = 0
                for char in line.prefix(settings.tabSize) {
                    if char == " " {
                        spacesToRemove += 1
                    } else {
                        break
                    }
                }
                return String(line.dropFirst(spacesToRemove))
            } else {
                // Remove one tab or up to tabSize spaces
                if line.hasPrefix("\t") {
                    return String(line.dropFirst(1))
                } else {
                    var spacesToRemove = 0
                    for char in line.prefix(settings.tabSize) {
                        if char == " " {
                            spacesToRemove += 1
                        } else {
                            break
                        }
                    }
                    return String(line.dropFirst(spacesToRemove))
                }
            }
        }.joined(separator: "\n")
        
        // Replace the text
        if self.shouldChangeText(in: lineRange, replacementString: unindentedLines) {
            self.replaceCharacters(in: lineRange, with: unindentedLines)
            self.didChangeText()
        }
    }
}