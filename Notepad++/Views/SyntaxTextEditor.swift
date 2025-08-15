//
//  SyntaxTextEditor.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI
import AppKit

struct SyntaxTextEditor: NSViewRepresentable {
    @Binding var text: String
    let language: LanguageDefinition?
    let fontSize: CGFloat
    let syntaxHighlightingEnabled: Bool
    let onTextChange: (String) -> Void
    @ObservedObject private var settings = AppSettings.shared
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = true // Need rich text for syntax highlighting
        textView.allowsUndo = true
        
        // Enable drag and drop
        textView.importsGraphics = false
        textView.isSelectable = true
        textView.isEditable = true
        textView.allowsDocumentBackgroundColorChange = false
        
        // Apply settings
        let fontName = settings.fontName.isEmpty ? "Menlo" : settings.fontName
        if let customFont = NSFont(name: fontName, size: CGFloat(settings.fontSize)) {
            textView.font = customFont
        } else {
            textView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        }
        
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Apply tab settings
        let tabWidth = CGFloat(settings.tabSize) * (textView.font?.maximumAdvancement.width ?? 7.0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = []
        for i in 1...20 {
            let tabStop = NSTextTab(textAlignment: .left, location: tabWidth * CGFloat(i))
            paragraphStyle.tabStops.append(tabStop)
        }
        textView.defaultParagraphStyle = paragraphStyle
        
        // Word wrap setting
        if settings.wordWrap {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        } else {
            textView.isHorizontallyResizable = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Apply initial syntax highlighting
        if syntaxHighlightingEnabled {
            context.coordinator.applySyntaxHighlighting(to: textView)
        }
        
        // Register for notifications
        context.coordinator.setupNotifications(for: textView)
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Update font from settings
        let fontName = settings.fontName.isEmpty ? "Menlo" : settings.fontName
        if let customFont = NSFont(name: fontName, size: CGFloat(settings.fontSize)) {
            textView.font = customFont
        } else {
            textView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        }
        
        // Update tab settings
        let tabWidth = CGFloat(settings.tabSize) * (textView.font?.maximumAdvancement.width ?? 7.0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = []
        for i in 1...20 {
            let tabStop = NSTextTab(textAlignment: .left, location: tabWidth * CGFloat(i))
            paragraphStyle.tabStops.append(tabStop)
        }
        textView.defaultParagraphStyle = paragraphStyle
        
        // Update word wrap
        if settings.wordWrap {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        } else {
            textView.isHorizontallyResizable = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Only update text if it's different AND we're not currently typing
        if !context.coordinator.isUserTyping && textView.string != text {
            context.coordinator.isUpdating = true
            textView.string = text
            context.coordinator.lastKnownText = text
            if syntaxHighlightingEnabled && settings.syntaxHighlighting {
                context.coordinator.applySyntaxHighlighting(to: textView)
            }
            context.coordinator.isUpdating = false
        }
        
        // Update syntax highlighting setting
        context.coordinator.syntaxHighlightingEnabled = syntaxHighlightingEnabled && settings.syntaxHighlighting
        context.coordinator.language = language
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxTextEditor
        var syntaxHighlightingEnabled: Bool
        var language: LanguageDefinition?
        private let syntaxHighlighter = SyntaxHighlighter()
        var isUpdating = false
        var isUserTyping = false
        var lastKnownText = ""
        private var searchRanges: [NSRange] = []
        private var currentSearchIndex: Int = 0
        private weak var textView: NSTextView?
        
        init(_ parent: SyntaxTextEditor) {
            self.parent = parent
            self.syntaxHighlightingEnabled = parent.syntaxHighlightingEnabled
            self.language = parent.language
            super.init()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        func setupNotifications(for textView: NSTextView) {
            self.textView = textView
            
            // Search notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleHighlightSearchResults(_:)),
                name: .highlightSearchResult,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClearSearchHighlights(_:)),
                name: .clearSearchHighlights,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSelectSearchResult(_:)),
                name: .selectSearchResult,
                object: nil
            )
            
            // Edit menu notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleUndo(_:)),
                name: .undo,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRedo(_:)),
                name: .redo,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCut(_:)),
                name: .cut,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCopy(_:)),
                name: .copy,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePaste(_:)),
                name: .paste,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSelectAll(_:)),
                name: .selectAll,
                object: nil
            )
        }
        
        @objc private func handleHighlightSearchResults(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let ranges = userInfo["ranges"] as? [NSRange],
                  let textView = self.textView else { return }
            
            searchRanges = ranges
            if let currentIndex = userInfo["currentIndex"] as? Int {
                currentSearchIndex = currentIndex
            }
            
            applySyntaxHighlighting(to: textView)
            
            // If there's a specific range to focus on, scroll to it
            if let range = userInfo["range"] as? NSRange {
                textView.scrollRangeToVisible(range)
                textView.showFindIndicator(for: range)
            }
        }
        
        @objc private func handleClearSearchHighlights(_ notification: Notification) {
            guard let textView = self.textView else { return }
            searchRanges = []
            currentSearchIndex = 0
            applySyntaxHighlighting(to: textView)
        }
        
        @objc private func handleSelectSearchResult(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let range = userInfo["range"] as? NSRange,
                  let textView = self.textView else { return }
            
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }
        
        // MARK: - Edit Command Handlers
        
        @objc private func handleUndo(_ notification: Notification) {
            guard let textView = self.textView else { return }
            if textView.undoManager?.canUndo == true {
                textView.undoManager?.undo()
            }
        }
        
        @objc private func handleRedo(_ notification: Notification) {
            guard let textView = self.textView else { return }
            if textView.undoManager?.canRedo == true {
                textView.undoManager?.redo()
            }
        }
        
        @objc private func handleCut(_ notification: Notification) {
            guard let textView = self.textView else { return }
            if textView.selectedRange().length > 0 {
                textView.cut(nil)
            }
        }
        
        @objc private func handleCopy(_ notification: Notification) {
            guard let textView = self.textView else { return }
            if textView.selectedRange().length > 0 {
                textView.copy(nil)
            }
        }
        
        @objc private func handlePaste(_ notification: Notification) {
            guard let textView = self.textView else { return }
            textView.paste(nil)
        }
        
        @objc private func handleSelectAll(_ notification: Notification) {
            guard let textView = self.textView else { return }
            textView.selectAll(nil)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Skip if this change came from updateNSView
            if isUpdating { return }
            
            isUserTyping = true
            let newText = textView.string
            lastKnownText = newText
            
            // Update the binding
            parent.text = newText
            parent.onTextChange(newText)
            
            // If we have search highlights, update them after content changes
            if !searchRanges.isEmpty {
                // Post notification to recalculate search results
                NotificationCenter.default.post(
                    name: .documentContentChanged,
                    object: nil
                )
            }
            
            // Apply syntax highlighting with a smaller delay for better responsiveness
            if syntaxHighlightingEnabled {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedHighlight(_:)), object: textView)
                perform(#selector(delayedHighlight(_:)), with: textView, afterDelay: 0.1)
            }
            
            // Reset typing flag after a short delay
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(resetTypingFlag), object: nil)
            perform(#selector(resetTypingFlag), with: nil, afterDelay: 0.5)
        }
        
        @objc private func resetTypingFlag() {
            isUserTyping = false
        }
        
        @objc private func delayedHighlight(_ textView: NSTextView) {
            applySyntaxHighlighting(to: textView)
        }
        
        func applySyntaxHighlighting(to textView: NSTextView) {
            guard syntaxHighlightingEnabled, let language = language else {
                // Reset to default formatting if highlighting is disabled
                let range = NSRange(location: 0, length: textView.string.count)
                textView.textStorage?.removeAttribute(.foregroundColor, range: range)
                textView.textStorage?.removeAttribute(.backgroundColor, range: range)
                textView.textStorage?.removeAttribute(.font, range: range)
                let defaultFont = NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular)
                textView.textStorage?.addAttribute(.font, value: defaultFont, range: range)
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
                return
            }
            
            let text = textView.string
            let textStorage = textView.textStorage!
            
            // Store cursor position and scroll position
            let selectedRange = textView.selectedRange()
            let visibleRect = textView.visibleRect
            
            // Begin editing
            textStorage.beginEditing()
            
            // Reset attributes more carefully to preserve text
            let fullRange = NSRange(location: 0, length: text.count)
            let defaultFont = NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular)
            
            // Remove only color attributes, preserve the text
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.removeAttribute(.backgroundColor, range: fullRange)
            textStorage.removeAttribute(.font, range: fullRange)
            textStorage.addAttribute(.font, value: defaultFont, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            
            // Apply syntax highlighting
            let attributedString = syntaxHighlighter.highlightedText(for: text, language: language)
            
            // Convert SwiftUI AttributedString to NSAttributedString attributes
            var currentIndex = 0
            for run in attributedString.runs {
                let length = attributedString[run.range].characters.count
                let range = NSRange(location: currentIndex, length: length)
                
                if let color = run.foregroundColor {
                    textStorage.addAttribute(.foregroundColor, value: NSColor(color), range: range)
                }
                
                if let font = run.font {
                    // Handle bold and italic
                    var traits: NSFontTraitMask = []
                    if font == .system(.body).bold() {
                        traits.insert(.boldFontMask)
                    }
                    if font == .system(.body).italic() {
                        traits.insert(.italicFontMask)
                    }
                    
                    if !traits.isEmpty {
                        let fontManager = NSFontManager.shared
                        if let currentFont = textStorage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                            if let modifiedFont = fontManager.font(withFamily: currentFont.familyName ?? "Menlo", 
                                                                  traits: traits, 
                                                                  weight: 5, 
                                                                  size: currentFont.pointSize) {
                                textStorage.addAttribute(.font, value: modifiedFont, range: range)
                            }
                        }
                    }
                }
                
                currentIndex += length
            }
            
            // End editing
            textStorage.endEditing()
            
            // Restore cursor position and scroll position
            textView.setSelectedRange(selectedRange)
            textView.scrollToVisible(visibleRect)
            
            // Highlight search results if any
            highlightSearchResults(in: textStorage)
        }
        
        func highlightSearchResults(in textStorage: NSTextStorage) {
            // Highlight all search results with yellow background
            for range in searchRanges {
                if range.location + range.length <= textStorage.length {
                    textStorage.addAttribute(.backgroundColor, value: NSColor.yellow.withAlphaComponent(0.3), range: range)
                }
            }
            
            // Highlight current search result with stronger color
            if currentSearchIndex >= 0 && currentSearchIndex < searchRanges.count {
                let currentRange = searchRanges[currentSearchIndex]
                if currentRange.location + currentRange.length <= textStorage.length {
                    textStorage.addAttribute(.backgroundColor, value: NSColor.orange.withAlphaComponent(0.5), range: currentRange)
                }
            }
        }
        
    }
}

// Helper to convert SwiftUI Color to NSColor
extension NSColor {
    convenience init(_ color: Color) {
        // This is a simplified conversion - in production you'd want more robust handling
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        self.init(red: components[safe: 0] ?? 0,
                  green: components[safe: 1] ?? 0,
                  blue: components[safe: 2] ?? 0,
                  alpha: components[safe: 3] ?? 1)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}