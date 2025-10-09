//
//  AutoCompletionEngine.swift
//  Notepad++
//
//  LITERAL TRANSLATION of AutoCompletion.cpp and AutoCompletion.h
//  Source: PowerEditor/src/ScintillaComponent/AutoCompletion.cpp
//  Source: PowerEditor/src/ScintillaComponent/AutoCompletion.h
//

import Foundation
import AppKit

// MARK: - Supporting Types

// Translation of MatchedCharInserted struct (AutoCompletion.h lines 25-30)
struct MatchedCharInserted {
    let _c: Character
    let _pos: Int

    init(_ c: Character, _ pos: Int) {
        self._c = c
        self._pos = pos
    }
}

// Translation of InsertedMatchedChars class (AutoCompletion.h lines 32-43)
class InsertedMatchedChars {
    private var _insertedMatchedChars: [MatchedCharInserted] = []
    private weak var _pEditView: NSTextView?

    func initialize(textView: NSTextView) {
        _pEditView = textView
    }

    // Translation of AutoCompletion.cpp lines 754-780
    func removeInvalidElements(_ mci: MatchedCharInserted) {
        guard let textView = _pEditView else { return }

        if mci._c == "\n" || mci._c == "\r" {
            _insertedMatchedChars.removeAll()
        } else {
            for i in stride(from: _insertedMatchedChars.count - 1, through: 0, by: -1) {
                if _insertedMatchedChars[i]._pos < mci._pos {
                    let posToDetectLine = lineNumber(for: mci._pos, in: textView)
                    let startPosLine = lineNumber(for: _insertedMatchedChars[i]._pos, in: textView)

                    if posToDetectLine != startPosLine {
                        _insertedMatchedChars.remove(at: i)
                    }
                } else {
                    _insertedMatchedChars.remove(at: i)
                }
            }
        }
    }

    // Translation of AutoCompletion.cpp lines 782-786
    func add(_ mci: MatchedCharInserted) {
        removeInvalidElements(mci)
        _insertedMatchedChars.append(mci)
    }

    func isEmpty() -> Bool {
        return _insertedMatchedChars.isEmpty
    }

    // Translation of AutoCompletion.cpp lines 791-840
    func search(startChar: Character, endChar: Character, posToDetect: Int) -> Int {
        guard !isEmpty(), let textView = _pEditView else { return -1 }

        let posToDetectLine = lineNumber(for: posToDetect, in: textView)

        for i in stride(from: _insertedMatchedChars.count - 1, through: 0, by: -1) {
            if _insertedMatchedChars[i]._c == startChar {
                if _insertedMatchedChars[i]._pos < posToDetect {
                    let startPosLine = lineNumber(for: _insertedMatchedChars[i]._pos, in: textView)

                    if posToDetectLine == startPosLine {
                        let endPos = lineEndPosition(for: startPosLine, in: textView)

                        for j in posToDetect...endPos {
                            if let aChar = characterAt(position: j, in: textView) {
                                if aChar != " " {
                                    if aChar == endChar {
                                        _insertedMatchedChars.remove(at: i)
                                        return j
                                    } else {
                                        _insertedMatchedChars.remove(at: i)
                                        return -1
                                    }
                                }
                            }
                        }
                    } else {
                        _insertedMatchedChars.remove(at: i)
                    }
                } else {
                    _insertedMatchedChars.remove(at: i)
                }
            }
        }
        return -1
    }

    // Helper methods for NSTextView
    private func lineNumber(for position: Int, in textView: NSTextView) -> Int {
        let string = textView.string as NSString
        guard position < string.length else { return 0 }
        var lineNumber = 0
        string.enumerateSubstrings(in: NSRange(location: 0, length: position + 1),
                                   options: .byLines) { _, _, _, _ in
            lineNumber += 1
        }
        return lineNumber
    }

    private func lineEndPosition(for lineNumber: Int, in textView: NSTextView) -> Int {
        let string = textView.string as NSString
        var currentLine = 0
        var endPos = 0

        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length),
                                   options: .byLines) { substring, range, _, stop in
            currentLine += 1
            if currentLine == lineNumber {
                endPos = range.location + range.length
                stop.pointee = true
            }
        }
        return endPos
    }

    private func characterAt(position: Int, in textView: NSTextView) -> Character? {
        let string = textView.string as NSString
        guard position < string.length else { return nil }
        let unichar = string.character(at: position)
        return Character(UnicodeScalar(unichar)!)
    }
}

// MARK: - AutoCompletion Engine

// Translation of AutoCompletion class (AutoCompletion.h lines 45-128)
class AutoCompletionEngine: NSObject {

    // MARK: - AutocompleteType enum (AutoCompletion.h lines 118-123)
    enum AutocompleteType {
        case autocFunc
        case autocFuncAndWord
        case autocFuncBrief
        case autocWord
    }

    // MARK: - Properties (AutoCompletion.h lines 97-113)

    private weak var _pEditView: NSTextView?
    private var _funcCompletionActive: Bool = false
    private var _curLang: LangType = .L_TEXT
    private var _ignoreCase: Bool = true

    private var _keyWordArray: [String] = []
    private var _keyWords: String = ""
    private var _keyWordMaxLen: Int = 0

    private let _insertedMatchedChars = InsertedMatchedChars()

    private var completionWindow: NSPanel?
    private var completionViewController: AutoCompletionListViewController?

    // MARK: - Constants (AutoCompletion.cpp lines 23-250)
    private let FUNC_IMG_ID = 1000
    private let BOX_IMG_ID = 1001

    // MARK: - Initialization

    init(textView: NSTextView) {
        self._pEditView = textView
        super.init()
        _insertedMatchedChars.initialize(textView: textView)
    }

    // MARK: - Core Auto-Completion Methods

    // Translation of AutoCompletion::update() (AutoCompletion.cpp lines 1017-1054)
    func update(character: Int) {
        guard character != 0 else { return }
        guard let textView = _pEditView else { return }

        let nppGUI = AppSettings.shared.nppGUI

        // Check if auto-completion is disabled for function completion
        if !_funcCompletionActive && nppGUI._autocStatus == .autocFunc {
            return
        }

        // Get word to current position
        let wordSize = 64
        guard let currentWord = getWordToCurrentPos(maxLength: wordSize) else { return }

        // Check if word length meets minimum threshold
        if currentWord.count >= nppGUI._autocFromLen {
            switch nppGUI._autocStatus {
            case .autocWord:
                _ = showWordComplete(autoInsert: false)

            case .autocFunc:
                if nppGUI._autocBrief {
                    _ = showAutoComplete(autocType: .autocFuncBrief, autoInsert: false)
                } else {
                    _ = showApiComplete()
                }

            case .autocBoth:
                _ = showApiAndWordComplete()

            case .autocNone:
                break
            }
        }
    }

    // Translation of AutoCompletion::showAutoComplete() (AutoCompletion.cpp lines 293-442)
    func showAutoComplete(autocType: AutocompleteType, autoInsert: Bool) -> Bool {
        guard let textView = _pEditView else { return false }

        // Check if function completion is required but not active
        if autocType == .autocFunc && !_funcCompletionActive {
            return false
        }

        // Get beginning of word and complete word
        let curPos = textView.selectedRange().location
        let startPos = wordStartPosition(at: curPos)

        if curPos == startPos {
            return false
        }

        let len = curPos - startPos
        var words = ""

        if autocType == .autocFunc {
            if len >= _keyWordMaxLen {
                return false
            }
        } else {
            let bufSize = 256
            if len >= bufSize {
                return false
            }

            let endPos = wordEndPosition(at: curPos)
            let lena = endPos - startPos
            if lena >= bufSize {
                return false
            }

            guard let beginChars = getGenericText(from: startPos, to: curPos) else {
                return false
            }

            // Get word array containing all words beginning with beginChars
            var wordArray: [String] = []

            if autocType == .autocWord || autocType == .autocFuncAndWord {
                if let allChars = getGenericText(from: startPos, to: endPos) {
                    getWordArray(wordArray: &wordArray, beginChars: beginChars, excludeChars: allChars)
                }
            }

            // Add keywords to word array (AutoCompletion.cpp lines 342-366)
            if autocType == .autocFuncBrief || autocType == .autocFuncAndWord {
                for keyword in _keyWordArray {
                    let compareResult: ComparisonResult

                    if _ignoreCase {
                        let kwPrefix = String(keyword.prefix(len))
                        compareResult = beginChars.caseInsensitiveCompare(kwPrefix) == .orderedSame ? .orderedSame : .orderedDescending
                    } else {
                        compareResult = keyword.hasPrefix(beginChars) ? .orderedSame : .orderedDescending
                    }

                    if compareResult == .orderedSame {
                        if !wordArray.contains(keyword) {
                            wordArray.append(keyword)
                        }
                    }
                }
            }

            if wordArray.isEmpty {
                return false
            }

            // Optionally, auto-insert word (AutoCompletion.cpp lines 373-386)
            if autocType == .autocWord && wordArray.count == 1 && autoInsert {
                let word = wordArray[0]
                // Check for type separator
                if let separatorIndex = word.firstIndex(of: "\u{1E}") {
                    let insertWord = String(word[..<separatorIndex])
                    replaceTarget(text: insertWord, from: startPos, to: curPos)
                } else {
                    replaceTarget(text: word, from: startPos, to: curPos)
                }
                textView.setSelectedRange(NSRange(location: startPos + word.count, length: 0))
                return true
            }

            // Sort word array (AutoCompletion.cpp lines 390-396)
            if autocType == .autocWord || autocType == .autocFuncAndWord {
                if _ignoreCase {
                    wordArray.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                } else {
                    wordArray.sort()
                }
            }

            // Convert to single string with space-separated words (lines 398-403)
            words = wordArray.joined(separator: " ")
        }

        // Show the autocompletion menu (AutoCompletion.cpp lines 406-439)
        let completionList: String
        if autocType == .autocFunc {
            completionList = _keyWords
        } else {
            completionList = words
        }

        showAutoCompletion(length: len, words: completionList)
        return true
    }

    // Translation of AutoCompletion::showApiComplete() (AutoCompletion.cpp lines 444-447)
    func showApiComplete() -> Bool {
        return showAutoComplete(autocType: .autocFunc, autoInsert: false)
    }

    // Translation of AutoCompletion::showApiAndWordComplete() (AutoCompletion.cpp lines 449-452)
    func showApiAndWordComplete() -> Bool {
        return showAutoComplete(autocType: .autocFuncAndWord, autoInsert: false)
    }

    // Translation of AutoCompletion::showWordComplete() (AutoCompletion.cpp lines 664-667)
    func showWordComplete(autoInsert: Bool) -> Bool {
        return showAutoComplete(autocType: .autocWord, autoInsert: autoInsert)
    }

    // Translation of AutoCompletion::getWordArray() (AutoCompletion.cpp lines 454-517)
    func getWordArray(wordArray: inout [String], beginChars: String, excludeChars: String) {
        guard let textView = _pEditView else { return }

        let nppGUI = AppSettings.shared.nppGUI

        // Check: ignore numbers setting (line 459-460)
        if nppGUI._autocIgnoreNumbers && isAllDigits(beginChars) {
            return
        }

        // Build regex pattern (lines 462-464)
        // Pattern: \<beginChars[^ \t\n\r.,;:"(){}=<>'+!?\[\]]+
        let escapedBeginChars = NSRegularExpression.escapedPattern(for: beginChars)
        let pattern = "\\b\(escapedBeginChars)[^ \\t\\n\\r.,;:\"(){}=<>'+!?\\[\\]]*"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: _ignoreCase ? .caseInsensitive : []) else {
            return
        }

        let documentText = textView.string
        let searchRange = NSRange(location: 0, length: (documentText as NSString).length)

        // Search entire document for matches (lines 474-516)
        let matches = regex.matches(in: documentText, options: [], range: searchRange)

        for match in matches {
            let matchRange = match.range
            let foundWord = (documentText as NSString).substring(with: matchRange)

            // Exclude the word we're currently typing (line 489)
            if foundWord != excludeChars && foundWord.count < 256 {
                if !wordArray.contains(foundWord) {
                    wordArray.append(foundWord)
                }
            }
        }
    }

    // MARK: - Helper Methods (Translation of helper functions)

    // Translation of isAllDigits() (AutoCompletion.cpp lines 263-271)
    private func isAllDigits(_ str: String) -> Bool {
        for char in str {
            if !char.isNumber {
                return false
            }
        }
        return !str.isEmpty
    }

    // NSTextView equivalents for Scintilla messages
    private func wordStartPosition(at position: Int) -> Int {
        guard let textView = _pEditView else { return position }
        let text = textView.string as NSString

        var pos = position - 1
        while pos > 0 {
            let char = text.character(at: pos)
            let scalar = UnicodeScalar(char)!
            if !CharacterSet.alphanumerics.contains(scalar) && scalar != "_" {
                return pos + 1
            }
            pos -= 1
        }
        return 0
    }

    private func wordEndPosition(at position: Int) -> Int {
        guard let textView = _pEditView else { return position }
        let text = textView.string as NSString
        let length = text.length

        var pos = position
        while pos < length {
            let char = text.character(at: pos)
            let scalar = UnicodeScalar(char)!
            if !CharacterSet.alphanumerics.contains(scalar) && scalar != "_" {
                return pos
            }
            pos += 1
        }
        return length
    }

    private func getGenericText(from: Int, to: Int) -> String? {
        guard let textView = _pEditView else { return nil }
        let text = textView.string as NSString
        guard from >= 0, to <= text.length, from < to else { return nil }
        return text.substring(with: NSRange(location: from, length: to - from))
    }

    private func getWordToCurrentPos(maxLength: Int) -> String? {
        guard let textView = _pEditView else { return nil }
        let curPos = textView.selectedRange().location
        let startPos = wordStartPosition(at: curPos)
        return getGenericText(from: startPos, to: curPos)
    }

    private func replaceTarget(text: String, from: Int, to: Int) {
        guard let textView = _pEditView else { return }
        let range = NSRange(location: from, length: to - from)
        if textView.shouldChangeText(in: range, replacementString: text) {
            textView.replaceCharacters(in: range, with: text)
            textView.didChangeText()
        }
    }

    // Show autocompletion window
    private func showAutoCompletion(length: Int, words: String) {
        guard let textView = _pEditView else { return }
        guard let window = textView.window else { return }

        hideCompletionWindow()

        let suggestions = words.components(separatedBy: " ").filter { !$0.isEmpty }
        if suggestions.isEmpty { return }

        // Calculate position for completion window
        let curPos = textView.selectedRange().location
        let startPos = wordStartPosition(at: curPos)
        let wordRange = NSRange(location: startPos, length: length)

        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let glyphRange = layoutManager.glyphRange(forCharacterRange: wordRange, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        let screenRect = textView.convert(rect, to: nil)
        let windowRect = window.convertToScreen(NSRect(origin: screenRect.origin, size: screenRect.size))

        // Create completion list view controller
        let viewController = AutoCompletionListViewController(
            suggestions: suggestions,
            wordRange: wordRange,
            textView: textView,
            onCompletion: { [weak self] in
                self?.hideCompletionWindow()
            }
        )

        // Create window for completion list
        let panel = NSPanel(
            contentRect: NSRect(x: windowRect.origin.x, y: windowRect.origin.y - 150, width: 250, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = viewController
        panel.backgroundColor = NSColor.controlBackgroundColor
        panel.isOpaque = true
        panel.hasShadow = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true

        window.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)

        completionWindow = panel
        completionViewController = viewController
    }

    private func hideCompletionWindow() {
        if let window = completionWindow {
            window.parent?.removeChildWindow(window)
            window.orderOut(nil)
        }
        completionWindow = nil
        completionViewController = nil
    }

    // MARK: - Language and Keyword Loading

    // Translation of AutoCompletion::setLanguage() (AutoCompletion.cpp lines 1071-1203)
    @discardableResult
    func setLanguage(_ language: LangType) -> Bool {
        // If language hasn't changed and keywords are already loaded, return early
        if _curLang == language && !_keyWordArray.isEmpty {
            return _funcCompletionActive
        }

        _curLang = language

        // Get keywords for this language
        let keywords = getKeywordsForLanguage(language)

        // Clear existing keywords (lines 1159-1160)
        _keyWords = ""
        _keyWordArray.removeAll()
        _keyWordMaxLen = 0

        _funcCompletionActive = !keywords.isEmpty

        if _funcCompletionActive {
            // Cache the keywords (lines 1164-1189)
            for keyword in keywords {
                let len = keyword.count
                if len > 0 {
                    var word = keyword
                    // Add image ID separator (lines 1177-1182)
                    let imgid = "\u{1E}\(FUNC_IMG_ID)"  // Using FUNC_IMG_ID for all keywords for now
                    word += imgid
                    _keyWordArray.append(word)
                    if len > _keyWordMaxLen {
                        _keyWordMaxLen = len
                    }
                }
            }

            // Sort keywords (lines 1191-1194)
            if _ignoreCase {
                _keyWordArray.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            } else {
                _keyWordArray.sort()
            }

            // Build space-separated string (lines 1196-1200)
            _keyWords = _keyWordArray.joined(separator: " ")
        }

        return _funcCompletionActive
    }

    // Helper to get keywords for a language (simplified version of XML loading from C++)
    private func getKeywordsForLanguage(_ language: LangType) -> [String] {
        switch language {
        case .L_C, .L_CPP:
            return [
                "auto", "break", "case", "char", "const", "continue", "default", "do",
                "double", "else", "enum", "extern", "float", "for", "goto", "if",
                "int", "long", "register", "return", "short", "signed", "sizeof", "static",
                "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
                // C++ additions
                "class", "namespace", "template", "typename", "public", "private", "protected",
                "virtual", "override", "final", "nullptr", "bool", "true", "false",
                "try", "catch", "throw", "new", "delete", "this", "operator"
            ]

        case .L_JAVA:
            return [
                "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
                "class", "const", "continue", "default", "do", "double", "else", "enum",
                "extends", "final", "finally", "float", "for", "goto", "if", "implements",
                "import", "instanceof", "int", "interface", "long", "native", "new", "package",
                "private", "protected", "public", "return", "short", "static", "strictfp",
                "super", "switch", "synchronized", "this", "throw", "throws", "transient",
                "try", "void", "volatile", "while", "true", "false", "null"
            ]

        case .L_JAVASCRIPT:
            return [
                "async", "await", "break", "case", "catch", "class", "const", "continue",
                "debugger", "default", "delete", "do", "else", "export", "extends", "finally",
                "for", "function", "if", "import", "in", "instanceof", "let", "new", "return",
                "static", "super", "switch", "this", "throw", "try", "typeof", "var", "void",
                "while", "with", "yield", "true", "false", "null", "undefined",
                // Common built-ins
                "Array", "Boolean", "Date", "Error", "Function", "JSON", "Math", "Number",
                "Object", "Promise", "Reg Exp", "String", "Symbol", "console", "document",
                "window", "setTimeout", "setInterval"
            ]

        case .L_PYTHON:
            return [
                "False", "None", "True", "and", "as", "assert", "async", "await", "break",
                "class", "continue", "def", "del", "elif", "else", "except", "finally",
                "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal",
                "not", "or", "pass", "raise", "return", "try", "while", "with", "yield",
                // Common built-ins
                "print", "len", "range", "str", "int", "float", "list", "dict", "tuple",
                "set", "bool", "type", "isinstance", "super", "property", "classmethod",
                "staticmethod", "enumerate", "zip", "map", "filter"
            ]

        case .L_HTML, .L_XML:
            return [
                // HTML5 tags
                "html", "head", "title", "meta", "link", "style", "script", "body",
                "div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th",
                "form", "input", "button", "select", "option", "textarea", "label",
                "h1", "h2", "h3", "h4", "h5", "h6", "header", "footer", "nav", "section",
                "article", "aside", "main", "figure", "figcaption", "video", "audio", "canvas",
                // Common attributes
                "class", "id", "src", "href", "alt", "title", "width", "height", "style",
                "type", "name", "value", "placeholder", "required", "disabled", "readonly"
            ]

        case .L_PHP:
            return [
                "abstract", "and", "array", "as", "break", "callable", "case", "catch",
                "class", "clone", "const", "continue", "declare", "default", "die", "do",
                "echo", "else", "elseif", "empty", "enddeclare", "endfor", "endforeach",
                "endif", "endswitch", "endwhile", "eval", "exit", "extends", "final",
                "finally", "fn", "for", "foreach", "function", "global", "goto", "if",
                "implements", "include", "include_once", "instanceof", "insteadof",
                "interface", "isset", "list", "match", "namespace", "new", "or", "print",
                "private", "protected", "public", "readonly", "require", "require_once",
                "return", "static", "switch", "throw", "trait", "try", "unset", "use",
                "var", "while", "xor", "yield", "true", "false", "null"
            ]

        case .L_TEXT:
            return [] // No keywords for plain text

        default:
            // For all other languages not yet implemented, return empty array
            return []
        }
    }

    // MARK: - Configuration Methods

    func configure(for textView: NSTextView) {
        self._pEditView = textView
        _insertedMatchedChars.initialize(textView: textView)

        // Set default language to trigger keyword loading
        setLanguage(.L_TEXT)

        // Observe text changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    @objc private func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        guard AppSettings.shared.enableAutoCompletion else { return }

        // Get the last typed character
        let selectedRange = textView.selectedRange()
        if selectedRange.location > 0 {
            let lastCharRange = NSRange(location: selectedRange.location - 1, length: 1)
            if let lastChar = (textView.string as NSString).substring(with: lastCharRange).first {
                update(character: Int(lastChar.asciiValue ?? 0))
            }
        }
    }
}

// MARK: - SwiftUI Completion List View

import SwiftUI

// Note: Using NSViewController-based approach for proper event monitor lifecycle
class AutoCompletionListViewController: NSViewController {
    let suggestions: [String]
    let wordRange: NSRange
    weak var textView: NSTextView?
    let onCompletion: () -> Void

    private var selectedIndex = 0
    private var eventMonitor: Any?

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    init(suggestions: [String], wordRange: NSRange, textView: NSTextView?, onCompletion: @escaping () -> Void) {
        self.suggestions = suggestions
        self.wordRange = wordRange
        self.textView = textView
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 150))

        // Setup table view
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("completion"))
        column.width = 250
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]

        view.addSubview(scrollView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupKeyboardHandling()
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        removeKeyboardHandling()
    }

    deinit {
        removeKeyboardHandling()
    }

    private func setupKeyboardHandling() {
        removeKeyboardHandling()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            switch event.keyCode {
            case 125: // Down arrow
                if self.selectedIndex < self.suggestions.count - 1 {
                    self.selectedIndex += 1
                    self.tableView.selectRowIndexes(IndexSet(integer: self.selectedIndex), byExtendingSelection: false)
                    self.tableView.scrollRowToVisible(self.selectedIndex)
                }
                return nil
            case 126: // Up arrow
                if self.selectedIndex > 0 {
                    self.selectedIndex -= 1
                    self.tableView.selectRowIndexes(IndexSet(integer: self.selectedIndex), byExtendingSelection: false)
                    self.tableView.scrollRowToVisible(self.selectedIndex)
                }
                return nil
            case 36: // Enter
                self.selectCompletion(at: self.selectedIndex)
                return nil
            case 53: // Escape
                self.onCompletion()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyboardHandling() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    @objc private func tableViewDoubleClick() {
        let row = tableView.clickedRow
        if row >= 0 && row < suggestions.count {
            selectCompletion(at: row)
        }
    }

    private func selectCompletion(at index: Int) {
        guard let textView = textView else { return }
        guard index < suggestions.count else { return }

        let completion = suggestions[index]

        // Remove type separator if present
        let finalCompletion: String
        if let separatorIndex = completion.firstIndex(of: "\u{1E}") {
            finalCompletion = String(completion[..<separatorIndex])
        } else {
            finalCompletion = completion
        }

        // Replace the partial word with completion
        if textView.shouldChangeText(in: wordRange, replacementString: finalCompletion) {
            textView.replaceCharacters(in: wordRange, with: finalCompletion)
            textView.didChangeText()
            textView.setSelectedRange(NSRange(location: wordRange.location + finalCompletion.count, length: 0))
        }

        onCompletion()
    }
}

extension AutoCompletionListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return suggestions.count
    }
}

extension AutoCompletionListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("CompletionCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            let textField = NSTextField()
            textField.isBordered = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            cell?.addSubview(textField)
            cell?.textField = textField
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
            cell?.identifier = identifier
        }

        let suggestion = suggestions[row]
        // Remove type separator for display
        if let separatorIndex = suggestion.firstIndex(of: "\u{1E}") {
            cell?.textField?.stringValue = String(suggestion[..<separatorIndex])
        } else {
            cell?.textField?.stringValue = suggestion
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedIndex = tableView.selectedRow
    }
}
