//
//  BracketMatcher.swift
//  Notepad++
//
//  Service for matching brackets and parentheses in code
//

import Foundation
import AppKit

class BracketMatcher: ObservableObject {
    static let shared = BracketMatcher()
    
    // Bracket pairs to match
    private let bracketPairs: [(open: Character, close: Character)] = [
        ("(", ")"),
        ("[", "]"),
        ("{", "}"),
        ("<", ">")
    ]
    
    // Find the matching bracket for a given position
    func findMatchingBracket(in text: String, at position: Int) -> Int? {
        guard position >= 0 && position < text.count else { return nil }
        
        let index = text.index(text.startIndex, offsetBy: position)
        let char = text[index]
        
        // Check if it's an opening bracket
        if let pair = bracketPairs.first(where: { $0.open == char }) {
            return findClosingBracket(in: text, startingAt: position, openChar: pair.open, closeChar: pair.close)
        }
        
        // Check if it's a closing bracket
        if let pair = bracketPairs.first(where: { $0.close == char }) {
            return findOpeningBracket(in: text, startingAt: position, openChar: pair.open, closeChar: pair.close)
        }
        
        return nil
    }
    
    // Find closing bracket from an opening bracket position
    private func findClosingBracket(in text: String, startingAt position: Int, openChar: Character, closeChar: Character) -> Int? {
        var depth = 0
        var currentPos = position
        
        while currentPos < text.count {
            let index = text.index(text.startIndex, offsetBy: currentPos)
            let char = text[index]
            
            if char == openChar {
                depth += 1
            } else if char == closeChar {
                depth -= 1
                if depth == 0 {
                    return currentPos
                }
            }
            
            currentPos += 1
        }
        
        return nil
    }
    
    // Find opening bracket from a closing bracket position
    private func findOpeningBracket(in text: String, startingAt position: Int, openChar: Character, closeChar: Character) -> Int? {
        var depth = 0
        var currentPos = position
        
        while currentPos >= 0 {
            let index = text.index(text.startIndex, offsetBy: currentPos)
            let char = text[index]
            
            if char == closeChar {
                depth += 1
            } else if char == openChar {
                depth -= 1
                if depth == 0 {
                    return currentPos
                }
            }
            
            currentPos -= 1
        }
        
        return nil
    }
    
    // Get all bracket pairs in the text (for highlighting)
    func findAllBracketPairs(in text: String) -> [(open: Int, close: Int)] {
        var pairs: [(open: Int, close: Int)] = []
        var stack: [(char: Character, position: Int)] = []
        
        for (index, char) in text.enumerated() {
            // Check if it's an opening bracket
            if bracketPairs.contains(where: { $0.open == char }) {
                stack.append((char, index))
            }
            // Check if it's a closing bracket
            else if let bracketPair = bracketPairs.first(where: { $0.close == char }) {
                // Find matching opening bracket in stack
                if let lastIndex = stack.lastIndex(where: { $0.char == bracketPair.open }) {
                    let openBracket = stack.remove(at: lastIndex)
                    pairs.append((open: openBracket.position, close: index))
                }
            }
        }
        
        return pairs
    }
    
    // Check if brackets are balanced in the text
    func areBracketsBalanced(in text: String) -> Bool {
        var stack: [Character] = []
        
        for char in text {
            if let pair = bracketPairs.first(where: { $0.open == char }) {
                stack.append(pair.open)
            } else if let pair = bracketPairs.first(where: { $0.close == char }) {
                if stack.isEmpty || stack.last != pair.open {
                    return false
                }
                stack.removeLast()
            }
        }
        
        return stack.isEmpty
    }
    
    // Find unmatched brackets for error highlighting
    func findUnmatchedBrackets(in text: String) -> [Int] {
        var unmatched: [Int] = []
        var stack: [(char: Character, position: Int)] = []
        
        for (index, char) in text.enumerated() {
            if let pair = bracketPairs.first(where: { $0.open == char }) {
                stack.append((pair.open, index))
            } else if let pair = bracketPairs.first(where: { $0.close == char }) {
                if let lastIndex = stack.lastIndex(where: { $0.char == pair.open }) {
                    stack.remove(at: lastIndex)
                } else {
                    // Unmatched closing bracket
                    unmatched.append(index)
                }
            }
        }
        
        // All remaining opening brackets are unmatched
        unmatched.append(contentsOf: stack.map { $0.position })
        
        return unmatched
    }
}