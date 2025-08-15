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
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Apply initial syntax highlighting
        if syntaxHighlightingEnabled {
            context.coordinator.applySyntaxHighlighting(to: textView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Update font size
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Update text if it's different from what's displayed
        if textView.string != text {
            textView.string = text
            if syntaxHighlightingEnabled {
                context.coordinator.applySyntaxHighlighting(to: textView)
            }
        }
        
        // Update syntax highlighting setting
        context.coordinator.syntaxHighlightingEnabled = syntaxHighlightingEnabled
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
        private var isUpdating = false
        
        init(_ parent: SyntaxTextEditor) {
            self.parent = parent
            self.syntaxHighlightingEnabled = parent.syntaxHighlightingEnabled
            self.language = parent.language
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update the binding
            parent.text = textView.string
            parent.onTextChange(textView.string)
            
            // Apply syntax highlighting with a small delay to avoid performance issues
            if syntaxHighlightingEnabled && !isUpdating {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedHighlight(_:)), object: textView)
                perform(#selector(delayedHighlight(_:)), with: textView, afterDelay: 0.3)
            }
        }
        
        @objc private func delayedHighlight(_ textView: NSTextView) {
            applySyntaxHighlighting(to: textView)
        }
        
        func applySyntaxHighlighting(to textView: NSTextView) {
            guard syntaxHighlightingEnabled, let language = language else {
                // Reset to default formatting if highlighting is disabled
                let range = NSRange(location: 0, length: textView.string.count)
                textView.textStorage?.removeAttribute(.foregroundColor, range: range)
                textView.textStorage?.removeAttribute(.font, range: range)
                textView.textStorage?.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: range)
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
                return
            }
            
            isUpdating = true
            
            let text = textView.string
            let textStorage = textView.textStorage!
            
            // Store cursor position
            let selectedRange = textView.selectedRange()
            
            // Begin editing
            textStorage.beginEditing()
            
            // Reset all attributes first
            let fullRange = NSRange(location: 0, length: text.count)
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.removeAttribute(.font, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)
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
            
            // Restore cursor position
            textView.setSelectedRange(selectedRange)
            
            isUpdating = false
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