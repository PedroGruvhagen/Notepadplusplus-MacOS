//
//  DebugBracketHighlightTextEditor.swift
//  Debug version to see what's happening with highlighting
//

import Foundation
import AppKit

extension BracketHighlightTextEditor.Coordinator {
    func debugApplySyntaxHighlighting(textView: NSTextView, language: LanguageDefinition) {
        print("=== DEBUG SYNTAX HIGHLIGHTING ===")
        print("Language: \(language.name)")
        print("Display Name: \(language.displayName)")
        print("Keywords sets count: \(language.keywords.count)")
        
        for (index, keywordSet) in language.keywords.enumerated() {
            print("Set \(index): \(keywordSet.name) with \(keywordSet.keywords.count) keywords")
            if keywordSet.keywords.count < 10 {
                print("  Keywords: \(keywordSet.keywords)")
            } else {
                print("  First 10 keywords: \(Array(keywordSet.keywords.prefix(10)))")
            }
        }
        
        guard textView.textStorage != nil else {
            print("ERROR: No text storage!")
            return
        }
        
        guard AppSettings.shared.syntaxHighlighting else {
            print("ERROR: Syntax highlighting disabled in settings!")
            return
        }
        
        let text = textView.string
        print("Text length: \(text.count)")
        print("Text preview: \(String(text.prefix(100)))")
        
        // Call the real function
        applySyntaxHighlighting(textView: textView, language: language)
        print("=== END DEBUG ===")
    }
}