//
//  BackupManager.swift
//  Notepad++
//
//  Manages automatic backup, auto-save snapshots and crash-recovery session persistence.
//  Translation of Notepad++ FileManager::backupCurrentBuffer / session handling
//  (Buffer.cpp:1263, NppIO.cpp:1858) and the periodic snapshot timer (Notepad_plus.cpp:8769).
//

import Foundation
import AppKit

class BackupManager: ObservableObject {
    static let shared = BackupManager()

    private var autoSaveTimer: Timer?
    private var sessionSnapshotTimer: Timer?
    private let fileManager = FileManager.default

    // F40: paths already reported as failing, so a persistent save/backup/snapshot error surfaces
    // ONCE per document per session instead of either being swallowed silently (the old `print`)
    // or spamming a modal on every timer tick.
    private var warnedFailurePaths: Set<String> = []

    init() {
        setupTimers()
        observeSettingsChanges()
        observeAppTermination()
    }

    private func observeAppTermination() {
        // Save session when app is about to terminate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func appWillTerminate() {
        // F35: persist the session so a graceful quit with "remember last session" restores the
        // open tabs (and any unsaved untitled content) on next launch. Crash / force-quit is
        // covered separately by the periodic snapshot timer, which fires independently of this
        // terminate hook. willTerminateNotification is delivered on the main thread, and the write
        // must complete synchronously here because the process exits the moment this returns.
        MainActor.assumeIsolated {
            saveSessionSnapshot(synchronousWrite: true)
        }
    }

    private func observeSettingsChanges() {
        // Observe settings changes to update timers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .settingsDidChange,
            object: nil
        )
    }

    @objc private func settingsChanged() {
        setupTimers()
    }

    private func setupTimers() {
        // Clear existing timers
        autoSaveTimer?.invalidate()
        sessionSnapshotTimer?.invalidate()

        let settings = AppSettings.shared

        // Setup auto-save timer
        if settings.enableAutoSave {
            // Clamp to a positive floor: a 0 or negative autoSaveInterval would make this repeating
            // Timer fire every runloop pass, backing up every dirty document continuously (F33).
            // Faithful to Notepad++'s periodic-backup thread, which floors its interval before every
            // sleep: `size_t timer = nppGUI._snapshotBackupTiming; if (timer < 1000) timer = 1000;`
            // (notepad-plus-plus-reference/PowerEditor/src/Notepad_plus.cpp:8769-8771).
            let interval = TimeInterval(max(1, settings.autoSaveInterval) * 60) // Convert minutes to seconds
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task { @MainActor in
                    await self.performAutoSave()
                }
            }
        }

        // F35: periodic crash-recovery snapshot. This is the ONLY thing that survives a crash or a
        // force-quit (appWillTerminate does not fire then), so it is what makes "force-quit then
        // relaunch restores open tabs and unsaved content" work. Clamp the interval to a positive
        // floor for the same runaway-timer reason as auto-save above (F33 pattern).
        if settings.enableSessionSnapshot {
            let interval = TimeInterval(max(1, settings.snapshotInterval)) // already in seconds
            sessionSnapshotTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task { @MainActor in
                    self.saveSessionSnapshot()
                }
            }
        }
    }

    @MainActor
    private func performAutoSave() async {
        let documentManager = DocumentManager.shared

        for tab in documentManager.tabs {
            let document = tab.document
            // F45: auto-save must NOT commit half-finished edits into the user's real file - that
            // destroys the last-good on-disk version mid-edit and removes the close-without-saving
            // escape. Write a timestamped snapshot into the backup directory instead and leave the
            // original untouched with the buffer still dirty, exactly like Notepad++'s periodic
            // backup, which writes FILENAME@TIMESTAMP snapshots and only touches the real file on
            // an explicit save (Buffer.cpp:1243-1253, 1263 backupCurrentBuffer).
            if document.isModified && document.fileURL != nil {
                await writeAutoSaveSnapshot(for: document)
            }
        }
    }

    // MARK: - Auto-save snapshot (F45)

    /// Write the current (unsaved) buffer to a timestamped snapshot in the backup directory,
    /// leaving the original file untouched. Port of FileManager::backupCurrentBuffer, which skips
    /// large files (Buffer.cpp:1266) and writes with the buffer's encoding via Utf8_16_Write
    /// (Buffer.cpp:1278-1283).
    @MainActor
    private func writeAutoSaveSnapshot(for document: Document) async {
        guard let fileURL = document.fileURL else { return }
        // Buffer.cpp:1266: backupCurrentBuffer returns false for large files.
        guard !document.isLargeFile else { return }

        let backupDir = getAutoSaveBackupDirectory()
        let timestamp = DateFormatter.backupTimestamp.string(from: Date())
        let snapshotURL = backupDir.appendingPathComponent("\(fileURL.lastPathComponent)@\(timestamp)")

        // Read the buffer + settings on the main actor, then write off it (F41 spirit).
        let contentToWrite = EncodingManager.shared.convertEOL(in: document.content, to: document.eolType)
        let encoding = document.encoding
        do {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
            try await Task.detached(priority: .utility) {
                try EncodingManager.shared.writeFile(content: contentToWrite, to: snapshotURL, encoding: encoding)
            }.value
            // Success clears any prior warning for this document.
            warnedFailurePaths.remove(fileURL.path)
        } catch {
            // F40: an auto-save failure used to be swallowed with `print`, invisible in a GUI app,
            // and repeated silently every tick. Surface it once so a persistent failure is seen.
            reportFailure(kind: "Auto-save", fileName: fileURL.lastPathComponent, path: fileURL.path, message: error.localizedDescription)
        }
    }

    private func getAutoSaveBackupDirectory() -> URL {
        let settings = AppSettings.shared
        if !settings.backupDirectory.isEmpty {
            return URL(fileURLWithPath: settings.backupDirectory, isDirectory: true)
        }
        // Default: Application Support/Notepad++/backup, matching Notepad++'s getUserPath()\backup\.
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Notepad++", isDirectory: true)
            .appendingPathComponent("backup", isDirectory: true)
    }

    // MARK: - Session snapshot (F35)

    @MainActor
    func saveSessionSnapshot(synchronousWrite: Bool = false) {
        let documentManager = DocumentManager.shared

        // Gather the session on the main actor (reading each buffer). The disk write happens off
        // the main actor for the periodic timer, and synchronously for the terminate hook (the
        // process exits before a detached task could run).
        var sessionData: [[String: Any]] = []

        for tab in documentManager.tabs {
            let doc = tab.document
            var tabData: [String: Any] = [
                "fileName": doc.fileName,
                "language": doc.language?.name ?? "Plain Text",
                "isModified": doc.isModified,
                "caretPosition": doc.caretPosition,
                "scrollX": doc.scrollPosition.x,
                "scrollY": doc.scrollPosition.y,
                "selectedLocation": doc.selectedRange.location,
                "selectedLength": doc.selectedRange.length,
                "encoding": doc.encoding.rawValue,
                "eolType": doc.eolType.rawValue
            ]

            if let url = doc.fileURL {
                tabData["filePath"] = url.path
            }

            // Only snapshot the actual text for buffers whose bytes are NOT already safely on disk:
            // untitled buffers and dirty (unsaved) buffers. A clean titled buffer is reloaded from
            // its file on restore, so storing its content would just duplicate the disk and bridge
            // the whole string every tick. Large files are skipped entirely (Buffer.cpp:1266
            // backupCurrentBuffer returns false for large files), which also bounds the per-tick cost.
            if (doc.isModified || doc.fileURL == nil) && !doc.isLargeFile {
                tabData["content"] = doc.content
            }

            sessionData.append(tabData)
        }

        var activeTabIndex = -1
        if let activeTab = documentManager.activeTab,
           let idx = documentManager.tabs.firstIndex(where: { $0.id == activeTab.id }) {
            activeTabIndex = idx
        }

        let sessionURL = getSessionSnapshotURL()
        let metaURL = sessionURL.deletingPathExtension().appendingPathExtension("meta.json")

        // Serialize on the main actor: JSONSerialization needs the `[[String: Any]]` we gathered,
        // which is not Sendable and so cannot cross into a detached task. The resulting Data IS
        // Sendable, so only the disk write is handed off. A snapshot-write failure is
        // non-destructive (the real files are untouched) - it only means this crash-recovery point
        // was skipped, and the next tick retries - so it is a best-effort `try?`.
        guard let sessionBytes = try? JSONSerialization.data(withJSONObject: sessionData, options: []) else { return }
        var metaBytes: Data? = nil
        if activeTabIndex >= 0 {
            metaBytes = try? JSONSerialization.data(withJSONObject: ["activeTabIndex": activeTabIndex])
        }

        if synchronousWrite {
            // Terminate hook: write inline before the process exits.
            try? sessionBytes.write(to: sessionURL, options: .atomic)
            if let metaBytes { try? metaBytes.write(to: metaURL, options: .atomic) }
        } else {
            Task.detached(priority: .utility) {
                try? sessionBytes.write(to: sessionURL, options: .atomic)
                if let metaBytes { try? metaBytes.write(to: metaURL, options: .atomic) }
            }
        }
    }

    /// Restore the previous session at launch when "remember last session" is on. Awaitable so the
    /// launch sequence can restore BEFORE deciding whether to fall back to a fresh untitled. Port
    /// of Notepad++ loading the session during startup before command-line files (loadSession).
    @MainActor
    func restoreSession() async {
        guard AppSettings.shared.rememberLastSession else { return }

        let sessionURL = getSessionSnapshotURL()
        guard fileManager.fileExists(atPath: sessionURL.path) else { return }
        guard let data = try? Data(contentsOf: sessionURL),
              let sessionData = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
            return
        }

        let documentManager = DocumentManager.shared

        for tabData in sessionData {
            let isModified = tabData["isModified"] as? Bool ?? false
            let savedContent = tabData["content"] as? String
            let document: Document

            if let filePath = tabData["filePath"] as? String {
                let fileURL = URL(fileURLWithPath: filePath)
                if isModified, let savedContent {
                    // Unsaved edits: restore the SNAPSHOT bytes (the user's work), NOT the disk
                    // version. Reloading from disk here would silently discard exactly the edits the
                    // snapshot exists to protect. Mark dirty (the content setter does) so the tab
                    // shows unsaved and prompts on close.
                    document = Document(filePath: fileURL)
                    document.content = savedContent
                } else if fileManager.fileExists(atPath: filePath) {
                    // Clean buffer: reload the current on-disk bytes (picks up any external change),
                    // matching Notepad++ reloading clean buffers on session load.
                    if let opened = try? await Document.open(from: fileURL) {
                        document = opened
                    } else {
                        document = Document(filePath: fileURL)
                        if let savedContent { document.content = savedContent }
                    }
                } else {
                    // The file is gone: fall back to the snapshot content if we have it.
                    document = Document(filePath: fileURL)
                    if let savedContent { document.content = savedContent }
                }
            } else {
                // Untitled buffer: restore its unsaved content verbatim, and assign the smallest free
                // "new N" number (port of Buffer.cpp:1633-1690 nextUntitledNewNumber). The snapshot does
                // not persist the original untitled number, so several restored untitled buffers must
                // still get distinct names (new 1, new 2, ...) instead of all colliding on the
                // Document.init default "new 1". Earlier loop iterations have already appended their
                // tabs, so nextUntitledNewNumber() accounts for the untitled buffers already restored.
                document = Document()
                document.setUntitledName(number: documentManager.nextUntitledNewNumber())
                if let savedContent { document.content = savedContent }
            }

            // Restore caret / scroll / selection. Seed the tab-switch position fields too so a
            // later tab switch restores the same spot.
            document.caretPosition = tabData["caretPosition"] as? Int ?? 0
            document.scrollPosition = CGPoint(
                x: tabData["scrollX"] as? CGFloat ?? 0,
                y: tabData["scrollY"] as? CGFloat ?? 0
            )
            document.selectedRange = NSRange(
                location: tabData["selectedLocation"] as? Int ?? 0,
                length: tabData["selectedLength"] as? Int ?? 0
            )
            document.documentSelectedRange = document.selectedRange
            document.documentScrollPosition = document.scrollPosition

            if let encodingRaw = tabData["encoding"] as? Int,
               let encoding = FileEncoding(rawValue: encodingRaw) {
                document.encoding = encoding
            }
            if let eolRaw = tabData["eolType"] as? Int,
               let eol = EOLType(rawValue: eolRaw) {
                document.eolType = eol
            }

            // A buffer marked clean in the snapshot must not carry over the dirty flag the content
            // setter may have set while loading a fallback copy.
            if !isModified {
                document.isModified = false
            }

            // F38: watch restored file-backed buffers for external changes (idempotent).
            document.beginFileMonitoring()

            let tab = EditorTab(document: document)
            documentManager.tabs.append(tab)
        }

        // Restore the active tab.
        let metaURL = sessionURL.deletingPathExtension().appendingPathExtension("meta.json")
        if let metaData = try? Data(contentsOf: metaURL),
           let metadata = (try? JSONSerialization.jsonObject(with: metaData)) as? [String: Any],
           let activeIndex = metadata["activeTabIndex"] as? Int,
           activeIndex >= 0, activeIndex < documentManager.tabs.count {
            documentManager.activeTab = documentManager.tabs[activeIndex]
        } else if !documentManager.tabs.isEmpty {
            documentManager.activeTab = documentManager.tabs.first
        }
    }

    private func getSessionSnapshotURL() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Notepad++", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)

        return appDir.appendingPathComponent("session.json")
    }

    // MARK: - Pre-save backup (F37): preserve the PREVIOUS on-disk version

    /// The destination for the pre-save backup of `document`, or nil when backup is disabled or the
    /// document has never been saved (no previous version to preserve). Read on the main actor
    /// because it consults settings; the actual copy runs off the main actor (copyPreviousVersion).
    @MainActor
    func backupDestination(for document: Document) -> URL? {
        let settings = AppSettings.shared
        guard settings.enableBackup, let fileURL = document.fileURL else { return nil }

        switch settings.backupMode {
        case .simple:
            return createSimpleBackup(for: fileURL)
        case .verbose:
            return createVerboseBackup(for: fileURL)
        case .none:
            return nil
        }
    }

    /// Copy the PREVIOUS on-disk file byte-for-byte to the backup location BEFORE the real save
    /// overwrites it, so the .bak is the prior version and a save can be rolled back. This is the
    /// literal translation of Notepad++'s pre-save backup, `::CopyFileEx(fn, fn_bak, ...)`
    /// (NppIO.cpp:1858), which runs before doSave. The old code instead wrote the NEW in-memory
    /// buffer as UTF-8/LF, so the .bak always duplicated the content just saved and gave zero
    /// rollback (F37). Nonisolated so it can run off the main actor with the save write (F41).
    nonisolated static func copyPreviousVersion(from sourceURL: URL, to backupURL: URL) throws {
        let fm = FileManager.default
        // First save: there is no previous on-disk version to preserve yet.
        guard fm.fileExists(atPath: sourceURL.path) else { return }

        try fm.createDirectory(at: backupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: backupURL.path) {
            try fm.removeItem(at: backupURL)
        }
        try fm.copyItem(at: sourceURL, to: backupURL)
    }

    private func createSimpleBackup(for fileURL: URL) -> URL {
        let backupDir = getBackupDirectory(for: fileURL)
        let backupName = fileURL.lastPathComponent + ".bak"
        return backupDir.appendingPathComponent(backupName)
    }

    private func createVerboseBackup(for fileURL: URL) -> URL {
        let backupDir = getBackupDirectory(for: fileURL)
        let timestamp = DateFormatter.backupTimestamp.string(from: Date())
        let backupName = "\(fileURL.deletingPathExtension().lastPathComponent).\(timestamp).bak"
        return backupDir.appendingPathComponent(backupName)
    }

    private func getBackupDirectory(for fileURL: URL) -> URL {
        let settings = AppSettings.shared

        if !settings.backupDirectory.isEmpty {
            // Use custom backup directory
            return URL(fileURLWithPath: settings.backupDirectory, isDirectory: true)
        } else {
            // Use same directory as file
            return fileURL.deletingLastPathComponent()
        }
    }

    // MARK: - Failure surfacing (F40)

    /// Surface a save-path failure once per document per session. Repeated failures on the same
    /// path are recorded in the warned set silently so the user is not spammed on every timer tick.
    @MainActor
    func reportFailure(kind: String, fileName: String, path: String, message: String) {
        guard !warnedFailurePaths.contains(path) else { return }
        warnedFailurePaths.insert(path)

        let alert = NSAlert()
        alert.messageText = "\(kind) Failed"
        alert.informativeText = "\(kind) of \"\(fileName)\" failed: \(message)\n\nYour original file has not been changed. Save manually to a safe location if the problem persists."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Convenience used by the save path when the pre-save backup copy fails (F37/F40). The dedup
    /// key MUST be the file's full path, not its basename: two different files with the same
    /// basename in different folders would otherwise share one key, so a real backup failure for
    /// the second file would be permanently suppressed after the first was reported.
    @MainActor
    func reportBackupFailure(fileName: String, path: String, message: String) {
        reportFailure(kind: "Backup", fileName: fileName, path: "backup:" + path, message: message)
    }
}

extension DateFormatter {
    static let backupTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}
