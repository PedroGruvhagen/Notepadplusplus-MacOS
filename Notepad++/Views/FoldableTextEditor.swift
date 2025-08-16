//
//  FoldableTextEditor.swift
//  Notepad++
//
//  Text editor with code folding support
//

import SwiftUI
import AppKit

struct FoldableTextEditor: NSViewRepresentable {
    @Binding var text: String
    let language: LanguageDefinition?
    let fontSize: CGFloat
    let syntaxHighlightingEnabled: Bool
    let onTextChange: (String) -> Void
    @ObservedObject var foldingState: FoldingState
    @ObservedObject private var settings = AppSettings.shared
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = FoldableTextView.scrollableTextView()
        
        if let foldableTextView = scrollView.documentView as? FoldableTextView {
            foldableTextView.foldingDelegate = context.coordinator
            foldableTextView.string = text
            foldableTextView.isAutomaticQuoteSubstitutionEnabled = false
            foldableTextView.isAutomaticSpellingCorrectionEnabled = false
            foldableTextView.isRichText = true
            foldableTextView.allowsUndo = true
            foldableTextView.importsGraphics = false
            foldableTextView.isSelectable = true
            foldableTextView.isEditable = true
            foldableTextView.allowsDocumentBackgroundColorChange = false
            
            // Set up folding state
            foldableTextView.foldingState = foldingState
            
            // Apply settings
            let fontName = settings.fontName.isEmpty ? "Menlo" : settings.fontName
            if let customFont = NSFont(name: fontName, size: CGFloat(settings.fontSize)) {
                foldableTextView.font = customFont
            } else {
                foldableTextView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
            }
            
            foldableTextView.textColor = NSColor.labelColor
            foldableTextView.backgroundColor = NSColor.textBackgroundColor
            
            context.coordinator.setupTextView(foldableTextView)
            context.coordinator.updateFoldingRegions()
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? FoldableTextView else { return }
        
        // Update font from settings
        let fontName = settings.fontName.isEmpty ? "SF Mono" : settings.fontName
        if let customFont = NSFont(name: fontName, size: CGFloat(settings.fontSize)) {
            textView.font = customFont
        } else {
            textView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(settings.fontSize), weight: .regular)
        }
        
        // Update text if different
        if textView.string != text {
            textView.string = text
            context.coordinator.updateFoldingRegions()
        }
        
        context.coordinator.syntaxHighlightingEnabled = syntaxHighlightingEnabled && settings.syntaxHighlighting
        context.coordinator.language = language
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, FoldableTextViewDelegate {
        var parent: FoldableTextEditor
        var syntaxHighlightingEnabled: Bool
        var language: LanguageDefinition?
        private let syntaxHighlighter = SyntaxHighlighter()
        private weak var textView: FoldableTextView?
        
        init(_ parent: FoldableTextEditor) {
            self.parent = parent
            self.syntaxHighlightingEnabled = parent.syntaxHighlightingEnabled
            self.language = parent.language
            super.init()
        }
        
        func setupTextView(_ textView: FoldableTextView) {
            self.textView = textView
            textView.delegate = self
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            parent.text = textView.string
            parent.onTextChange(textView.string)
            
            // Update folding regions after text change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.updateFoldingRegions()
            }
            
            // Apply syntax highlighting
            if syntaxHighlightingEnabled {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedHighlight(_:)), object: textView)
                perform(#selector(delayedHighlight(_:)), with: textView, afterDelay: 0.3)
            }
        }
        
        @objc private func delayedHighlight(_ textView: NSTextView) {
            applySyntaxHighlighting(to: textView)
        }
        
        func applySyntaxHighlighting(to textView: NSTextView) {
            guard syntaxHighlightingEnabled, let language = language else { return }
            
            let text = textView.string
            let textStorage = textView.textStorage!
            let selectedRange = textView.selectedRange()
            
            textStorage.beginEditing()
            
            // Reset attributes
            let fullRange = NSRange(location: 0, length: text.count)
            textStorage.removeAttribute(.foregroundColor, range: fullRange)
            textStorage.removeAttribute(.font, range: fullRange)
            textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            
            // Apply syntax highlighting
            let attributedString = syntaxHighlighter.highlightedText(for: text, language: language)
            
            var currentIndex = 0
            for run in attributedString.runs {
                let length = attributedString[run.range].characters.count
                let range = NSRange(location: currentIndex, length: length)
                
                if let color = run.foregroundColor {
                    textStorage.addAttribute(.foregroundColor, value: NSColor(color), range: range)
                }
                
                currentIndex += length
            }
            
            textStorage.endEditing()
            textView.setSelectedRange(selectedRange)
        }
        
        func updateFoldingRegions() {
            guard let textView = textView else { return }
            
            let regions = FoldingManager.detectFoldingRegions(
                in: textView.string,
                language: language
            )
            
            parent.foldingState.updateRegions(regions)
            textView.needsDisplay = true
        }
        
        // FoldableTextViewDelegate
        func toggleFold(at line: Int) {
            parent.foldingState.toggleFold(at: line)
            textView?.updateVisibleText()
        }
        
        func isFoldableHeader(line: Int) -> Bool {
            return parent.foldingState.isFoldableHeader(line: line)
        }
        
        func isLineCollapsed(line: Int) -> Bool {
            return !parent.foldingState.isLineVisible(line: line)
        }
        
        func getFoldingRegion(at line: Int) -> FoldingRegion? {
            return parent.foldingState.regions.first { $0.startLine == line }
        }
    }
}

// Protocol for folding delegate
protocol FoldableTextViewDelegate: AnyObject {
    func toggleFold(at line: Int)
    func isFoldableHeader(line: Int) -> Bool
    func isLineCollapsed(line: Int) -> Bool
    func getFoldingRegion(at line: Int) -> FoldingRegion?
}

// Custom NSTextView with folding support
class FoldableTextView: NSTextView {
    weak var foldingDelegate: FoldableTextViewDelegate?
    var foldingState: FoldingState?
    private var foldButtons: [NSButton] = []
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawFoldingIndicators()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupFoldingUI()
    }
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupFoldingUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFoldingUI()
    }
    
    private func setupFoldingUI() {
        // Setup will be done when drawing
    }
    
    private func drawFoldingIndicators() {
        // Remove old buttons
        foldButtons.forEach { $0.removeFromSuperview() }
        foldButtons.removeAll()
        
        guard let foldingState = foldingState,
              let layoutManager = layoutManager,
              textContainer != nil else { return }
        
        let lines = string.components(separatedBy: .newlines)
        var visibleLineIndex = 0
        
        for (lineIndex, _) in lines.enumerated() {
            // Skip collapsed lines
            if foldingState.isLineVisible(lineIndex: lineIndex) {
                if let region = foldingState.regions.first(where: { $0.startLine == lineIndex }) {
                    // This line is a foldable header
                    let lineRange = (string as NSString).lineRange(for: NSRange(location: 0, length: 0))
                    let lineRect = layoutManager.lineFragmentRect(
                        forGlyphAt: layoutManager.glyphIndexForCharacter(at: lineRange.location),
                        effectiveRange: nil
                    )
                    
                    // Create fold button
                    let button = NSButton(frame: NSRect(x: -20, y: lineRect.origin.y, width: 16, height: 16))
                    button.bezelStyle = .shadowlessSquare
                    button.isBordered = false
                    button.title = region.isCollapsed ? "▶" : "▼"
                    button.target = self
                    button.action = #selector(foldButtonClicked(_:))
                    button.tag = lineIndex
                    
                    addSubview(button)
                    foldButtons.append(button)
                }
                visibleLineIndex += 1
            }
        }
    }
    
    @objc private func foldButtonClicked(_ sender: NSButton) {
        let line = sender.tag
        foldingDelegate?.toggleFold(at: line)
    }
    
    func updateVisibleText() {
        guard let foldingState = foldingState else { return }
        
        // Build visible text
        let lines = string.components(separatedBy: .newlines)
        var visibleLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            if foldingState.isLineVisible(lineIndex: index) {
                // Check if this is a collapsed header
                if let region = foldingState.regions.first(where: { $0.startLine == index && $0.isCollapsed }) {
                    // Add the header line with a folding indicator
                    let linesHidden = region.endLine - region.startLine
                    visibleLines.append("\(line) ... (\(linesHidden) lines)")
                } else {
                    visibleLines.append(line)
                }
            }
        }
        
        // Update display without triggering text change
        let newText = visibleLines.joined(separator: "\n")
        if newText != string {
            string = newText
            needsDisplay = true
        }
    }
}

// Extension for FoldingState
extension FoldingState {
    func isLineVisible(lineIndex: Int) -> Bool {
        return !collapsedLines.contains(lineIndex)
    }
}