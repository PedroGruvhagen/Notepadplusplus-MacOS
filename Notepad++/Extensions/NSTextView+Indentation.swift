//
//  NSTextView+Indentation.swift
//  Notepad++
//
//  Extension to handle indentation settings for NSTextView
//

import AppKit

extension NSTextView {
    
    func configureIndentationSettings(tabSize: Int, replaceTabsBySpaces: Bool, maintainIndent: Bool, autoIndent: Bool, smartIndent: Bool) {
        // NSTextView doesn't support setValue:forKey: for custom properties
        // These settings are handled directly by AppSettings.shared when needed
    }
    
    // REMOVED ALL OVERRIDES - Let NSTextView handle everything normally
    // NO custom Tab handling, NO custom Enter handling, NOTHING
    
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