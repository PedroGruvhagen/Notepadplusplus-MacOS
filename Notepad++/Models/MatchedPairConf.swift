//
//  MatchedPairConf.swift
//  Notepad++
//
//  LITERAL TRANSLATION of MatchedPairConf class
//  Source: PowerEditor/src/Parameters.h lines 758-773
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// Helper struct for Codable character pairs
struct CharacterPair: Codable {
    let first: String
    let second: String
}

// Translation of class MatchedPairConf final from Parameters.h line 758-773
struct MatchedPairConf: Codable {

    // Line 766: std::vector<std::pair<char, char>> _matchedPairs;
    var _matchedPairs: [CharacterPair] = []

    // Line 767: bool _doHtmlXmlTag = false;
    var _doHtmlXmlTag: Bool = false

    // Line 768: bool _doParentheses = false;
    var _doParentheses: Bool = false

    // Line 769: bool _doBrackets = false;
    var _doBrackets: Bool = false

    // Line 770: bool _doCurlyBrackets = false;
    var _doCurlyBrackets: Bool = false

    // Line 771: bool _doQuotes = false;
    var _doQuotes: Bool = false

    // Line 772: bool _doDoubleQuotes = false;
    var _doDoubleQuotes: Bool = false

    // MARK: - Methods (Translation of lines 761-763)

    // Line 761: bool hasUserDefinedPairs() const { return _matchedPairs.size() != 0; }
    func hasUserDefinedPairs() -> Bool {
        return _matchedPairs.count != 0
    }

    // Line 762: bool hasDefaultPairs() const
    func hasDefaultPairs() -> Bool {
        return _doParentheses || _doBrackets || _doCurlyBrackets || _doQuotes || _doDoubleQuotes || _doHtmlXmlTag
    }

    // Line 763: bool hasAnyPairsPair() const { return hasUserDefinedPairs() || hasDefaultPairs(); }
    func hasAnyPairsPair() -> Bool {
        return hasUserDefinedPairs() || hasDefaultPairs()
    }

    // MARK: - Initialization

    // Default initializer - C++ has implicit default constructor
    init() {
        // All properties have default values
    }
}
