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
    var fontName: String = "Menlo"
    var wordWrap: Bool = false
    var showWhitespace: Bool = false
    var showEndOfLine: Bool = false
    var highlightCurrentLine: Bool = true
    var currentLineColor: String = "#F0F0F0"
    var showIndentGuides: Bool = true
    var caretWidth: CGFloat = 1.0
    var scrollBeyondLastLine: Bool = false
    var tabSize: Int = 4
    var replaceTabsBySpaces: Bool = false
    var maintainIndent: Bool = true
    var autoIndent: Bool = true
    var smartIndent: Bool = false
    let language: LanguageDefinition?
    let syntaxHighlightingEnabled: Bool
    let onTextChange: ((String) -> Void)?
    
    // REMOVED: Using translated Notepad++ braceMatch functions instead
    
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
        
        // Text appearance with theme support
        let theme = ThemeManager.shared.currentTheme
        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = theme.textColor
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.selectedTextAttributes = [
            .backgroundColor: theme.selectionColor,
            .foregroundColor: theme.textColor
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
        
        // Configure word wrap
        if let textContainer = textView.textContainer {
            if wordWrap {
                textContainer.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = true
                textView.isHorizontallyResizable = false
                textView.autoresizingMask = [.width]
            } else {
                textContainer.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = false
                textView.isHorizontallyResizable = true
                textView.autoresizingMask = []
            }
            textContainer.heightTracksTextView = false
        }
        
        // Configure caret width
        if let layoutManager = textView.layoutManager {
            layoutManager.showsInvisibleCharacters = showWhitespace || showEndOfLine
        }
        
        // Configure layout manager
        textView.minSize = CGSize(width: 0, height: 0)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        
        // Store additional settings in coordinator
        context.coordinator.highlightCurrentLine = highlightCurrentLine
        context.coordinator.currentLineColor = currentLineColor
        context.coordinator.showIndentGuides = showIndentGuides
        context.coordinator.scrollBeyondLastLine = scrollBeyondLastLine
        context.coordinator.tabSize = tabSize
        context.coordinator.replaceTabsBySpaces = replaceTabsBySpaces
        context.coordinator.maintainIndent = maintainIndent
        context.coordinator.autoIndent = autoIndent
        context.coordinator.smartIndent = smartIndent
        
        // Configure indentation settings
        textView.configureIndentationSettings(
            tabSize: tabSize,
            replaceTabsBySpaces: replaceTabsBySpaces,
            maintainIndent: maintainIndent,
            autoIndent: autoIndent,
            smartIndent: smartIndent
        )
        
        // Set delegate
        textView.delegate = context.coordinator
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        
        context.coordinator.textView = textView
        
        // Apply performance optimizations if needed
        if let document = context.coordinator.getDocument() {
            PerformanceManager.shared.optimizeTextView(textView, forLargeFile: document.isLargeFile)
        }
        
        // DISABLED - Auto-completion causes text duplication issues
        // DO NOT configure auto-completion
        
        // Apply initial syntax highlighting if enabled
        if syntaxHighlightingEnabled {
            if let language = language {
                print("DEBUG: Initial highlighting - Language detected: \(language.name)")
                context.coordinator.applySyntaxHighlighting(textView: textView, language: language)
            } else {
                print("DEBUG: Initial highlighting - NO LANGUAGE DETECTED!")
            }
        } else {
            print("DEBUG: Initial highlighting - Syntax highlighting disabled")
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
        
        
        // Update font if size or name changed
        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        
        // Update word wrap
        if let textContainer = textView.textContainer {
            if wordWrap {
                textContainer.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = true
                textView.isHorizontallyResizable = false
            } else {
                textContainer.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                textContainer.widthTracksTextView = false
                textView.isHorizontallyResizable = true
            }
        }
        
        // Update whitespace visibility
        if let layoutManager = textView.layoutManager {
            layoutManager.showsInvisibleCharacters = showWhitespace || showEndOfLine
        }
        
        // Update coordinator settings
        context.coordinator.highlightCurrentLine = highlightCurrentLine
        context.coordinator.currentLineColor = currentLineColor
        context.coordinator.showIndentGuides = showIndentGuides
        context.coordinator.scrollBeyondLastLine = scrollBeyondLastLine
        context.coordinator.tabSize = tabSize
        context.coordinator.replaceTabsBySpaces = replaceTabsBySpaces
        context.coordinator.maintainIndent = maintainIndent
        context.coordinator.autoIndent = autoIndent
        context.coordinator.smartIndent = smartIndent
        
        // Update indentation settings
        textView.configureIndentationSettings(
            tabSize: tabSize,
            replaceTabsBySpaces: replaceTabsBySpaces,
            maintainIndent: maintainIndent,
            autoIndent: autoIndent,
            smartIndent: smartIndent
        )
        
        // Only update text if it's different from what's in the editor
        if textView.string != text && !context.coordinator.isUpdating {
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
        var highlightCurrentLine = true
        var currentLineColor = "#F0F0F0"
        var showIndentGuides = true
        var scrollBeyondLastLine = false
        var currentLineRange: NSRange?
        var tabSize = 4
        var replaceTabsBySpaces = false
        var maintainIndent = true
        var autoIndent = true
        var smartIndent = false
        
        init(_ parent: BracketHighlightTextEditor) {
            self.parent = parent
        }
        
        func getDocument() -> Document? {
            // This would need to be passed in or accessed from the parent view
            // For now, return nil as we don't have direct access to the document
            return nil
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Prevent recursive updates
            if isUpdating { 
                return 
            }
            
            // Get the new text
            let newText = textView.string
            
            // Port of Notepad++ SCN_CHARADDED handling from NppNotification.cpp
            // Check what character was just typed
            let currentPos = textView.selectedRange().location
            if currentPos > 0 && currentPos <= newText.count {
                let index = newText.index(newText.startIndex, offsetBy: currentPos - 1)
                let lastChar = newText[index]
                
                // Port of: if (nppGui._maintainIndent != autoIndent_none)
                //             maintainIndentation(static_cast<wchar_t>(notification->ch));
                if AppSettings.shared.maintainIndent {
                    textView.maintainIndentation(character: lastChar)
                }
                
                // Port of auto-completion update (if enabled)
                // if (currentBuf->allowAutoCompletion()) { autoC->update(notification->ch); }
                // We're disabling this for now as requested
            }
            
            // Update the binding
            self.parent.text = newText
            
            // Call the optional onTextChange if provided
            self.parent.onTextChange?(newText)
            
            updateBracketHighlighting()
            updateCurrentLineHighlight()
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            updateBracketHighlighting()
            updateCurrentLineHighlight()
            
            // Update smart highlighting
            if let textView = textView {
                textView.updateSmartHighlight()
            }
        }
        
        func updateBracketHighlighting() {
            guard let textView = textView,
                  AppSettings.shared.matchBraces else { return }
            
            // Clear previous bracket highlighting
            if let textStorage = textView.textStorage {
                let fullRange = NSRange(location: 0, length: textStorage.length)
                textStorage.removeAttribute(.backgroundColor, range: fullRange)
            }
            
            // Apply syntax highlighting if enabled
            if parent.syntaxHighlightingEnabled, let language = parent.language {
                applySyntaxHighlighting(textView: textView, language: language)
            }
            
            // Use the translated Notepad++ braceMatch function
            // This is a DIRECT PORT from Notepad_plus.cpp line 2993-3024
            textView.performBraceMatch()
        }
        
        // REMOVED: highlightBracketPair - Now handled by NSTextView.braceHighlight() 
        // which is a direct translation of SCI_BRACEHIGHLIGHT
        
        func applySyntaxHighlighting(textView: NSTextView, language: LanguageDefinition) {
            guard let textStorage = textView.textStorage else { return }
            guard AppSettings.shared.syntaxHighlighting else { return }
            
            let text = textView.string
            
            // DIRECT PORT - Use exact Scintilla lexer behavior from Notepad++
            // This matches ScintillaEditView::defineDocType() behavior
            
            // Get keywords for LIST_0 and LIST_1 (matching setPythonLexer LIST_0 | LIST_1)
            var keywords0: [String] = []
            var keywords1: [String] = []
            
            for keywordSet in language.keywords {
                if keywordSet.name == "Instructions" {
                    keywords0 = keywordSet.keywords
                } else if keywordSet.name == "Types" || keywordSet.name == "Instructions 2" {
                    keywords1 = keywordSet.keywords
                }
            }
            
            // Port of language-specific lexer selection (like defineDocType switch statement)
            switch language.name.lowercased() {
            case "python":
                // Direct port of setPythonLexer()
                ScintillaLexerPort.applyPythonHighlighting(
                    to: textStorage,
                    text: text,
                    keywords0: keywords0,
                    keywords1: keywords1
                )
                
            case "javascript", "js":
                // TODO: Port setJsLexer()
                ScintillaLexerPort.applyJavaScriptHighlighting(
                    to: textStorage,
                    text: text,
                    keywords: keywords0
                )
                
            case "c", "cpp", "c++":
                // TODO: Port setCppLexer()
                ScintillaLexerPort.applyCppHighlighting(
                    to: textStorage,
                    text: text,
                    keywords: keywords0
                )
                
            default:
                // For now, use basic highlighting for other languages
                // This will be replaced with direct ports of each lexer
                applyBasicHighlighting(textStorage: textStorage, text: text, language: language)
            }
        }
        
        // Temporary fallback until all lexers are ported
        private func applyBasicHighlighting(textStorage: NSTextStorage, text: String, language: LanguageDefinition) {
            // Basic keyword matching as fallback
            for keywordSet in language.keywords {
                for keyword in keywordSet.keywords {
                    if let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b", options: []) {
                        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
                        for match in matches {
                            textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
                        }
                    }
                }
            }
        }
        
        private func colorForKeywordType(_ type: String) -> NSColor {
            return ThemeManager.shared.currentTheme.colorForTokenType(type)
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
        // Translation of IDM_SEARCH_GOTOMATCHINGBRACE handling from NppCommands.cpp
        @objc func jumpToMatchingBracket(_ sender: Any?) {
            guard let textView = textView else { return }
            
            // Direct translation from NppCommands.cpp line 1784-1795
            var braceAtCaret: Int = -1
            var braceOpposite: Int = -1
            
            // Line 1786: findMatchingBracePos(braceAtCaret, braceOpposite);
            textView.findMatchingBracePos(&braceAtCaret, &braceOpposite)
            
            // Line 1788-1795: Jump to matching brace if found
            if braceOpposite != -1 {
                // Set cursor position to matching brace
                textView.setSelectedRange(NSRange(location: braceOpposite, length: 0))
                textView.scrollRangeToVisible(NSRange(location: braceOpposite, length: 1))
            }
        }
        
        func updateCurrentLineHighlight() {
            guard let textView = textView,
                  highlightCurrentLine else { return }
            
            let text = textView.string as NSString
            let selectedRange = textView.selectedRange()
            
            // Remove previous line highlight (with bounds checking)
            if let previousRange = currentLineRange,
               let textStorage = textView.textStorage,
               previousRange.location + previousRange.length <= text.length {
                textStorage.removeAttribute(.backgroundColor, range: previousRange)
            }
            
            // Guard against invalid selection range
            guard selectedRange.location <= text.length else { return }
            
            // Find current line range
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            let safeRange = NSRange(location: min(selectedRange.location, text.length), length: 0)
            text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: safeRange)
            
            // Ensure the range is valid
            let lineRange = NSRange(location: lineStart, length: max(0, lineEnd - lineStart))
            guard lineRange.location + lineRange.length <= text.length else { return }
            
            currentLineRange = lineRange
            
            // Apply highlight to current line
            if let textStorage = textView.textStorage {
                // Use custom color if set, otherwise use theme color
                let color = NSColor(hex: currentLineColor) ?? ThemeManager.shared.currentTheme.currentLineColor
                textStorage.addAttribute(.backgroundColor, value: color, range: lineRange)
            }
        }
    }
}