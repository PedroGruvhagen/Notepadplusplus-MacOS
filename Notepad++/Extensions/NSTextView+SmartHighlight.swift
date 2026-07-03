//
//  NSTextView+SmartHighlight.swift
//  Notepad++
//
//  Extension to implement smart highlighting for NSTextView
//

import AppKit

extension NSTextView {
    
    private static var smartHighlightRangesKey: UInt8 = 0
    
    private var smartHighlightRanges: [NSRange]? {
        get {
            objc_getAssociatedObject(self, &NSTextView.smartHighlightRangesKey) as? [NSRange]
        }
        set {
            objc_setAssociatedObject(self, &NSTextView.smartHighlightRangesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func updateSmartHighlight() {
        let settings = AppSettings.shared
        
        guard settings.smartHighlighting else {
            clearSmartHighlight()
            return
        }
        
        // Clear previous highlights
        clearSmartHighlight()
        
        // Get selected text
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0 else { return }
        
        let text = self.string as NSString
        let selectedText = text.substring(with: selectedRange)
        
        // Don't highlight if selection is too short or contains whitespace
        if selectedText.count < 2 || selectedText.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return
        }
        
        // Build search pattern
        var pattern = NSRegularExpression.escapedPattern(for: selectedText)
        var options: NSRegularExpression.Options = []
        
        if settings.smartHighlightWholeWord {
            pattern = "\\b\(pattern)\\b"
        }
        
        if !settings.smartHighlightMatchCase {
            options.insert(.caseInsensitive)
        }
        
        // Restrict the scan to the VISIBLE character range, expanded to whole lines, rather
        // than the whole document. Faithful to SmartHighlighter.cpp:36-39
        // (highlightViewWithWord), which scans only firstVisibleLine ..
        // firstVisibleLine + min(linesOnScreen, MAXLINEHIGHLIGHT); the visible rect is
        // inherently that bounded window. Derived the same way syntax highlighting derives
        // its visible range (F12). If the view is not laid out yet, there is nothing on
        // screen to highlight.
        guard let visibleRange = SyntaxHighlighter.visibleCharacterRange(of: self) else { return }
        let scanRange = text.lineRange(for: visibleRange)

        // Find all matches
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let matches = regex.matches(in: self.string, options: [], range: scanRange)

            guard let textStorage = self.textStorage else { return }
            
            // Store ranges for clearing later
            var highlightRanges: [NSRange] = []
            
            // Highlight all matches except the current selection
            for match in matches {
                if !NSEqualRanges(match.range, selectedRange) {
                    textStorage.addAttribute(
                        .backgroundColor,
                        value: NSColor.systemYellow.withAlphaComponent(0.3),
                        range: match.range
                    )
                    highlightRanges.append(match.range)
                }
            }
            
            smartHighlightRanges = highlightRanges
            
        } catch {
            // Invalid regex, ignore
        }
    }
    
    func clearSmartHighlight() {
        guard let textStorage = self.textStorage,
              let ranges = smartHighlightRanges else { return }

        let length = textStorage.length
        for range in ranges {
            // Bounds-check against the CURRENT storage: after a document swap the stored
            // ranges may belong to a different (shorter) storage (F03), which otherwise
            // raises NSRangeException.
            guard range.location >= 0,
                  range.length >= 0,
                  range.location + range.length <= length else { continue }
            textStorage.removeAttribute(.backgroundColor, range: range)
        }

        smartHighlightRanges = nil
    }
}