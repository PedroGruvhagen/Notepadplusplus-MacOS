//
//  StyleContext.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Scintilla StyleContext class
//  Source: lexilla/lexlib/StyleContext.h
//  This is NOT a reimplementation - it's a direct translation
//

import Foundation

// MARK: - Style IDs from SciLexer.h
enum SCE_C {
    static let DEFAULT = 0
    static let COMMENT = 1
    static let COMMENTLINE = 2
    static let COMMENTDOC = 3
    static let NUMBER = 4
    static let WORD = 5
    static let STRING = 6
    static let CHARACTER = 7
    static let UUID = 8
    static let PREPROCESSOR = 9
    static let OPERATOR = 10
    static let IDENTIFIER = 11
    static let STRINGEOL = 12
    static let VERBATIM = 13
    static let REGEX = 14
    static let COMMENTLINEDOC = 15
    static let WORD2 = 16
    static let COMMENTDOCKEYWORD = 17
    static let COMMENTDOCKEYWORDERROR = 18
    static let GLOBALCLASS = 19
    static let STRINGRAW = 20
    static let TRIPLEVERBATIM = 21
    static let HASHQUOTEDSTRING = 22
    static let PREPROCESSORCOMMENT = 23
    static let PREPROCESSORCOMMENTDOC = 24
    static let USERLITERAL = 25
    static let TASKMARKER = 26
    static let ESCAPESEQUENCE = 27
}

// MARK: - LexAccessor (Simplified for Swift)
// This provides access to the document text and styling
class LexAccessor {
    var text: String
    var styles: [Int]
    private var startSegment: Int = 0
    
    init(text: String) {
        self.text = text
        self.styles = Array(repeating: SCE_C.DEFAULT, count: text.count)
    }
    
    func safeGetCharAt(_ position: Int, _ chDefault: Character = "\0") -> Character {
        guard position >= 0 && position < text.count else {
            return chDefault
        }
        let index = text.index(text.startIndex, offsetBy: position)
        return text[index]
    }
    
    func getLine(_ position: Int) -> Int {
        var line = 0
        var pos = 0
        for char in text {
            if pos >= position {
                break
            }
            if char == "\n" {
                line += 1
            }
            pos += 1
        }
        return line
    }
    
    func lineStart(_ line: Int) -> Int {
        var currentLine = 0
        var pos = 0
        for char in text {
            if currentLine == line {
                return pos
            }
            if char == "\n" {
                currentLine += 1
            }
            pos += 1
        }
        return pos
    }
    
    func lineEnd(_ line: Int) -> Int {
        var currentLine = 0
        var pos = 0
        for char in text {
            if char == "\n" {
                if currentLine == line {
                    return pos
                }
                currentLine += 1
            }
            pos += 1
        }
        return text.count
    }
    
    func colourTo(_ position: Int, _ state: Int) {
        for i in startSegment..<min(position + 1, styles.count) {
            styles[i] = state
        }
        startSegment = position + 1
    }
    
    func flush() {
        // In the real implementation, this would update the display
    }
    
    func getStartSegment() -> Int {
        return startSegment
    }
}

// MARK: - StyleContext
// Direct translation of lexilla/lexlib/StyleContext.h
class StyleContext {
    private var styler: LexAccessor
    private let lengthDocument: Int
    private let endPos: Int
    private let lineDocEnd: Int
    
    // Public properties matching C++ version
    var currentPos: Int
    var currentLine: Int
    var lineEnd: Int
    var lineStartNext: Int
    var atLineStart: Bool
    var atLineEnd: Bool = false
    var state: Int
    var chPrev: Character = " "
    var ch: Character = " "
    var width: Int = 0
    var chNext: Character = " "
    var widthNext: Int = 1
    
    init(startPos: Int, length: Int, initStyle: Int, styler: LexAccessor) {
        self.styler = styler
        self.lengthDocument = styler.text.count
        self.endPos = startPos + length
        self.lineDocEnd = styler.getLine(lengthDocument - 1)
        
        self.currentPos = startPos
        self.state = initStyle
        self.currentLine = styler.getLine(startPos)
        self.lineEnd = styler.lineEnd(currentLine)
        self.lineStartNext = styler.lineStart(currentLine + 1)
        self.atLineStart = styler.lineStart(currentLine) == startPos
        
        // Initialize first character
        if currentPos < lengthDocument {
            ch = styler.safeGetCharAt(currentPos)
            width = 1
            getNextChar()
        }
    }
    
    private func getNextChar() {
        chNext = styler.safeGetCharAt(currentPos + width, "\0")
        widthNext = 1
        
        // Check if at line end
        if currentLine < lineDocEnd {
            atLineEnd = currentPos >= (lineStartNext - 1)
        } else {
            atLineEnd = currentPos >= lineStartNext
        }
    }
    
    func complete() {
        styler.colourTo(currentPos - (currentPos > lengthDocument ? 2 : 1), state)
        styler.flush()
    }
    
    func more() -> Bool {
        return currentPos < endPos
    }
    
    func forward() {
        if currentPos < endPos {
            atLineStart = atLineEnd
            if atLineStart {
                currentLine += 1
                lineEnd = styler.lineEnd(currentLine)
                lineStartNext = styler.lineStart(currentLine + 1)
            }
            chPrev = ch
            currentPos += width
            ch = chNext
            width = widthNext
            getNextChar()
        } else {
            atLineStart = false
            chPrev = " "
            ch = " "
            chNext = " "
            atLineEnd = true
        }
    }
    
    func forward(_ nb: Int) {
        for _ in 0..<nb {
            forward()
        }
    }
    
    func changeState(_ newState: Int) {
        state = newState
    }
    
    func setState(_ newState: Int) {
        styler.colourTo(currentPos - (currentPos > lengthDocument ? 2 : 1), state)
        state = newState
    }
    
    func forwardSetState(_ newState: Int) {
        forward()
        styler.colourTo(currentPos - (currentPos > lengthDocument ? 2 : 1), state)
        state = newState
    }
    
    func lengthCurrent() -> Int {
        return currentPos - styler.getStartSegment()
    }
    
    func getRelativeChar(_ n: Int, _ chDefault: Character = "\0") -> Character {
        return styler.safeGetCharAt(currentPos + n, chDefault)
    }
    
    func getRelative(_ n: Int, _ chDefault: Character = "\0") -> Character {
        return styler.safeGetCharAt(currentPos + n, chDefault)
    }
    
    func match(_ s: String) -> Bool {
        for (i, char) in s.enumerated() {
            if getRelative(i) != char {
                return false
            }
        }
        return true
    }
}