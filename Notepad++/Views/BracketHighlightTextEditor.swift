//
//  BracketHighlightTextEditor.swift
//  Notepad++
//
//  Text editor with bracket matching and highlighting
//

import SwiftUI
import AppKit

struct BracketHighlightTextEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let language: LanguageDefinition?
    let syntaxHighlightingEnabled: Bool
    let onTextChange: ((String) -> Void)?
    
    private let bracketMatcher = BracketMatcher.shared
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // Create text view with proper setup
        let textView = NSTextView()
        
        // Essential properties for text to be visible and editable
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true  // Enable rich text for syntax highlighting
        textView.importsGraphics = false
        textView.allowsUndo = true
        
        // Text appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor,
            .foregroundColor: NSColor.selectedTextColor
        ]
        
        // Disable auto substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        
        // Set initial text
        textView.string = text
        
        // Configure text container for proper layout
        if let textContainer = textView.textContainer {
            textContainer.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // Configure layout manager
        textView.minSize = CGSize(width: 0, height: 0)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Set delegate
        textView.delegate = context.coordinator
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        
        context.coordinator.textView = textView
        
        // Apply initial syntax highlighting if enabled
        if syntaxHighlightingEnabled, let language = language {
            context.coordinator.applySyntaxHighlighting(textView: textView, language: language)
        }
        
        context.coordinator.updateBracketHighlighting()
        
        // Set up notification observer for bracket navigation
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.jumpToMatchingBracket(_:)),
            name: .jumpToMatchingBracket,
            object: nil
        )
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        
        // Update font if size changed
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Only update text if it's different AND we're not typing AND the new text is actually newer
        if !context.coordinator.isUserTyping && textView.string != text {
            // CRITICAL: Don't replace text with older content
            if textView.string.count > text.count && text.count == 29 {
                // Force the binding to update with the current text
                DispatchQueue.main.async {
                    self.text = textView.string
                }
                return
            }
            
            context.coordinator.isUpdating = true
            
            // Save selection and scroll position
            let savedSelection = textView.selectedRange()
            let visibleRect = textView.visibleRect
            
            textView.string = text
            
            // Restore selection and scroll position
            if savedSelection.location <= text.count {
                textView.setSelectedRange(savedSelection)
            }
            textView.scrollToVisible(visibleRect)
            
            // Apply syntax highlighting after text update
            if syntaxHighlightingEnabled, let language = language {
                context.coordinator.applySyntaxHighlighting(textView: textView, language: language)
            }
            
            context.coordinator.updateBracketHighlighting()
            context.coordinator.isUpdating = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: BracketHighlightTextEditor
        weak var textView: NSTextView?
        var currentMatchingBracket: NSRange?
        var isUpdating = false
        var isUserTyping = false
        
        init(_ parent: BracketHighlightTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Prevent recursive updates
            if isUpdating { 
                return 
            }
            
            // Mark that we're typing and shouldn't accept external updates
            isUserTyping = true
            
            // Update through the binding
            let newText = textView.string
            
            // IMPORTANT: Update the binding synchronously
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.text = newText
                
                // Call the optional onTextChange if provided
                self.parent.onTextChange?(newText)
            }
            
            updateBracketHighlighting()
            
            // Keep the typing flag active longer to prevent race conditions
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isUserTyping = false
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            updateBracketHighlighting()
        }
        
        func updateBracketHighlighting() {
            guard let textView = textView else { return }
            let text = textView.string
            let selectedRange = textView.selectedRange()
            
            // Remove previous bracket highlighting
            if let previousMatch = currentMatchingBracket {
                textView.textStorage?.removeAttribute(.backgroundColor,
                                                     range: previousMatch)
            }
            
            // Clear all bracket highlighting first
            textView.textStorage?.removeAttribute(.backgroundColor,
                                                 range: NSRange(location: 0, length: text.count))
            
            // Apply syntax highlighting if enabled
            if parent.syntaxHighlightingEnabled, let language = parent.language {
                applySyntaxHighlighting(textView: textView, language: language)
            }
            
            // Find and highlight matching bracket
            if selectedRange.length == 0 {
                let cursorPos = selectedRange.location
                
                // Check character at cursor position
                if cursorPos > 0 && cursorPos <= text.count {
                    // Check character before cursor
                    if let matchingPos = parent.bracketMatcher.findMatchingBracket(in: text, at: cursorPos - 1) {
                        highlightBracketPair(at: cursorPos - 1, and: matchingPos, in: textView)
                    }
                    // Check character at cursor
                    else if cursorPos < text.count,
                            let matchingPos = parent.bracketMatcher.findMatchingBracket(in: text, at: cursorPos) {
                        highlightBracketPair(at: cursorPos, and: matchingPos, in: textView)
                    }
                }
            }
            
            // Highlight unmatched brackets in red
            let unmatchedBrackets = parent.bracketMatcher.findUnmatchedBrackets(in: text)
            for position in unmatchedBrackets {
                if position < text.count {
                    textView.textStorage?.addAttribute(.backgroundColor,
                                                      value: NSColor.systemRed.withAlphaComponent(0.3),
                                                      range: NSRange(location: position, length: 1))
                }
            }
        }
        
        private func highlightBracketPair(at pos1: Int, and pos2: Int, in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            
            let highlightColor = NSColor.systemYellow.withAlphaComponent(0.5)
            
            // Highlight both brackets
            if pos1 < textStorage.length {
                textStorage.addAttribute(.backgroundColor,
                                        value: highlightColor,
                                        range: NSRange(location: pos1, length: 1))
            }
            
            if pos2 < textStorage.length {
                textStorage.addAttribute(.backgroundColor,
                                        value: highlightColor,
                                        range: NSRange(location: pos2, length: 1))
                currentMatchingBracket = NSRange(location: pos2, length: 1)
            }
        }
        
        func applySyntaxHighlighting(textView: NSTextView, language: LanguageDefinition) {
            guard let textStorage = textView.textStorage else { return }
            let text = textView.string
            
            // Reset to default color
            textStorage.addAttribute(.foregroundColor,
                                    value: NSColor.labelColor,
                                    range: NSRange(location: 0, length: text.count))
            
            // Apply keyword highlighting
            for keywordSet in language.keywords {
                let color = colorForKeywordType(keywordSet.name)
                
                for keyword in keywordSet.keywords {
                    let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
                    
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                        let matches = regex.matches(in: text,
                                                   range: NSRange(location: 0, length: text.count))
                        
                        for match in matches {
                            textStorage.addAttribute(.foregroundColor,
                                                    value: color,
                                                    range: match.range)
                        }
                    }
                }
            }
            
            // Highlight strings
            highlightStrings(in: textStorage, text: text)
            
            // Highlight comments
            if let commentLine = language.commentLine {
                highlightLineComments(in: textStorage, text: text, marker: commentLine)
            }
            
            if let commentStart = language.commentStart,
               let commentEnd = language.commentEnd {
                highlightBlockComments(in: textStorage, text: text,
                                     start: commentStart, end: commentEnd)
            }
        }
        
        private func colorForKeywordType(_ type: String) -> NSColor {
            switch type.lowercased() {
            case "keywords", "instruction", "instre1":
                return .systemPurple
            case "types", "type", "type1", "type2":
                return .systemBlue
            case "literals", "literal":
                return .systemOrange
            case "comments", "comment":
                return .systemGreen
            case "strings", "string":
                return .systemRed
            case "functions", "function":
                return .systemIndigo
            default:
                return .systemTeal
            }
        }
        
        private func highlightStrings(in textStorage: NSTextStorage, text: String) {
            let patterns = [
                "\"[^\"\\n]*\"", // Double-quoted strings
                "'[^'\\n]*'"     // Single-quoted strings
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let matches = regex.matches(in: text,
                                               range: NSRange(location: 0, length: text.count))
                    
                    for match in matches {
                        textStorage.addAttribute(.foregroundColor,
                                                value: NSColor.systemRed,
                                                range: match.range)
                    }
                }
            }
        }
        
        private func highlightLineComments(in textStorage: NSTextStorage, text: String, marker: String) {
            let escapedMarker = NSRegularExpression.escapedPattern(for: marker)
            let pattern = "\(escapedMarker).*$"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: text,
                                           range: NSRange(location: 0, length: text.count))
                
                for match in matches {
                    textStorage.addAttribute(.foregroundColor,
                                            value: NSColor.systemGreen,
                                            range: match.range)
                }
            }
        }
        
        private func highlightBlockComments(in textStorage: NSTextStorage, text: String,
                                           start: String, end: String) {
            let escapedStart = NSRegularExpression.escapedPattern(for: start)
            let escapedEnd = NSRegularExpression.escapedPattern(for: end)
            let pattern = "\(escapedStart)[\\s\\S]*?\(escapedEnd)"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text,
                                           range: NSRange(location: 0, length: text.count))
                
                for match in matches {
                    textStorage.addAttribute(.foregroundColor,
                                            value: NSColor.systemGreen,
                                            range: match.range)
                }
            }
        }
        
        // Handle bracket navigation (Cmd+M to jump to matching bracket)
        @objc func jumpToMatchingBracket(_ sender: Any?) {
            guard let textView = textView else { return }
            let text = textView.string
            let selectedRange = textView.selectedRange()
            
            if selectedRange.length == 0 {
                let cursorPos = selectedRange.location
                
                // Try character before cursor first
                if cursorPos > 0,
                   let matchingPos = parent.bracketMatcher.findMatchingBracket(in: text, at: cursorPos - 1) {
                    textView.setSelectedRange(NSRange(location: matchingPos + 1, length: 0))
                    textView.scrollRangeToVisible(NSRange(location: matchingPos, length: 1))
                }
                // Try character at cursor
                else if cursorPos < text.count,
                        let matchingPos = parent.bracketMatcher.findMatchingBracket(in: text, at: cursorPos) {
                    textView.setSelectedRange(NSRange(location: matchingPos, length: 0))
                    textView.scrollRangeToVisible(NSRange(location: matchingPos, length: 1))
                }
            }
        }
    }
}