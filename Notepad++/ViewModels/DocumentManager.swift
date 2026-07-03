//
//  DocumentManager.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    @Published var tabs: [EditorTab] = []
    @Published var activeTab: EditorTab?
    @Published var recentFiles: [URL] = []
    
    init() {
        loadRecentFiles()
        // Don't automatically create new document
        // Let the app decide based on launch context
    }
    
    func createNewDocument() {
        let document = Document()
        // Assign the untitled number BEFORE appending to tabs so the new document does not count
        // itself and receives the smallest free number (port of Buffer.cpp:1680-1690 newEmptyDocument
        // naming the buffer UNTITLED_STR + nextUntitledNewNumber()).
        document.setUntitledName(number: nextUntitledNewNumber())
        applyNewDocumentDefaults(to: document)
        let tab = EditorTab(document: document)
        tabs.append(tab)
        activeTab = tab
    }

    // Port of FileManager::nextUntitledNewNumber (Buffer.cpp:1633-1678): the smallest positive
    // integer not currently used by an open untitled "new N" buffer, so a closed number is reused.
    func nextUntitledNewNumber() -> Int {
        var used = Set<Int>()
        for tab in tabs where tab.document.isUntitled {
            if let n = Self.untitledNumber(fromName: tab.document.fileName) { used.insert(n) }
        }
        var number = 1
        while used.contains(number) { number += 1 }
        return number
    }

    // Parse "new N" -> N (N a positive integer), else nil. Mirrors Buffer.cpp:1645-1646 reading the
    // number that follows UNTITLED_STR in the untitled buffer's file name.
    static func untitledNumber(fromName name: String) -> Int? {
        guard name.hasPrefix("new ") else { return nil }
        let suffix = name.dropFirst(4)
        guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber), let n = Int(suffix) else { return nil }
        return n
    }

    // F54: apply the persisted New Document preferences (default encoding, line ending, language) to a
    // freshly created buffer. Previously these @AppStorage keys were written by the settings pane but
    // never read, so a user who chose Windows CRLF still got LF documents. Port of Notepad++ applying
    // NewDocDefaultSettings to every new buffer: EOL + encoding in the Buffer constructor
    // (Buffer.cpp:107 ndds._format / ._unicodeMode) and the language for a new empty document
    // (Buffer.cpp:1680 newBuf->_lang = ndds._lang).
    private func applyNewDocumentDefaults(to document: Document) {
        let settings = AppSettings.shared

        switch settings.defaultLineEnding {
        case .windows: document.eolType = .windows
        case .unix:    document.eolType = .unix
        case .mac:     document.eolType = .macos
        }

        document.encoding = Self.fileEncoding(forName: settings.defaultEncoding)

        if let language = LanguageManager.shared.languageDefinition(named: settings.defaultLanguage) {
            document.language = language
        }
    }

    // Map the New Document encoding picker tag (NewDocumentSettingsView) to the buffer UniMode. The
    // single-byte legacy encodings (ISO-8859-1, Windows-1252, MacRoman) collapse to ANSI, matching
    // Notepad++ treating a non-Unicode default as an 8-bit codepage buffer.
    static func fileEncoding(forName name: String) -> FileEncoding {
        switch name {
        case "UTF-8":     return .utf8
        case "UTF-8-BOM": return .utf8BOM
        case "UTF-16BE":  return .utf16BE
        case "UTF-16LE":  return .utf16LE
        case "ASCII":     return .ascii
        default:          return .ansi
        }
    }
    
    @MainActor
    func openDocument() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        // Notepad++ opens ANY file regardless of extension (default dialog filter
        // is "All types (*.*)"). An empty allowedContentTypes array applies no UTI
        // filter, so zip, binary, and extensionless files can all be selected.
        // The read path (EncodingManager.readFile) is binary-safe and never rejects
        // by extension, so any selected file opens.
        panel.allowedContentTypes = []
        panel.message = "Select files to open"
        
        let response = await panel.beginAsync()
        
        guard response == .OK else {
            // User cancelled
            return
        }
        
        for url in panel.urls {
            await openDocument(from: url)
        }
    }
    
    @MainActor
    func openDocument(from url: URL) async {
        // Check if document is already open
        if let existingTab = tabs.first(where: { $0.document.fileURL == url }) {
            activeTab = existingTab
            return
        }
        
        // Check if file is large and warn user
        if PerformanceManager.shared.isLargeFile(at: url) {
            let shouldContinue = await withCheckedContinuation { continuation in
                PerformanceManager.shared.showLargeFileWarning(for: url) { result in
                    continuation.resume(returning: result)
                }
            }
            
            guard shouldContinue else { return }
        }
        
        do {
            let document = try await Document.open(from: url)
            let tab = EditorTab(document: document)

            // Port of the single-clean-buffer replacement in loadBufferIntoView
            // (Notepad_plus.cpp:4730-4740): drop a lone clean untitled buffer so the opened
            // file replaces it instead of being appended beside it. Evaluated synchronously
            // right before the append so a Finder multi-select (several openDocument calls)
            // drops it at most once (F27).
            dropLoneCleanUntitledIfPresent()

            tabs.append(tab)
            activeTab = tab
            addToRecentFiles(url)

            // F38: watch files opened normally for external changes. Before this, only Save-As'd /
            // re-saved buffers were ever monitored, so a Finder/File>Open document could be
            // silently overwritten by Cmd+S after another program changed it on disk. In Notepad++
            // Buffer::checkFileState runs for every file-backed buffer (Buffer.cpp:123,426).
            document.beginFileMonitoring()
        } catch {
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Open Failed"
            alert.informativeText = "Could not open the document: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func saveDocument(_ tab: EditorTab) async {
        let document = tab.document

        if document.fileURL == nil {
            await saveDocumentAs(tab)
        } else {
            // F39: warn before the first save writes a lossy (U+FFFD) decode back over the file.
            guard confirmLossyOverwriteIfNeeded(document) else { return }
            do {
                try await document.save()
            } catch {
                await handleSaveError(error, for: document)
            }
        }
    }

    /// Handle a failed save. F34: an encoding-conversion failure must never be a dead end - offer
    /// to re-encode the buffer as UTF-8 and retry, matching Notepad++ where the buffer's encoding
    /// is a user-changeable property (Buffer.cpp setEncoding) and saving never hard-fails without
    /// an escape. Any other failure is surfaced with the original file left intact.
    private func handleSaveError(_ error: Error, for document: Document) async {
        if case EncodingError.conversionFailed = error {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = "\"\(document.fileName)\" contains characters that cannot be written in its current encoding (\(document.encoding.displayName)).\n\nSave it as UTF-8 instead?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save as UTF-8")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                document.changeEncoding(.utf8)
                do {
                    try await document.save()
                } catch {
                    presentSaveFailure(error, for: document)
                }
            }
            return
        }
        presentSaveFailure(error, for: document)
    }

    private func presentSaveFailure(_ error: Error, for document: Document) {
        let alert = NSAlert()
        alert.messageText = "Save Failed"
        if case EncodingError.notEnoughRoom = error {
            // F36: the atomic write + free-space guard left the original file untouched.
            alert.informativeText = "There is not enough free space on the disk to save \(document.fileName). The original file was not changed."
        } else {
            alert.informativeText = "Could not save \(document.fileName): \(error.localizedDescription)"
        }
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// F39: if the buffer was decoded lossily (undecodable bytes replaced with U+FFFD) and the user
    /// has not yet acknowledged it, warn before saving - the save would overwrite the original bytes
    /// with the mangled text. Returns true to proceed, false to abort the save.
    private func confirmLossyOverwriteIfNeeded(_ document: Document) -> Bool {
        guard document.lossyDecode, !document.lossyOverwriteAcknowledged else { return true }
        let alert = NSAlert()
        alert.messageText = "Possible Data Loss"
        alert.informativeText = "\"\(document.fileName)\" contained bytes that could not be decoded and were replaced with the Unicode replacement character (\u{FFFD}).\n\nSaving now overwrites the original file with the modified text. Save anyway?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save Anyway")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            document.lossyOverwriteAcknowledged = true
            return true
        }
        return false
    }
    
    @MainActor
    func saveDocumentAs(_ tab: EditorTab) async {
        let panel = NSSavePanel()
        // Notepad++ Save As allows any type (default filter "All types (*.*)"); an
        // empty array honors whatever extension the user types instead of forcing .txt.
        panel.allowedContentTypes = []
        panel.nameFieldStringValue = tab.document.fileName
        
        let response = await panel.beginAsync()
        
        guard response == .OK, let url = panel.url else {
            // User cancelled or panel error
            return
        }

        // F39: warn before writing a lossy (U+FFFD) decode back to disk.
        guard confirmLossyOverwriteIfNeeded(tab.document) else { return }

        do {
            try await tab.document.saveAs(to: url)
            addToRecentFiles(url)
        } catch {
            // F34: an encoding-conversion failure offers the UTF-8 escape hatch; other failures
            // leave the (untouched, per F43) original in place.
            await handleSaveError(error, for: tab.document)
        }
    }
    
    /// Translation of Notepad_plus.cpp doSaveOrNot (line 2414) + NppIO.cpp fileClose
    /// dirty-check (lines 1149-1171). Returns true if the buffer may be closed, false to
    /// abort closing (Cancel pressed, or a cancelled Save As).
    func confirmClose(_ tab: EditorTab) async -> Bool {
        let document = tab.document

        // NppIO.cpp:1149 - an empty untitled buffer closes silently (no prompt).
        if document.fileURL == nil && document.content.isEmpty {
            return true
        }

        // NppIO.cpp:1153 - only dirty buffers prompt.
        guard document.isModified else { return true }

        // Activate the buffer being asked about so the save sheet appears over the file it
        // names, not whatever tab happens to be frontmost. Notepad++ calls activateBuffer
        // (NppIO.cpp:1255, fileCloseAll) / switchToFile (Notepad_plus.cpp:5804) immediately
        // before doSaveOrNot; without it the quit and close-all loops prompted over an
        // unrelated document, often an empty untitled one (F29).
        activeTab = tab

        // Notepad_plus.cpp:2435-2447 doSaveOrNot - "Save"/"Save file \"...\"?" (Yes/No/Cancel).
        // Buttons are placed per macOS HIG (Save / Cancel / Don't Save).
        let alert = NSAlert()
        alert.messageText = "Save"
        alert.informativeText = "Save file \"\(document.fileName)\"?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")        // IDYES    -> .alertFirstButtonReturn
        alert.addButton(withTitle: "Cancel")      // IDCANCEL -> .alertSecondButtonReturn
        alert.addButton(withTitle: "Don't Save")  // IDNO     -> .alertThirdButtonReturn

        switch alert.runModal() {
        case .alertFirstButtonReturn:   // Save (IDYES) - NppIO.cpp:1158-1162
            await saveDocument(tab)
            // Still modified means the Save As panel was cancelled -> abort closing.
            return !document.isModified
        case .alertThirdButtonReturn:   // Don't Save (IDNO) - NppIO.cpp:1167, discard & continue
            return true
        default:                        // Cancel (IDCANCEL) - NppIO.cpp:1163, abort closing
            return false
        }
    }

    /// Loops the close confirmation over every dirty buffer for an app-wide quit.
    /// Returns false if the user cancels any prompt (terminate should be aborted).
    func confirmCloseAllForQuit() async -> Bool {
        for tab in tabs where tab.document.isModified {
            if await confirmClose(tab) == false { return false }
        }
        return true
    }

    /// Port of the tail of NppIO.cpp fileCloseAll (lines 1377-1394): once every dirty buffer
    /// has been resolved (saved or discarded), close all buffers and leave a single fresh
    /// empty untitled, matching Notepad++'s always-one-buffer invariant. The window-close
    /// path calls this after confirmCloseAllForQuit succeeds so documents the user already
    /// answered are actually gone and cannot be re-prompted by the next close, and so a warm
    /// Finder open starts from a clean untitled (F30).
    func resetToFreshUntitled() {
        tabs.removeAll()
        createNewDocument()
    }

    /// Port of the single-clean-buffer replacement in loadBufferIntoView
    /// (Notepad_plus.cpp:4730-4740): when exactly one tab is open and it is a clean
    /// (unmodified) untitled buffer, close it so a file being opened replaces it rather
    /// than being appended beside it. Notepad++ keeps the lone buffer only when
    /// `buf->isDirty() || !buf->isUntitled()`, i.e. it closes it iff clean AND untitled,
    /// with no content-emptiness test. Re-checking state on every call makes this
    /// idempotent for Finder multi-select: after the first file replaces the untitled,
    /// tabs[0] is titled and later files no longer match, so several files opening at once
    /// cannot each try to replace the lone untitled (F27).
    private func dropLoneCleanUntitledIfPresent() {
        guard tabs.count == 1,
              let onlyTab = tabs.first,
              onlyTab.document.fileURL == nil,
              !onlyTab.document.isModified else { return }
        tabs.removeAll()
    }

    /// Removes a tab from the array and re-selects a neighbour (no save prompt).
    private func removeTab(_ tab: EditorTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: index)

        if tabs.isEmpty {
            createNewDocument()
        } else if activeTab == tab {
            activeTab = tabs[max(0, index - 1)]
        }
    }

    func closeTab(_ tab: EditorTab) async {
        guard await confirmClose(tab) else { return }
        removeTab(tab)
    }
    
    func saveAllDocuments() async {
        for tab in tabs where tab.document.isModified {
            if tab.document.fileURL != nil {
                // F39: warn before a lossy-decode overwrite; F34: encoding failures get the escape hatch.
                guard confirmLossyOverwriteIfNeeded(tab.document) else { continue }
                do {
                    try await tab.document.save()
                } catch {
                    await handleSaveError(error, for: tab.document)
                }
            } else {
                // For untitled documents, show save dialog
                await saveDocumentAs(tab)
            }
        }
    }
    
    func closeAllTabs() async {
        // NppIO.cpp fileCloseAll loops doSaveOrNot over every dirty buffer; Cancel aborts all.
        for tab in tabs {
            guard await confirmClose(tab) else { return }
        }
        tabs.removeAll()
        createNewDocument()
    }

    func closeOtherTabs() async {
        guard let currentTab = activeTab else { return }
        for tab in tabs where tab != currentTab {
            guard await confirmClose(tab) else { return }
        }
        tabs = [currentTab]
        activeTab = currentTab
    }

    // Close all tabs to the left of the active tab
    func closeAllToLeft() async {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }

        for tab in tabs[..<currentIndex] {
            guard await confirmClose(tab) else { return }
        }
        tabs = Array(tabs[currentIndex...])
        activeTab = currentTab
    }

    // Close all tabs to the right of the active tab
    func closeAllToRight() async {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }

        for tab in tabs[(currentIndex + 1)...] {
            guard await confirmClose(tab) else { return }
        }
        tabs = Array(tabs[...currentIndex])
        activeTab = currentTab
    }

    // Close all unchanged (unmodified) tabs
    func closeAllUnchanged() {
        tabs = tabs.filter { $0.document.isModified }

        // If active tab was closed, select another one
        if let active = activeTab, !tabs.contains(active) {
            activeTab = tabs.first
        }

        // If no tabs left, create a new one
        if tabs.isEmpty {
            createNewDocument()
        }
    }

    // Move file to trash
    func moveToTrash() async {
        guard let activeTab = activeTab,
              let url = activeTab.document.fileURL else { return }

        // Confirm the destructive action (translation of NppIO.cpp fileDelete confirmation).
        let confirm = NSAlert()
        confirm.messageText = "Move to Trash"
        confirm.informativeText = "Are you sure you want to move \"\(activeTab.document.fileName)\" to the Trash?"
        confirm.alertStyle = .warning
        confirm.addButton(withTitle: "Move to Trash")
        confirm.addButton(withTitle: "Cancel")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            // The file is gone, so close the tab directly without a save prompt.
            removeTab(activeTab)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Move to Trash Failed"
            alert.informativeText = "Could not move the file to trash: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // Reload document from disk
    func reloadDocument() async {
        guard let activeTab = activeTab,
              let url = activeTab.document.fileURL else { return }

        // Check if document is modified and confirm
        if activeTab.document.isModified {
            let alert = NSAlert()
            alert.messageText = "Reload File"
            alert.informativeText = "This document has unsaved changes. Reloading will discard these changes. Continue?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Reload")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                return
            }
        }

        do {
            let newDocument = try await Document.open(from: url)
            // F44: replace the content while preserving the caret and scroll position, matching
            // Notepad++ doReload's saveCurrentPos/restoreCurrentPosPreStep bracket (NppIO.cpp:603/629).
            activeTab.document.forceUpdateContentPreservingViewState(
                newDocument.content,
                encoding: newDocument.encoding,
                eol: newDocument.eolType
            )
        } catch {
            let alert = NSAlert()
            alert.messageText = "Reload Failed"
            alert.informativeText = "Could not reload the document: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // Save a copy to a new location without changing the original file reference
    @MainActor
    func saveCopyAs(_ tab: EditorTab) async {
        let panel = NSSavePanel()
        // Notepad++ Save As allows any type (default filter "All types (*.*)"); an
        // empty array honors whatever extension the user types instead of forcing .txt.
        panel.allowedContentTypes = []
        panel.nameFieldStringValue = "Copy of " + tab.document.fileName

        let response = await panel.beginAsync()

        guard response == .OK, let url = panel.url else {
            return
        }

        do {
            // Save content to the new location without changing the document's file path.
            // Apply the buffer's EOL format at write time (Scintilla model) so the saved
            // copy has consistent line endings instead of mixed CRLF/LF.
            try EncodingManager.shared.writeFile(
                content: EncodingManager.shared.convertEOL(in: tab.document.content, to: tab.document.eolType),
                to: url,
                encoding: tab.document.encoding
            )
        } catch {
            let alert = NSAlert()
            alert.messageText = "Save Copy Failed"
            alert.informativeText = "Could not save the copy: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // Rename the current document
    @MainActor
    func renameDocument(_ tab: EditorTab) async {
        guard let oldURL = tab.document.fileURL else {
            // For untitled documents, just do Save As
            await saveDocumentAs(tab)
            return
        }

        let panel = NSSavePanel()
        // Notepad++ Save As allows any type (default filter "All types (*.*)"); an
        // empty array honors whatever extension the user types instead of forcing .txt.
        panel.allowedContentTypes = []
        panel.nameFieldStringValue = tab.document.fileName
        panel.directoryURL = oldURL.deletingLastPathComponent()

        let response = await panel.beginAsync()

        guard response == .OK, let newURL = panel.url else {
            return
        }

        do {
            // Move the file to the new location
            try FileManager.default.moveItem(at: oldURL, to: newURL)

            // Update the document's file reference
            tab.document.fileURL = newURL

            // Add new URL to recent files
            addToRecentFiles(newURL)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Rename Failed"
            alert.informativeText = "Could not rename the document: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // Print document
    func printDocument() {
        guard let activeTab = activeTab else { return }

        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false

        // Create text view for printing. Set the font, then assign the text with a single copy via
        // textView.string (the previous code built a separate NSAttributedString and then
        // setAttributedString, a redundant second full copy of the whole document).
        let font = NSFont(name: "Menlo", size: 10) ?? NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin, height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin))
        textView.font = font
        textView.string = activeTab.document.content

        let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true

        // Port of Printer.cpp:44 (nMaxPage = 0xffffU): Notepad++ shows the print dialog before the
        // page count is known, then paginates after the user confirms. The blocking run() paginates
        // the ENTIRE document on the main thread before the panel is usable, so large files beachball.
        // runModal(for:...) presents the sheet-modal panel promptly and paginates asynchronously with
        // the progress panel, matching that "dialog first, count later" behaviour.
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            printOperation.run()
        }
    }

    var hasModifiedDocuments: Bool {
        tabs.contains { $0.document.isModified }
    }
    
    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: "recentFiles"),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            recentFiles = urls
        }
    }
    
    private func addToRecentFiles(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 10 {
            recentFiles = Array(recentFiles.prefix(10))
        }
        saveRecentFiles()
    }
    
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: "recentFiles")
        }
    }
}
