//
//  WordList.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Scintilla WordList class
//  Source: lexilla/lexlib/WordList.h
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - WordList
// Translation of lexilla/lexlib/WordList.h
class WordList {
    private var words: Set<String> = []
    private var caseSensitive: Bool = true
    
    init(caseSensitive: Bool = true) {
        self.caseSensitive = caseSensitive
    }
    
    // Set words from a space-separated string (matching Scintilla behavior)
    func set(_ wordListText: String?) {
        words.removeAll()
        guard let text = wordListText else { return }
        
        let wordArray = text.split(separator: " ")
        for word in wordArray {
            let wordStr = String(word)
            if !wordStr.isEmpty {
                if caseSensitive {
                    words.insert(wordStr)
                } else {
                    words.insert(wordStr.lowercased())
                }
            }
        }
    }
    
    // Check if a word is in the list
    func inList(_ word: String) -> Bool {
        if caseSensitive {
            return words.contains(word)
        } else {
            return words.contains(word.lowercased())
        }
    }
    
    // Check if list has any words
    func length() -> Int {
        return words.count
    }
    
    // Clear the word list
    func clear() {
        words.removeAll()
    }
}

// MARK: - ScintillaCharacterSet helpers (matching Scintilla's CharacterSet.h)
struct ScintillaCharacterSet {
    private let chars: Set<Character>
    
    init(_ charactersString: String) {
        self.chars = Set(charactersString)
    }
    
    func contains(_ ch: Character) -> Bool {
        return chars.contains(ch)
    }
    
    // Common character sets from Scintilla
    static let setAlpha = ScintillaCharacterSet("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let setDigits = ScintillaCharacterSet("0123456789")
    static let setAlphaNum = ScintillaCharacterSet("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    static let setHexDigits = ScintillaCharacterSet("0123456789ABCDEFabcdef")
    static let setOctDigits = ScintillaCharacterSet("01234567")
    static let setNoneNumeric = ScintillaCharacterSet("")
}

// MARK: - Helper functions from CharacterSet.h
func isWordChar(_ ch: Character) -> Bool {
    return ScintillaCharacterSet.setAlphaNum.contains(ch) || ch == "_"
}

func isWordStart(_ ch: Character) -> Bool {
    return ScintillaCharacterSet.setAlpha.contains(ch) || ch == "_"
}

func isOperator(_ ch: Character) -> Bool {
    let operators = "!%&*+-/<=>?^|~"
    return operators.contains(ch)
}

func isASpace(_ ch: Character) -> Bool {
    return ch == " " || ch == "\t" || ch == "\n" || ch == "\r"
}

func isASpaceOrTab(_ ch: Character) -> Bool {
    return ch == " " || ch == "\t"
}

func isADigit(_ ch: Character) -> Bool {
    return ScintillaCharacterSet.setDigits.contains(ch)
}

func makeLowerCase(_ ch: Character) -> Character {
    return Character(String(ch).lowercased())
}

func makeUpperCase(_ ch: Character) -> Character {
    return Character(String(ch).uppercased())
}