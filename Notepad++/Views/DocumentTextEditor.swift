//
//  DocumentTextEditor.swift
//  Notepad++
//
//  Document-aware text editor that uses Document's NSTextStorage
//  This is the CRITICAL FIX for language state bleeding across tabs
//

import SwiftUI
import AppKit

struct DocumentTextEditor: NSViewRepresentable {
    @ObservedObject var document: Document
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
    let syntaxHighlightingEnabled: Bool
    
    // Store the text view for document swapping
    static var sharedTextView: NSTextView?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // Create or reuse the text view
        let textView: NSTextView
        if let shared = Self.sharedTextView {
            textView = shared
        } else {
            textView = NSTextView()
            Self.sharedTextView = textView
        }
        
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
        
        // Ensure text is always visible with proper contrast
        let bgColor = theme.backgroundColor
        let txtColor = theme.textColor
        
        // Fallback: if colors are too similar, force black on white
        if abs(bgColor.brightnessComponent - txtColor.brightnessComponent) < 0.3 {
            textView.textColor = .black
            textView.backgroundColor = .white
        } else {
            textView.textColor = txtColor
            textView.backgroundColor = bgColor
        }
        
        textView.insertionPointColor = textView.textColor
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
        
        // CRITICAL: Activate this document's text storage
        // This is the Swift equivalent of SCI_SETDOCPOINTER
        document.activate(in: textView)
        
        // Force layout update to ensure content is displayed
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.needsDisplay = true
        
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
        context.coordinator.document = document
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
        PerformanceManager.shared.optimizeTextView(textView, forLargeFile: document.isLargeFile)
        
        // Apply initial syntax highlighting if enabled
        if syntaxHighlightingEnabled {
            if let language = document.language {
                print("DEBUG: Initial highlighting - Language detected: \(language.name)")
                document.syntaxHighlighter.highlight(textStorage: document.textStorage, language: language)
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
        
        // Check if we need to switch documents
        if context.coordinator.document?.id != document.id {
            // Save state from old document
            context.coordinator.document?.saveState(from: textView)
            
            // Activate new document (swaps text storage) and restore position when switching tabs
            document.activate(in: textView, restorePosition: true)
            
            // Force layout update to ensure content is displayed
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            textView.needsDisplay = true
            
            // Update coordinator reference
            context.coordinator.document = document
            
            // Apply syntax highlighting for new document
            if syntaxHighlightingEnabled, let language = document.language {
                document.syntaxHighlighter.highlight(textStorage: document.textStorage, language: language)
            }
        }
        
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DocumentTextEditor
        weak var textView: NSTextView?
        weak var document: Document?
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
        
        init(_ parent: DocumentTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let document = document else { return }
            
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
            }
            
            // Update the document's content property
            document.updateContent(newText)
            
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
            
            // Use the translated Notepad++ braceMatch function
            // This is a DIRECT PORT from Notepad_plus.cpp line 2993-3024
            textView.performBraceMatch()
        }
        
        // Handle bracket navigation (Cmd+M to jump to matching bracket)
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

// Extension moved to PerformanceManager