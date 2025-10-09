//
//  Document.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Notepad++ Buffer class
//  Source: PowerEditor/src/ScintillaComponent/Buffer.h and Buffer.cpp
//  This is NOT a reimplementation - it's a direct translation
//  Note: Class renamed to Document for Swift compatibility but it's Buffer from C++
//

import Foundation
import AppKit

// Translation of DocFileStatus enum from Buffer.h line 30-37
struct DocFileStatus: OptionSet {
    let rawValue: Int
    
    static let regular      = DocFileStatus(rawValue: 0x01)  // DOC_REGULAR - should not be combined with anything
    static let unnamed      = DocFileStatus(rawValue: 0x02)  // DOC_UNNAMED - not saved (new ##)
    static let deleted      = DocFileStatus(rawValue: 0x04)  // DOC_DELETED - doesn't exist in environment anymore
    static let modified     = DocFileStatus(rawValue: 0x08)  // DOC_MODIFIED - File in environment has changed
    static let needReload   = DocFileStatus(rawValue: 0x10)  // DOC_NEEDRELOAD - File is modified & needed to be reload
    static let inaccessible = DocFileStatus(rawValue: 0x20)  // DOC_INACCESSIBLE - File is absent on its load
}

// Translation of BufferStatusInfo enum from Buffer.h line 39-52
struct BufferStatusInfo: OptionSet {
    let rawValue: Int
    
    static let none         = BufferStatusInfo(rawValue: 0x000)  // BufferChangeNone
    static let language     = BufferStatusInfo(rawValue: 0x001)  // BufferChangeLanguage
    static let dirty        = BufferStatusInfo(rawValue: 0x002)  // BufferChangeDirty
    static let format       = BufferStatusInfo(rawValue: 0x004)  // BufferChangeFormat
    static let unicode      = BufferStatusInfo(rawValue: 0x008)  // BufferChangeUnicode
    static let readonly     = BufferStatusInfo(rawValue: 0x010)  // BufferChangeReadonly
    static let status       = BufferStatusInfo(rawValue: 0x020)  // BufferChangeStatus
    static let timestamp    = BufferStatusInfo(rawValue: 0x040)  // BufferChangeTimestamp
    static let filename     = BufferStatusInfo(rawValue: 0x080)  // BufferChangeFilename
    static let recentTag    = BufferStatusInfo(rawValue: 0x100)  // BufferChangeRecentTag
    static let lexing       = BufferStatusInfo(rawValue: 0x200)  // BufferChangeLexing
    static let mask         = BufferStatusInfo(rawValue: 0x3FF)  // BufferChangeMask
}

// Translation of SavingStatus enum from Buffer.h line 54-59
enum SavingStatus: Int {
    case saveOK = 0
    case saveOpenFailed = 1
    case saveWritingFailed = 2
    case notEnoughRoom = 3
}

// Translation of Position struct from Buffer.h line 320-335
struct DocumentPosition {
    var _firstVisibleLine: Int = 0
    var _startPos: Int = 0
    var _endPos: Int = 0
    var _xOffset: Int = 0
    var _selMode: Int = 0
    var _scrollWidth: Int = 2000
    var _wrapCount: Int = 0

    init() {}
}

// Translation of Buffer class from Buffer.h line 152
// Named Document in Swift for compatibility but this IS the Buffer class
@MainActor
class Document: ObservableObject {
    // Member variables from Buffer.h line 337-374
    private var _fileManager: FileManager?
    private let _id: UUID  // BufferID in C++ version
    private var _doc: ScintillaDocument  // Document handle
    private var _lang: LanguageDefinition?  // LangType
    private var _references: Int = 0
    private var _refPositions: [Int: DocumentPosition] = [:]  // Map of view ID to position
    private var _foldStates: [Int: [Int]] = [:]  // Map of view ID to fold states
    
    // File properties
    private var _fullPathName: String = ""
    private var _fileName: String = ""
    private var _currentStatus: DocFileStatus = .regular
    private var _isDirty: Bool = false
    private var _isFileReadOnly: Bool = false
    private var _isUserReadOnly: Bool = false
    private var _isInaccessible: Bool = false
    private var _isFromNetwork: Bool = false
    private var _needReloading: Bool = false
    private var _isLargeFile: Bool = false
    
    // Format properties
    private var _eolFormat: EOLType = .unix
    private var _unicodeMode: FileEncoding = .utf8
    private var _encoding: Int = -1
    
    // Lexing
    private var _needLexer: Bool = false
    private var _userLangExt: String = ""
    
    // Recent tag
    private static var _recentTagCtr: Int = 0
    private var _recentTag: Int = 0
    
    // Timestamps
    private var _timeStamp: Date?
    private var _tabCreatedTimeString: String = ""
    
    // Untitled tab
    private var _isUntitledTabRenamed: Bool = false
    
    // Backup
    private var _backupFileName: String = ""
    private var _isModified: Bool = false
    
    // Additional properties for Swift UI compatibility
    @Published var content: String = "" {
        didSet {
            if content != oldValue {
                setDirty(true)
                _doc.setText(content)
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: content)
                textStorage.endEditing()
            }
        }
    }
    
    // NSTextStorage for AppKit integration
    let textStorage: NSTextStorage
    
    // Compatibility properties
    var fileURL: URL? {
        get {
            if !_fullPathName.isEmpty {
                return URL(fileURLWithPath: _fullPathName)
            }
            return nil
        }
        set {
            if let url = newValue {
                setFileName(url.path)
            }
        }
    }
    
    var language: LanguageDefinition? {
        get { _lang }
        set { setLangType(newValue) }
    }
    
    var isModified: Bool {
        get { _isDirty }
        set { setDirty(newValue) }
    }
    
    var encoding: FileEncoding {
        get { _unicodeMode }
        set { setUnicodeMode(newValue) }
    }
    
    var eolType: EOLType {
        get { _eolFormat }
        set { setEolFormat(newValue) }
    }
    
    var fileExtension: String? {
        if let url = fileURL {
            return url.pathExtension.isEmpty ? nil : url.pathExtension
        }
        return nil
    }
    
    // MARK: - Constructor (Translation of Buffer.cpp line 42)
    init(content: String = "", filePath: URL? = nil) {
        // Initialize text storage first
        self.textStorage = NSTextStorage(string: content)
        self.content = content
        
        // Initialize with defaults
        self._fileManager = nil
        self._id = UUID()
        self._doc = ScintillaDocument()
        self._currentStatus = filePath == nil ? .unnamed : .regular
        self._isLargeFile = false
        
        // Set file name if provided
        if let filePath = filePath {
            setFileName(filePath.path)
        } else {
            // Unnamed document
            _fileName = "new \(UUID().uuidString.prefix(8))"
            _tabCreatedTimeString = Date().description
        }
        
        // Initialize content in ScintillaDocument
        _doc.setText(content)
    }
    
    // MARK: - Translation of setFileName (Buffer.cpp line 199)
    func setFileName(_ fn: String) {
        _fullPathName = fn
        _fileName = URL(fileURLWithPath: fn).lastPathComponent
        
        // Determine language from extension (simplified - in real implementation would use LanguageManager)
        if let fileURL = URL(string: fn) {
            let ext = fileURL.pathExtension
            // Detect language from extension
            if let nppLanguage = LanguageManager.shared.detectLanguage(for: _fileName) {
                _lang = nppLanguage.toLanguageDefinition()
            }
        }
        
        // Get last modified time
        if FileManager.default.fileExists(atPath: fn) {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fn) {
                _timeStamp = attributes[.modificationDate] as? Date
                _isFileReadOnly = !(FileManager.default.isWritableFile(atPath: fn))
            }
        }
        
        // Check if network path (translation of Buffer.cpp line 221)
        _isFromNetwork = fn.hasPrefix("\\\\") || fn.hasPrefix("//")
        
        doNotify(.filename)
    }
    
    // MARK: - Translation of checkFileState (Buffer.cpp line 350)
    func checkFileState() -> Bool {
        // Line 355-356: Unsaved document cannot change by environment
        if _currentStatus.contains(.unnamed) {
            return false
        }
        
        let fullPath = _fullPathName
        var hasFileStateChanged = false
        
        // Line 362-386: Check file existence
        let fileExists = FileManager.default.fileExists(atPath: fullPath)
        var fileModificationDate: Date?
        
        if fileExists {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath) {
                fileModificationDate = attributes[.modificationDate] as? Date
            }
        }
        
        // Line 399-410: File has been deleted
        if !fileExists && _currentStatus == .regular {
            _currentStatus = .deleted
            hasFileStateChanged = true
            doNotify([.status])
        }
        // Line 411-422: File has been restored  
        else if fileExists && _currentStatus.contains(.deleted) {
            _currentStatus = .regular
            hasFileStateChanged = true
            
            // Reload the file
            if !_isDirty {
                reload()
            }
            doNotify([.status])
        }
        // Line 423-441: File has been modified
        else if fileExists && _currentStatus == .regular {
            if let modDate = fileModificationDate,
               let lastMod = _timeStamp,
               modDate > lastMod {
                
                _currentStatus = .modified
                hasFileStateChanged = true
                doNotify([.timestamp, .status])
                
                // Auto-reload if not dirty
                if !_isDirty {
                    reload()
                }
            }
        }
        
        return hasFileStateChanged
    }
    
    // MARK: - Translation of reload (Buffer.cpp line 586)
    private func reload() {
        guard !_fullPathName.isEmpty else { return }
        
        do {
            let content = try String(contentsOfFile: _fullPathName, encoding: .utf8)
            _doc.setText(content)
            _isDirty = false
            _needReloading = false
            
            // Update timestamp
            if let attributes = try? FileManager.default.attributesOfItem(atPath: _fullPathName) {
                _timeStamp = attributes[.modificationDate] as? Date
            }
            
            _currentStatus = .regular
            doNotify([.status, .timestamp, .dirty])
        } catch {
            print("Failed to reload file: \(error)")
        }
    }
    
    // MARK: - Translation of setDirty (Buffer.cpp line 297)
    func setDirty(_ dirty: Bool) {
        let wasDirty = _isDirty
        _isDirty = dirty
        
        if wasDirty != dirty {
            doNotify(.dirty)
        }
    }
    
    // MARK: - Translation of setLangType (Buffer.cpp line 257)
    func setLangType(_ lang: LanguageDefinition?, userLangName: String = "") {
        // Compare by name since LanguageDefinition is a struct
        let langChanged = _lang?.name != lang?.name || (_lang == nil && lang == nil && _userLangExt != userLangName)
        if langChanged {
            _lang = lang
            _userLangExt = userLangName
            doNotify(.language)
            
            _needLexer = true
            doNotify(.lexing)
        }
    }
    
    // MARK: - Translation of setUnicodeMode (Buffer.cpp line 270)
    func setUnicodeMode(_ mode: FileEncoding) {
        if _unicodeMode != mode {
            _unicodeMode = mode
            doNotify(.unicode)
        }
    }
    
    // MARK: - Translation of setEncoding (Buffer.cpp line 283)
    func setEncoding(_ encoding: Int) {
        if _encoding != encoding {
            _encoding = encoding
            
            if _encoding == -1 {
                _unicodeMode = .utf8
            }
            doNotify(.unicode)
        }
    }
    
    // MARK: - Translation of increaseRecentTag (Buffer.h line 177)
    func increaseRecentTag() {
        Document._recentTagCtr += 1
        _recentTag = Document._recentTagCtr
        doNotify(.recentTag)
    }
    
    // MARK: - Translation of doNotify (Buffer.cpp line 305)
    private func doNotify(_ mask: BufferStatusInfo) {
        // In C++ this notifies the FileManager
        // In Swift we can use NotificationCenter or delegates
        NotificationCenter.default.post(
            name: .bufferChanged,
            object: self,
            userInfo: ["mask": mask]
        )
    }
    
    // MARK: - Reference counting (Translation of addReference/removeReference)
    func addReference(identifier: Int) -> Int {
        _references += 1
        
        if _refPositions[identifier] == nil {
            _refPositions[identifier] = DocumentPosition()
            _foldStates[identifier] = []
        }
        
        return _references
    }
    
    func removeReference(identifier: Int) -> Int {
        _references -= 1
        
        if _references == 0 {
            // Purge document
            _refPositions.removeAll()
            _foldStates.removeAll()
        } else {
            _refPositions.removeValue(forKey: identifier)
            _foldStates.removeValue(forKey: identifier)
        }
        
        return _references
    }
    
    // MARK: - Position management (Translation of setPosition/getPosition)
    func setPosition(_ pos: DocumentPosition, identifier: Int) {
        _refPositions[identifier] = pos
    }
    
    func getPosition(identifier: Int) -> DocumentPosition? {
        return _refPositions[identifier]
    }
    
    // MARK: - Getters matching Buffer.h
    var fullPathName: String { _fullPathName }
    var fileName: String { _fileName }
    var id: UUID { _id }
    var recentTag: Int { _recentTag }
    var isDirty: Bool { _isDirty }
    var isReadOnly: Bool { _isUserReadOnly || _isFileReadOnly }
    var isUntitled: Bool { _currentStatus.contains(.unnamed) }
    var isFromNetwork: Bool { _isFromNetwork }
    var isInaccessible: Bool { _isInaccessible }
    var fileReadOnly: Bool { _isFileReadOnly }
    var userReadOnly: Bool { _isUserReadOnly }
    var eolFormat: EOLType { _eolFormat }
    var langType: LanguageDefinition? { _lang }
    var unicodeMode: FileEncoding { _unicodeMode }
    var encodingInt: Int { _encoding }  // Renamed to avoid conflict with encoding property
    var status: DocFileStatus { _currentStatus }
    var document: ScintillaDocument { _doc }
    var needsLexing: Bool { _needLexer }
    var needReload: Bool { _needReloading }
    var tabCreatedTimeString: String { _tabCreatedTimeString }
    var isUntitledTabRenamed: Bool { _isUntitledTabRenamed }
    
    // MARK: - Setters matching Buffer.h
    func setInaccessibility(_ val: Bool) {
        _isInaccessible = val
    }
    
    func setFileReadOnly(_ ro: Bool) {
        _isFileReadOnly = ro
        doNotify(.readonly)
    }
    
    func setUserReadOnly(_ ro: Bool) {
        _isUserReadOnly = ro
        doNotify(.readonly)
    }
    
    func setEolFormat(_ format: EOLType) {
        _eolFormat = format
        doNotify(.format)
    }
    
    func setNeedsLexing(_ lex: Bool) {
        _needLexer = lex
        doNotify(.lexing)
    }
    
    func setUntitledTabRenamedStatus(_ isRenamed: Bool) {
        _isUntitledTabRenamed = isRenamed
    }
    
    func setNeedReload(_ reload: Bool) {
        _needReloading = reload
    }
    
    // MARK: - Compatibility methods for UI
    func updateContent(_ newContent: String) {
        content = newContent
    }
    
    func forceUpdateContent(_ newContent: String, encoding: FileEncoding, eol: EOLType) {
        content = newContent
        _unicodeMode = encoding
        _eolFormat = eol
        _isDirty = false
    }
    
    func handleExternalDeletion() {
        _currentStatus = .deleted
        doNotify(.status)
    }
    
    // MARK: - Save/Load operations for compatibility
    func save() async throws {
        guard let url = fileURL else {
            throw DocumentError.noFilePath
        }
        
        // Create backup before saving
        BackupManager.shared.createBackup(for: self)
        
        let contentToSave = content
        let encodingToUse = _unicodeMode
        try await Task {
            try await MainActor.run {
                try EncodingManager.shared.writeFile(content: contentToSave, to: url, encoding: encodingToUse)
            }
        }.value
        markAsSaved()
    }
    
    func saveAs(to url: URL) async throws {
        let oldURL = fileURL
        fileURL = url
        _fileName = url.lastPathComponent
        
        // Use the LanguageManager to detect language
        if let nppLanguage = LanguageManager.shared.detectLanguage(for: url.lastPathComponent) {
            _lang = nppLanguage.toLanguageDefinition()
        }
        
        // Update file monitoring if URL changed
        if oldURL != url {
            if let monitor = fileMonitor {
                monitor.updateFileURL(url)
            } else {
                startFileMonitoring()
            }
        }
        
        try await save()
    }
    
    static func open(from url: URL) async throws -> Document {
        // Read file with encoding and EOL detection on background thread
        let (content, detectedEncoding, detectedEOL) = try await Task.detached {
            // Encoding detection must happen on main thread
            let result = try await MainActor.run {
                let settings = AppSettings.shared
                return try EncodingManager.shared.readFile(at: url, openAnsiAsUtf8: settings.openAnsiAsUtf8)
            }
            return result
        }.value
        
        // Create Document on main thread
        return await MainActor.run {
            let doc = Document(content: content, filePath: url)
            doc._unicodeMode = detectedEncoding
            doc._eolFormat = detectedEOL
            return doc
        }
    }
    
    func markAsSaved() {
        _isDirty = false
        
        // Restart file monitoring after save to update modification date
        if fileMonitor != nil {
            startFileMonitoring()
        }
    }
    
    // Convert EOL in current document
    func convertEOL(to newEOL: EOLType) {
        let convertedContent = EncodingManager.shared.convertEOL(in: content, to: newEOL)
        content = convertedContent
        _eolFormat = newEOL
        _isDirty = true
    }
    
    // MARK: - File monitoring support
    private func startFileMonitoring() {
        guard let fileURL = fileURL else { return }
        
        stopFileMonitoring() // Stop any existing monitoring
        fileMonitor = FileMonitor(fileURL: fileURL, document: self)
        fileMonitor?.start()
    }
    
    private func stopFileMonitoring() {
        fileMonitor?.stop()
        fileMonitor = nil
    }
    
    @Published var caretPosition: Int = 0
    @Published var scrollPosition: CGPoint = .zero
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var foldingState = FoldingState()
    @Published var documentScrollPosition: NSPoint = .zero
    @Published var documentSelectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var documentVisibleRect: NSRect = .zero
    
    // Syntax highlighter
    let syntaxHighlighter = SyntaxHighlighter()
    
    // File monitoring support
    private var fileMonitor: FileMonitor?
    
    // MARK: - Document State Management (Port of ScintillaEditView::saveCurrentPos)
    
    /// Save the current state from the text view (before switching tabs)
    /// Port of ScintillaEditView::saveCurrentPos() from ScintillaEditView.cpp
    func saveState(from textView: NSTextView) {
        documentSelectedRange = textView.selectedRange()
        if let scrollView = textView.enclosingScrollView {
            documentScrollPosition = scrollView.contentView.bounds.origin
        }
        documentVisibleRect = textView.visibleRect
        
        // Update content from text view
        let currentContent = textView.string
        if currentContent != content {
            updateContent(currentContent)
        }
    }
    
    /// Restore the saved state to the text view (after switching to this tab)
    /// Port of ScintillaEditView::restoreCurrentPos() from ScintillaEditView.cpp
    func restoreState(to textView: NSTextView) {
        // Restore selection
        if documentSelectedRange.location <= textView.string.count {
            textView.setSelectedRange(documentSelectedRange)
        }
        
        // Restore scroll position
        if let scrollView = textView.enclosingScrollView {
            scrollView.contentView.scroll(to: documentScrollPosition)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
    
    /// Activate this document in the text view (port of ScintillaEditView::activateBuffer)
    /// This is the CRITICAL method that performs the document swap
    func activate(in textView: NSTextView, restorePosition: Bool = false) {
        // Port of SCI_SETDOCPOINTER - swap the entire text storage
        if let layoutManager = textView.layoutManager {
            // Remove text view from old text storage
            textView.textStorage?.removeLayoutManager(layoutManager)
            
            // Attach to new text storage
            self.textStorage.addLayoutManager(layoutManager)
        }
        
        // Apply language-specific settings (port of defineDocType)
        if let language = self._lang {
            applySyntaxHighlighting(to: textView, language: language)
        }
        
        // Only restore saved state when explicitly requested (e.g., when switching tabs)
        if restorePosition {
            restoreState(to: textView)
        }
    }
    
    private func applySyntaxHighlighting(to textView: NSTextView, language: LanguageDefinition) {
        // This will be handled by the syntax highlighter
        // For now, just ensure the text storage has the correct attributes
        if AppSettings.shared.syntaxHighlighting {
            // Apply syntax highlighting to our text storage
            syntaxHighlighter.highlight(textStorage: textStorage, language: language)
        }
    }
    
    deinit {
        // Explicitly stop file monitoring to prevent crashes
        fileMonitor?.stop()
        fileMonitor = nil
    }
}

// MARK: - Notification extension
extension Notification.Name {
    static let bufferChanged = Notification.Name("BufferChanged")
}

// MARK: - DocumentError enum
enum DocumentError: LocalizedError {
    case noFilePath
    case saveError(String)
    case openError(String)
    
    var errorDescription: String? {
        switch self {
        case .noFilePath:
            return "No file path specified"
        case .saveError(let message):
            return "Save error: \(message)"
        case .openError(let message):
            return "Open error: \(message)"
        }
    }
}