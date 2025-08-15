//
//  AutoCompletionEngine.swift
//  Notepad++
//
//  Auto-completion engine for code suggestions
//

import Foundation
import AppKit

class AutoCompletionEngine: NSObject {
    static let shared = AutoCompletionEngine()
    
    private var wordList: Set<String> = []
    private var functionSignatures: [String: String] = [:]
    private weak var textView: NSTextView?
    private var completionWindow: NSWindow?
    
    override init() {
        super.init()
        setupBuiltInCompletions()
    }
    
    private func setupBuiltInCompletions() {
        // Add common programming keywords
        wordList = Set([
            // Swift
            "func", "var", "let", "class", "struct", "enum", "protocol",
            "extension", "import", "if", "else", "for", "while", "switch",
            "case", "default", "return", "break", "continue", "guard",
            "defer", "init", "deinit", "self", "super", "static", "override",
            "private", "public", "internal", "fileprivate", "open",
            
            // Common types
            "String", "Int", "Double", "Float", "Bool", "Array", "Dictionary",
            "Set", "Optional", "Any", "AnyObject", "NSObject", "NSString",
            
            // Common functions
            "print", "assert", "precondition", "fatalError", "debugPrint"
        ])
        
        // Add function signatures
        functionSignatures = [
            "print": "print(_ items: Any...)",
            "assert": "assert(_ condition: Bool, _ message: String = \"\")",
            "min": "min(_ x: T, _ y: T) -> T",
            "max": "max(_ x: T, _ y: T) -> T"
        ]
    }
    
    func configure(for textView: NSTextView) {
        self.textView = textView
        
        // Observe text changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )
    }
    
    @objc private func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView,
              AppSettings.shared.enableAutoCompletion else { return }
        
        let text = textView.string
        let selectedRange = textView.selectedRange()
        
        // Get current word being typed
        guard let wordRange = getCurrentWordRange(in: text, at: selectedRange.location),
              wordRange.length >= AppSettings.shared.autoCompletionMinChars else {
            hideCompletionWindow()
            return
        }
        
        let currentWord = (text as NSString).substring(with: wordRange)
        
        // Skip if word contains only numbers and setting says to ignore
        if AppSettings.shared.autoCompletionIgnoreNumbers && currentWord.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            hideCompletionWindow()
            return
        }
        
        // Get suggestions
        let suggestions = getSuggestions(for: currentWord)
        
        if !suggestions.isEmpty {
            showCompletionWindow(with: suggestions, for: wordRange)
        } else {
            hideCompletionWindow()
        }
    }
    
    private func getCurrentWordRange(in text: String, at location: Int) -> NSRange? {
        guard location > 0 else { return nil }
        
        let nsText = text as NSString
        var start = location - 1
        
        // Find word start
        while start > 0 {
            let char = nsText.character(at: start)
            if !CharacterSet.alphanumerics.contains(UnicodeScalar(char)!) && char != Character("_").asciiValue! {
                start += 1
                break
            }
            start -= 1
        }
        
        if start < 0 { start = 0 }
        
        let length = location - start
        return length > 0 ? NSRange(location: start, length: length) : nil
    }
    
    private func getSuggestions(for prefix: String) -> [String] {
        var suggestions: [String] = []
        
        // Get matches from word list
        suggestions += wordList.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
        
        // Get words from current document
        if let textView = textView {
            let documentWords = extractWords(from: textView.string)
            suggestions += documentWords.filter { 
                $0.lowercased().hasPrefix(prefix.lowercased()) && $0 != prefix 
            }
        }
        
        // Remove duplicates and sort
        let uniqueSuggestions = Array(Set(suggestions)).sorted()
        
        return Array(uniqueSuggestions.prefix(10)) // Limit to 10 suggestions
    }
    
    private func extractWords(from text: String) -> Set<String> {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 }
        return Set(words)
    }
    
    private func showCompletionWindow(with suggestions: [String], for wordRange: NSRange) {
        hideCompletionWindow()
        
        guard let textView = textView,
              let window = textView.window else { return }
        
        // Calculate position for completion window
        let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: wordRange, actualCharacterRange: nil)
        let rect = textView.layoutManager?.boundingRect(forGlyphRange: glyphRange ?? wordRange, in: textView.textContainer!)
        
        guard let textRect = rect else { return }
        
        let screenRect = textView.convert(textRect, to: nil)
        let windowRect = window.convertToScreen(screenRect)
        
        // Create completion list view
        let listView = AutoCompletionListView(
            suggestions: suggestions,
            wordRange: wordRange,
            textView: textView,
            onCompletion: { [weak self] in
                self?.hideCompletionWindow()
            }
        )
        
        // Create window for completion list
        let panel = NSPanel(
            contentRect: NSRect(x: windowRect.origin.x, y: windowRect.origin.y - 150, width: 200, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.contentView = NSHostingView(rootView: listView)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        
        window.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)  // Use orderFront instead of makeKeyAndOrderFront
        
        completionWindow = panel
    }
    
    private func hideCompletionWindow() {
        completionWindow?.parent?.removeChildWindow(completionWindow!)
        completionWindow?.orderOut(nil)
        completionWindow = nil
    }
    
    func insertCompletion(_ completion: String, at range: NSRange, in textView: NSTextView) {
        let settings = AppSettings.shared
        var insertText = completion
        
        // Add auto-insert characters based on settings
        if settings.autoInsertParentheses && functionSignatures[completion] != nil {
            insertText += "()"
        } else if settings.autoInsertBrackets && completion.hasSuffix("Array") {
            insertText += "[]"
        } else if settings.autoInsertQuotes && completion == "String" {
            insertText += "\"\""
        }
        
        // Replace the partial word with completion
        let currentWord = (textView.string as NSString).substring(with: range)
        let replaceRange = NSRange(location: range.location, length: currentWord.count)
        
        if textView.shouldChangeText(in: replaceRange, replacementString: insertText) {
            textView.replaceCharacters(in: replaceRange, with: insertText)
            textView.didChangeText()
            
            // Show function signature if available
            if settings.showFunctionParameters,
               let signature = functionSignatures[completion] {
                showFunctionHint(signature, at: NSRange(location: range.location + insertText.count, length: 0))
            }
        }
    }
    
    private func showFunctionHint(_ signature: String, at range: NSRange) {
        // Implementation for showing function parameter hints
        // This would show a tooltip with the function signature
    }
}

// SwiftUI View for completion list
import SwiftUI

struct AutoCompletionListView: View {
    let suggestions: [String]
    let wordRange: NSRange
    weak var textView: NSTextView?
    let onCompletion: () -> Void
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            List(suggestions.indices, id: \.self) { index in
                Text(suggestions[index])
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedIndex == index ? Color.accentColor : Color.clear)
                    .foregroundColor(selectedIndex == index ? .white : .primary)
                    .onTapGesture {
                        selectCompletion(at: index)
                    }
            }
            .listStyle(PlainListStyle())
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .shadow(radius: 4)
        .onAppear {
            setupKeyboardHandling()
        }
    }
    
    private func selectCompletion(at index: Int) {
        guard let textView = textView else { return }
        
        let completion = suggestions[index]
        AutoCompletionEngine.shared.insertCompletion(completion, at: wordRange, in: textView)
        onCompletion()
    }
    
    private func setupKeyboardHandling() {
        // Handle keyboard navigation
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 125: // Down arrow
                if selectedIndex < suggestions.count - 1 {
                    selectedIndex += 1
                }
                return nil
            case 126: // Up arrow
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return nil
            case 36: // Enter
                selectCompletion(at: selectedIndex)
                return nil
            case 53: // Escape
                onCompletion()
                return nil
            default:
                return event
            }
        }
    }
}