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

    // F39: set at open when the file had to be decoded with lossy U+FFFD substitution. While
    // true (and not yet acknowledged) the interactive save paths warn before overwriting the
    // original bytes, so a mis-decoded binary/mixed file cannot be silently corrupted on the
    // first Cmd+S.
    private(set) var lossyDecode: Bool = false
    var lossyOverwriteAcknowledged: Bool = false
    
    // True only while a programmatic full-replace (open / reload / EOL convert /
    // forceUpdateContent) is rewriting textStorage and rebuilding _doc.cb. The storage
    // delegate and applyIncrementalEdit no-op while it is set, so the delta path does not
    // double-apply on top of the full _doc.setText rebuild (F09).
    private var isApplyingProgrammaticEdit = false

    // Cached OptimizedSettings so the SwiftUI render/edit hot path never recomputes them
    // (the computation stats the file). Invalidated on open/save (F13).
    private var _cachedOptimizedSettings: OptimizedSettings?

    // F16: `content` is a DERIVED view of the single canonical text store, not a second
    // resident copy. The bytes live once in `textStorage` (the NSTextStorage the live
    // NSTextView edits in place, the SCI_SETDOCPOINTER model), mirrored by the _doc.cb line
    // index. Reading `content` bridges textStorage's string on demand (save, search, fold
    // detection, session snapshot). This removes the whole-document resident allocation the
    // old stored @Published property kept, and the per-keystroke textView.string bridge plus
    // O(n) compare that refreshed it. Faithful to the C++ Buffer, which holds only a Document
    // handle; the text exists once in Scintilla's CellBuffer (Buffer.h:28,418, CellBuffer.cxx:350).
    var content: String {
        get { textStorage.string }
        // PROGRAMMATIC full-replace path ONLY (open / reload / EOL convert / forceUpdateContent /
        // find-replace / session restore). Typing never calls this: the NSTextView mutates
        // textStorage directly and the storage delegate feeds the delta to _doc.cb (see
        // noteTextEdited / applyIncrementalEdit). Mirrors the old didSet programmatic branch.
        set {
            guard textStorage.string != newValue else { return }
            setDirty(true)
            isApplyingProgrammaticEdit = true
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: newValue)
            textStorage.endEditing()
            _doc.setText(newValue)
            isApplyingProgrammaticEdit = false
            // Publish a lightweight change signal so SwiftUI observers refresh without
            // comparing the whole string.
            textVersion &+= 1
        }
    }

    // F16: monotonically bumped on every text change (typing via noteTextEdited, programmatic
    // via the content setter). @Published so SwiftUI observers key `.onChange` off an O(1) Int
    // instead of the whole `content` string. Replaces the reactivity the stored @Published
    // `content` used to provide; document.objectWillChange still fires on each edit so
    // @ObservedObject views re-evaluate.
    @Published private(set) var textVersion: Int = 0
    
    // NSTextStorage for AppKit integration
    let textStorage: NSTextStorage

    // Undo history lives in the Document, not the shared view (Scintilla model: each
    // Document owns its undo; SCI_SETDOCPOINTER swaps to the new doc's history, and
    // EMPTYUNDOBUFFER -> Document::DeleteUndoHistory clears it, Editor.cxx:6425). The
    // Coordinator returns this from undoManager(for:) so a tab switch swaps undo and
    // Cmd+Z can never replay another document's edits (F04).
    let undoManager: UndoManager = {
        let manager = UndoManager()
        manager.levelsOfUndo = 100
        return manager
    }()
    
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
        // F16: `content` is now derived from textStorage (the single canonical store), which
        // NSTextStorage(string:) above already holds. No separate resident copy to assign.

        // Initialize with defaults
        self._fileManager = nil
        self._id = UUID()
        self._doc = ScintillaDocument()
        // The mirror CellBuffer is a text + line-index mirror of NSTextStorage; undo is
        // owned solely by NSTextView.undoManager (F04). The per-keystroke incremental edits
        // (applyIncrementalEdit -> deleteChars/insertString) would otherwise append an
        // Action per keystroke to _doc.cb.undoHistory, which nothing ever consumes, growing
        // without bound over a long session. Turn undo collection OFF on the mirror.
        // Translation of CellBuffer::SetUndoCollection(false) (CellBuffer.cxx:1112-1116).
        self._doc.cb.isCollectingUndo = false
        self._currentStatus = filePath == nil ? .unnamed : .regular
        // Compute the large-file flag ONCE here (equivalent to
        // PerformanceManager.isLargeFile(size:), ViewModels/PerformanceManager.swift:17) so
        // the edit/render hot path never recomputes content.utf8.count (F13).
        // Document.open overrides this from the on-disk file size for a loaded file.
        self._isLargeFile = PerformanceManager.shared.isLargeFile(size: Int64(content.utf8.count))
        
        // Set file name if provided
        if let filePath = filePath {
            setFileName(filePath.path)
        } else {
            // Unnamed document. Sane default title; DocumentManager.createNewDocument assigns the
            // real reuse-lowest-free number via setUntitledName (port of Buffer.cpp:1680-1690).
            _fileName = "new 1"
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

    // Port of Buffer.cpp:1680-1690: an untitled buffer is titled UNTITLED_STR ("new ") + its number.
    func setUntitledName(number: Int) {
        _fileName = "new \(number)"
    }
    
    // The live external-change watch is FileMonitor (Services/FileMonitor.swift), which owns the
    // DispatchSource, the checkFileState / doReloadOrNot prompt (F38) and the reload (F42/F44).
    // The former Document.checkFileState()/reload() pair here was DEAD (no callers) and its
    // reload() had a real desync bug - it rewrote only _doc.cb, never textStorage/content, so the
    // getter would go stale - which is exactly the trap the audit flagged. Deleted so nothing can
    // resurrect it; the correct, view-state-preserving reload is
    // forceUpdateContentPreservingViewState below.

    // MARK: - Translation of setDirty (Buffer.cpp line 297)
    func setDirty(_ dirty: Bool) {
        let wasDirty = _isDirty
        _isDirty = dirty

        if wasDirty != dirty {
            objectWillChange.send()  // _isDirty is read by the tab "modified" dot and status bar
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
            objectWillChange.send()   // the Language menu checkmark reflects the active language

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

    // MARK: - User-driven encoding change (F34 escape hatch)

    /// Change the buffer's encoding from the UI (the status-bar encoding menu, and the "Save as
    /// UTF-8" offer in the save-error dialog). The buffer's encoding is a user-mutable property
    /// in Notepad++ (Buffer.cpp:270 setUnicodeMode, reachable from the Encoding menu); changing
    /// it marks the buffer dirty (Buffer.cpp:297 setDirty) so the NEXT save writes with the new
    /// encoding, giving a way out when the current encoding cannot represent typed characters.
    func changeEncoding(_ newEncoding: FileEncoding) {
        guard _unicodeMode != newEncoding else { return }
        _unicodeMode = newEncoding
        objectWillChange.send()   // the status bar shows the encoding name
        setDirty(true)            // re-save needed so the file is rewritten with the new encoding
        doNotify(.unicode)
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
        objectWillChange.send()  // _eolFormat is shown in the status bar
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

    // F16: the live NSTextView has just mutated `textStorage` (the single canonical store) in
    // place; the storage delegate already applied the exact insert/delete delta to the _doc.cb
    // mirror (applyIncrementalEdit). `content` is derived from textStorage, so there is no
    // separate copy to refresh here. Mark the buffer dirty and publish the change signal so
    // SwiftUI observers (gutter line count, fold-detection debounce) refresh, WITHOUT
    // materializing or comparing the whole document string per keystroke. Removes the last
    // per-keystroke O(document) cost on the content path.
    func noteTextEdited() {
        setDirty(true)
        textVersion &+= 1
    }

    // F16: programmatic full-replace entry point (find/replace). Routes through the `content`
    // setter, which rewrites textStorage whole and rebuilds _doc.cb. The typing path uses
    // noteTextEdited() instead and never materializes the whole string.
    func updateContent(_ newContent: String) {
        content = newContent
    }
    
    func forceUpdateContent(_ newContent: String, encoding: FileEncoding, eol: EOLType) {
        content = newContent
        _unicodeMode = encoding
        _eolFormat = eol
        _isDirty = false
        // A reload/replace from disk resolves any lossy-decode warning: the buffer now matches
        // the file, so a later save is no longer overwriting mis-decoded bytes (F39).
        lossyDecode = false
        lossyOverwriteAcknowledged = false
        invalidateOptimizedSettings()  // content (size) may have changed (F13)
    }

    /// Reload/replace this document's whole content while preserving the caret and scroll
    /// position of the live editor (F44). Port of Notepad++ doReload, which brackets the
    /// document-pointer swap with saveCurrentPos()/restoreCurrentPosPreStep() (NppIO.cpp:603/629;
    /// ScintillaEditView.cpp:2202 saves the anchor/caret/first-visible-line, :2230 restores them).
    /// forceUpdateContent alone rewrites the entire NSTextStorage, which drops the selection and
    /// leaves the caret at an arbitrary spot with no scroll restore. Positions are captured/
    /// restored only when the live active text view is actually showing THIS document's storage
    /// (a background tab reloaded on disk keeps its saved tab-switch position instead); everything
    /// is clamped to the new length so a shrunk file cannot raise NSRangeException.
    func forceUpdateContentPreservingViewState(_ newContent: String, encoding: FileEncoding, eol: EOLType) {
        let textView = DocumentTextEditor.activeTextView
        let showsThisDocument = (textView?.textStorage === textStorage)

        var savedSelection: NSRange?
        var savedScrollOrigin: NSPoint?
        if showsThisDocument, let textView {
            savedSelection = textView.selectedRange()
            savedScrollOrigin = textView.enclosingScrollView?.contentView.bounds.origin
        }

        forceUpdateContent(newContent, encoding: encoding, eol: eol)

        if showsThisDocument, let textView {
            let newLength = (textView.string as NSString).length
            if let selection = savedSelection {
                let clampedLocation = min(selection.location, newLength)
                let clampedLength = min(selection.length, newLength - clampedLocation)
                textView.setSelectedRange(NSRange(location: clampedLocation, length: clampedLength))
            }
            if let origin = savedScrollOrigin, let scrollView = textView.enclosingScrollView {
                scrollView.contentView.scroll(to: origin)
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
            // Keep the saved tab-switch state in step so a later tab swap restores the same spot.
            documentSelectedRange = textView.selectedRange()
            if let scrollView = textView.enclosingScrollView {
                documentScrollPosition = scrollView.contentView.bounds.origin
            }
        }
    }
    
    func handleExternalDeletion() {
        _currentStatus = .deleted
        doNotify(.status)
    }

    /// Reveal (select + centre) a range in the live editor once this document is the one shown.
    /// F50: Find in Files activation opens the file in a tab and jumps to the matched line, like
    /// Notepad++ opening the result inside the editor and centring the found section
    /// (FindReplaceDlg.cpp:614/637/663). If this document's storage is already on screen the reveal
    /// happens immediately; otherwise it is parked in pendingRevealRange and applied by
    /// DocumentTextEditor.updateNSView right after the tab swap installs this document's storage.
    func revealRange(_ range: NSRange) {
        if let textView = DocumentTextEditor.activeTextView,
           textView.textStorage === textStorage {
            DocumentTextEditor.reveal(range, in: textView)
            textView.window?.makeFirstResponder(textView)
        } else {
            pendingRevealRange = range
        }
    }

    // MARK: - Incremental CellBuffer sync (F09)

    /// Apply an incremental edit (delivered by the live NSTextStorage delegate) to the
    /// CellBuffer so it stays in perfect sync WITHOUT a full re-ingest. This is the exact
    /// Scintilla notification point: an edit is a delete of the replaced span followed by an
    /// insert of the new text at the same position, mutating the CellBuffer in place
    /// (CellBuffer.cxx BasicDeleteChars :1011 then BasicInsertString :840; Scintilla never
    /// rebuilds the whole buffer on an edit). `range` and `delta` are UTF-16 (NSTextStorage)
    /// units, the same coordinate space CellBuffer now stores (F09/F15).
    func applyIncrementalEdit(range: NSRange, changeInLength delta: Int, newText: NSString) {
        // Skip while a programmatic full-replace is rebuilding _doc via setText, so the
        // storage edit it triggers does not double-apply on top of that rebuild.
        guard !isApplyingProgrammaticEdit else { return }

        let start = range.location
        let oldLen = range.length - delta   // characters that were there before the edit
        // F51: capture line geometry BEFORE mutating _doc.cb so bookmark line indices can be shifted
        // to track whole lines inserted/removed above them (Scintilla LineMarkers InsertLine/RemoveLine,
        // PerLine.h:41). Guarded on a non-empty bookmark set so the typing hot path pays nothing normally.
        let trackBookmarks = !bookmarkedLines.isEmpty
        let editLine = trackBookmarks ? _doc.cb.lineFromPosition(start) : 0
        let linesBefore = trackBookmarks ? _doc.cb.lines : 0
        if oldLen > 0 {
            _doc.cb.deleteChars(position: start, deleteLength: oldLen)
        }
        if range.length > 0 {
            _doc.cb.insertString(position: start, s: newText.substring(with: range))
        }
        if trackBookmarks {
            adjustBookmarks(afterEditStartingAtLine: editLine, lineDelta: _doc.cb.lines - linesBefore)
        }
    }

    // MARK: - Status / gutter readouts from the CellBuffer index (F13)

    /// Number of lines in the document. O(1): the CellBuffer keeps a line-start vector
    /// (CellBuffer.cxx:617 Lines() returns the line count directly). Consumed by the
    /// line-number gutter; keep this name.
    var lineCount: Int { _doc.cb.lines }

    /// The caret's 1-based (line, column) for the status bar, from the CellBuffer index
    /// rather than by splitting the whole text. Mirrors Notepad++ reading the caret line via
    /// SCI_LINEFROMPOSITION(SCI_GETCURRENTPOS) and the column via SCI_GETCOLUMN. `caretPosition`
    /// is a UTF-16 offset (selectedRange location), the same space CellBuffer
    /// lineFromPosition/lineStart use (CellBuffer.cxx:605 LineFromPosition, :569 LineStart).
    /// O(log n) binary search + O(1).
    var statusLineColumn: (line: Int, column: Int) {
        let p = caretPosition
        let l = _doc.cb.lineFromPosition(p)
        return (l + 1, p - _doc.cb.lineStart(l) + 1)
    }

    // MARK: - Line-index helpers for the ruler gutter, folding, bookmarks (F61/F19/F51)

    /// 0-based document line containing a UTF-16 character position. O(log n) binary search over the
    /// CellBuffer line-start vector (CellBuffer.cxx:605 LineFromPosition). Used by the NSRulerView
    /// line-number gutter, the folding layout-manager delegate, and bookmark line resolution.
    func lineIndex(forCharacterAt position: Int) -> Int { _doc.cb.lineFromPosition(position) }

    /// UTF-16 start offset of a 0-based line (CellBuffer.cxx:569 LineStart). O(1).
    func lineStartPosition(_ line: Int) -> Int { _doc.cb.lineStart(line) }

    /// UTF-16 end offset (before the EOL) of a 0-based line (CellBuffer.cxx:578 LineEnd). O(1).
    func lineEndPosition(_ line: Int) -> Int { _doc.cb.lineEnd(line) }

    // MARK: - Bookmarks (F51)

    /// Bookmarked lines for THIS document (0-based line indices). Port of Scintilla line markers
    /// (MARK_BOOKMARK = 20), which live in the document's LineMarkers (PerLine), NOT in the view, so
    /// they swap with SCI_SETDOCPOINTER and survive edits. @Published so the ruler repaints its
    /// bookmark glyphs. Untitled documents can be bookmarked too (unlike a filePath-keyed store).
    @Published private(set) var bookmarkedLines: Set<Int> = []

    /// Toggle the bookmark on a 0-based line. Port of Notepad_plus::bookmarkToggle (Notepad_plus.h:547):
    /// present -> bookmarkDelete, else bookmarkAdd (Notepad_plus.h:526-545, SCI_MARKERGET/ADD/DELETE).
    func toggleBookmark(atLine line: Int) {
        guard line >= 0, line < max(lineCount, 1) else { return }
        if bookmarkedLines.contains(line) {
            bookmarkedLines.remove(line)
        } else {
            bookmarkedLines.insert(line)
        }
    }

    func isBookmarked(line: Int) -> Bool { bookmarkedLines.contains(line) }

    /// Clear every bookmark on this document. Port of bookmarkClearAll (Notepad_plus.h:558,
    /// SCI_MARKERDELETEALL, MARK_BOOKMARK).
    func clearBookmarks() {
        guard !bookmarkedLines.isEmpty else { return }
        bookmarkedLines = []
    }

    /// Next/previous bookmarked line relative to a 0-based line, with wraparound. Port of
    /// Notepad_plus::bookmarkNext (Notepad_plus.cpp:5143): forward scans from line+1 then wraps to the
    /// top (SCI_MARKERNEXT from 0); backward scans from line-1 then wraps to the bottom
    /// (SCI_MARKERPREVIOUS from last line). Returns nil only when there are no bookmarks.
    func bookmarkLine(after line: Int, forward: Bool) -> Int? {
        guard !bookmarkedLines.isEmpty else { return nil }
        let sorted = bookmarkedLines.sorted()
        if forward {
            return sorted.first(where: { $0 > line }) ?? sorted.first
        } else {
            return sorted.last(where: { $0 < line }) ?? sorted.last
        }
    }

    /// Shift bookmark line indices when an edit inserts/deletes whole lines above them, mirroring
    /// Scintilla's LineMarkers InsertLine/RemoveLine (PerLine.h:41), which splice marker slots so a
    /// bookmark stays on its logical line after edits elsewhere. Zero cost when no bookmarks exist.
    fileprivate func adjustBookmarks(afterEditStartingAtLine editLine: Int, lineDelta: Int) {
        guard lineDelta != 0, !bookmarkedLines.isEmpty else { return }
        var shifted = Set<Int>()
        for l in bookmarkedLines {
            if l <= editLine {
                shifted.insert(l)
            } else {
                let moved = l + lineDelta
                if moved > editLine { shifted.insert(moved) }
                // A bookmark whose line was swallowed by a deletion collapsing onto editLine is dropped.
            }
        }
        if shifted != bookmarkedLines { bookmarkedLines = shifted }
    }

    // MARK: - Cached performance gates (F13)

    /// The document's OptimizedSettings, computed once and cached. The previous code called
    /// this on every SwiftUI body render (per keystroke), and the computation did a
    /// synchronous `attributesOfItem` disk stat each time. Caching it (invalidated on
    /// open/save) keeps the render path off the file system.
    func getOptimizedSettings() -> OptimizedSettings {
        if let cached = _cachedOptimizedSettings {
            return cached
        }
        let computed = PerformanceManager.shared.getOptimizedSettings(for: self)
        _cachedOptimizedSettings = computed
        return computed
    }

    func invalidateOptimizedSettings() {
        _cachedOptimizedSettings = nil
    }

    /// Whether this document counts as "large" for the performance gates. Computed ONCE at
    /// open/init (from the content byte count for an unsaved buffer, or the on-disk file
    /// size for a file) and stored, so the edit/render hot path never recomputes
    /// content.utf8.count (an O(n) pass) nor stats the file. Equivalent to
    /// PerformanceManager.isLargeFile(size:) (ViewModels/PerformanceManager.swift:17).
    var isLargeFile: Bool { _isLargeFile }
    
    // MARK: - Save/Load operations for compatibility
    func save() async throws {
        guard let url = fileURL else {
            throw DocumentError.noFilePath
        }

        // Main-actor work: read the buffer and settings, then compute the exact bytes to write
        // and the backup destination. Apply the buffer's EOL format at write time (Scintilla
        // model): the editor keeps text LF-normalised while editing, so without this, lines
        // opened as CRLF plus newly-typed LF lines were saved with mixed endings.
        let contentToSave = EncodingManager.shared.convertEOL(in: content, to: _eolFormat)
        let encodingToUse = _unicodeMode
        // F37: destination for a copy of the PREVIOUS on-disk version (nil when backup is off).
        let backupURL = BackupManager.shared.backupDestination(for: self)

        // F41: everything below runs off the main actor - the strings are value copies and the
        // file I/O has no UI dependency, so the UI no longer freezes for the write's duration.
        // The former `Task { MainActor.run { writeFile } }` wrapper kept the write on main. The
        // detached closure touches only Sendable values and the nonisolated static copy/write
        // helpers; the backup-failure REPORT is hopped back to the main actor below.
        let backupFailure: String? = try await Task.detached(priority: .userInitiated) { () -> String? in
            var backupFailure: String? = nil
            // F37: copy the previous on-disk file to the backup BEFORE overwriting it, so the .bak
            // is the prior version and Cmd+S can be rolled back. Copy-before-write translation of
            // NppIO.cpp:1858 CopyFileEx(fn, fn_bak) which runs before doSave. Skipped on the first
            // save (no file yet). A backup failure is surfaced (F40) but must NOT block saving the
            // user's content, so it does not abort the write - it is reported afterwards.
            if let backupURL {
                do {
                    try BackupManager.copyPreviousVersion(from: url, to: backupURL)
                } catch {
                    backupFailure = error.localizedDescription
                }
            }
            // F36: atomic write + free-space guard (both inside writeFile). A write failure throws
            // and propagates to the caller with the original file left intact.
            try EncodingManager.shared.writeFile(content: contentToSave, to: url, encoding: encodingToUse)
            return backupFailure
        }.value

        if let backupFailure {
            BackupManager.shared.reportBackupFailure(fileName: url.lastPathComponent, path: url.path, message: backupFailure)
        }

        markAsSaved()
    }

    func saveAs(to url: URL) async throws {
        // F43: write the bytes to the NEW path FIRST and mutate the document identity (path,
        // name, language, monitor) only AFTER the write succeeds. Translation of Buffer.cpp:1563-
        // 1569 (early return SaveWritingFailed before any buffer mutation) and :1598 (setFileName
        // only after a successful write). The old order set fileURL/_fileName before save(), so a
        // failed write (an un-encodable character, disk full, permissions) left the tab pointing
        // at the unwritten target and Cmd+S then retried the wrong path, losing the original
        // association. Save As does not take the pre-save .bak (Notepad++ only backs up on Save).
        let contentToSave = EncodingManager.shared.convertEOL(in: content, to: _eolFormat)
        let encodingToUse = _unicodeMode
        try await Task.detached(priority: .userInitiated) {
            try EncodingManager.shared.writeFile(content: contentToSave, to: url, encoding: encodingToUse)
        }.value

        // Write succeeded: adopt the new identity now.
        let oldURL = fileURL
        fileURL = url
        _fileName = url.lastPathComponent
        invalidateOptimizedSettings()  // url changed, large-file gate may differ (F13)

        // Use the LanguageManager to detect language
        if let nppLanguage = LanguageManager.shared.detectLanguage(for: url.lastPathComponent) {
            _lang = nppLanguage.toLanguageDefinition()
        }

        // Update file monitoring for the new URL (F38: also starts one if none existed, e.g. a
        // formerly untitled buffer saved for the first time).
        if oldURL != url {
            if let monitor = fileMonitor {
                monitor.updateFileURL(url)
            } else {
                beginFileMonitoring()
            }
        }

        markAsSaved()
    }

    static func open(from url: URL) async throws -> Document {
        // Read the setting on the main actor (Document.open is main-actor isolated), then
        // do the disk read, encoding detection, decode and EOL scan ENTIRELY off the main
        // actor. The previous code wrapped the read in `Task.detached { await
        // MainActor.run { ... } }`, which hopped straight back to the main actor because
        // EncodingManager was @MainActor-isolated, so the whole read still blocked the UI
        // for the full duration of the load (F26). EncodingManager.readFile and its
        // helpers are now `nonisolated` (they touch no UI state) so they run on the
        // detached task. Port of Notepad++ buffered load: file I/O and decoding never
        // block the editor (Buffer.cpp FileManager::loadFile :924 / loadFileData :1015).
        let openAnsiAsUtf8 = AppSettings.shared.openAnsiAsUtf8
        let (content, detectedEncoding, detectedEOL, lossy) = try await Task.detached(priority: .userInitiated) {
            try EncodingManager.shared.readFile(at: url, openAnsiAsUtf8: openAnsiAsUtf8)
        }.value

        // Back on the main actor: construct the Document with the finished strings.
        let doc = Document(content: content, filePath: url)
        doc._unicodeMode = detectedEncoding
        doc._eolFormat = detectedEOL
        // F39: remember a lossy (U+FFFD) decode so the first save warns before writing the
        // substitution back over the original bytes.
        doc.lossyDecode = lossy
        // Large-file flag from the on-disk file size (matches getOptimizedSettings for a
        // saved file); computed once at open, off the render path (F13).
        doc._isLargeFile = PerformanceManager.shared.isLargeFile(at: url)
        return doc
    }
    
    func markAsSaved() {
        _isDirty = false
        invalidateOptimizedSettings()  // save may change file size/url gate (F13)

        // Restart file monitoring after save to update modification date
        if fileMonitor != nil {
            startFileMonitoring()
        }
    }
    
    // Convert EOL in current document.
    // NSTextView normalises CR/CRLF to LF for display, so the EOL is tracked as a per-buffer
    // format flag and materialised at save time (see save()), matching the Scintilla model.
    // Rewriting the buffer with CR characters here had no visible effect and was lost on the
    // next edit, which is why the EOL Conversion menu appeared to do nothing.
    func convertEOL(to newEOL: EOLType) {
        guard _eolFormat != newEOL else { return }
        setEolFormat(newEOL)   // updates the status bar (doNotify(.format) + objectWillChange)
        setDirty(true)         // marks the buffer dirty so the change is saved
    }
    
    // MARK: - File monitoring support

    /// Begin watching this file for external changes. Called when a file is opened normally and
    /// after a Save As (F38). Gated on the "detect file changes" preference, matching Notepad++'s
    /// file auto-detection: when NppGUI._fileAutoDetection is cdDisabled (0x00) no monitoring or
    /// reload happens (NppConstants.h:188-194; the DOC_MODIFIED handling runs only when detection
    /// is enabled, Notepad_plus.cpp:6644). Before this, ONLY Save-As'd / re-saved buffers were ever
    /// monitored, so an external edit to a normally-opened file went unnoticed and Cmd+S silently
    /// overwrote it (Buffer.cpp:123,426 checkFileState runs for every file-backed buffer in N++).
    func beginFileMonitoring() {
        guard AppSettings.shared.detectFileChanges else { return }
        startFileMonitoring()
    }

    private func startFileMonitoring() {
        guard let fileURL = fileURL else { return }

        stopFileMonitoring() // Stop any existing monitoring
        fileMonitor = FileMonitor(fileURL: fileURL, document: self)
        // Do NOT call fileMonitor?.start() here. FileMonitor.init already starts monitoring exactly
        // once (init -> updateFileURL -> start()). Calling start() again armed a second DispatchSource
        // and orphaned the first, leaking one file descriptor per construction (F31). The init's
        // single start is the only one needed.
    }
    
    private func stopFileMonitoring() {
        fileMonitor?.stop()
        fileMonitor = nil
    }
    
    @Published var caretPosition: Int = 0
    // F50: a range for the live editor to select+centre once this document is the one on screen
    // (Find in Files result activation). Deliberately NOT @Published: it is consumed inside
    // DocumentTextEditor.updateNSView, and publishing from there would re-enter the view update.
    // Set via revealRange(_:); cleared by the editor after it applies it.
    var pendingRevealRange: NSRange?
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
    
    /// Save the current state from the text view (before switching tabs).
    /// Port of ScintillaEditView::saveCurrentPos (ScintillaEditView.cpp:2202-2224): it
    /// stores caret/anchor/scroll POSITIONS only and never copies text into the buffer,
    /// because the buffer the view points to is the single owner of the bytes. Copying
    /// textView.string here (the old behavior) let a desynced shared view write a foreign
    /// document's text into this document and mark it dirty (F02). Content reaches the
    /// document only through user edits (textDidChange -> updateContent), exactly as
    /// Scintilla mutates the pointed-to Document directly.
    func saveState(from textView: NSTextView) {
        documentSelectedRange = textView.selectedRange()
        if let scrollView = textView.enclosingScrollView {
            documentScrollPosition = scrollView.contentView.bounds.origin
        }
        documentVisibleRect = textView.visibleRect
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
        
        // Syntax highlighting is driven by the editor (DocumentTextEditor makeNSView /
        // updateNSView call highlightVisibleThenRest) so it can style the VISIBLE range
        // first and gate on the large-file optimized setting. It is no longer run here as
        // a whole-document pass on every doc-pointer swap (F25). The swap itself only moves
        // the layout manager; styling is picked up incrementally, as in Scintilla where
        // SCI_SETDOCPOINTER swaps documents and styling extends over the visible window.

        // Only restore saved state when explicitly requested (e.g., when switching tabs)
        if restorePosition {
            restoreState(to: textView)
        }
    }

    /// Style the document's text storage for a fresh open or a tab switch: the VISIBLE
    /// range synchronously so colors appear immediately, then the rest once, deferred, so
    /// neither blocks the open / tab switch. Faithful to Scintilla styling the visible
    /// window first (Editor.cxx:5413 StyleToPositionInView) and extending the styled
    /// region afterwards (Document.cxx:2616 EnsureStyledTo / idle styling). The internal
    /// highlight() self-gates on the syntax-highlighting setting.
    func highlightVisibleThenRest(in textView: NSTextView, language: LanguageDefinition) {
        let highlighter = self.syntaxHighlighter

        // Visible range now (nil before the view is laid out / in a window, e.g. at first
        // open, in which case only the deferred whole-document pass runs).
        if let visible = SyntaxHighlighter.visibleCharacterRange(of: textView), visible.length > 0 {
            highlighter.highlight(textStorage: textStorage, language: language, range: visible)
        }

        // Bring the rest of the document up to date once, deferred, off the open / swap
        // critical path. Styles the document's own storage even if the tab has since
        // switched away (harmless); skips only if the language changed meanwhile.
        let langName = language.name
        DispatchQueue.main.async { [weak self] in
            guard let self, self._lang?.name == langName else { return }
            highlighter.highlight(textStorage: self.textStorage, language: language)
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