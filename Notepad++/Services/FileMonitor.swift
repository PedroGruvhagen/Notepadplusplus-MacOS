//
//  FileMonitor.swift
//  Notepad++
//
//  LITERAL TRANSLATION of Notepad++ file monitoring functionality
//  From Buffer.cpp checkFileState() and related functions
//

import Foundation
import AppKit

/// Translation of Buffer::checkFileState() from Buffer.cpp line 350-450
/// Returns true if the status has been changed. false otherwise
@MainActor
class FileMonitor {
    
    // Translation of DocFileStatus enum from Buffer.h
    enum DocFileStatus {
        case regular      // DOC_REGULAR
        case unnamed      // DOC_UNNAMED  
        case deleted      // DOC_DELETED
        case modified     // DOC_MODIFIED
    }
    
    private weak var document: Document?
    private var lastModificationTime: Date?
    private var currentStatus: DocFileStatus = .regular
    nonisolated(unsafe) private var fileMonitorSource: DispatchSourceFileSystemObject?
    private let monitorQueue = DispatchQueue(label: "com.notepadplusplus.filemonitor")
    
    // Translation of reloadThrottleInterval from original implementation
    private let reloadThrottleInterval: TimeInterval = 0.25
    private var lastReloadTime: Date?
    
    init(fileURL: URL, document: Document) {
        self.document = document
        updateFileURL(fileURL)
    }
    
    deinit {
        // Stop monitoring when deallocated
        // Cancel the source if it hasn't been cancelled already
        stop()
    }
    
    /// Translation of Buffer::checkFileState() from Buffer.cpp line 350
    func checkFileState() -> Bool {
        guard let document = document,
              let fileURL = document.fileURL else {
            return false
        }
        
        // Line 355-356: Unsaved document cannot change by environment
        if currentStatus == .unnamed {
            return false
        }
        
        // Line 364-365: Check file attributes
        var fileExists = false
        var fileModificationDate: Date?
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            fileExists = true
            fileModificationDate = attributes[.modificationDate] as? Date
        } catch {
            fileExists = false
        }
        
        var hasFileStateChanged = false
        
        // Line 399-410: File has been deleted
        if !fileExists && currentStatus == .regular {
            currentStatus = .deleted
            hasFileStateChanged = true
            
            // Notify document of deletion (equivalent to doNotify(BufferChangeStatus))
            document.handleExternalDeletion()
        }
        // Line 411-422: File has been restored
        else if fileExists && currentStatus == .deleted {
            currentStatus = .regular
            hasFileStateChanged = true
            
            // Reload the file automatically
            DispatchQueue.main.async { [weak self] in
                self?.reloadFile()
            }
        }
        // Line 423-441: File has been modified
        else if fileExists && currentStatus == .regular {
            if let modDate = fileModificationDate,
               let lastMod = lastModificationTime,
               modDate > lastMod {
                
                currentStatus = .modified
                hasFileStateChanged = true
                
                // Line 439: doNotify(BufferChangeTimestamp | BufferChangeStatus)
                DispatchQueue.main.async { [weak self] in
                    self?.handleFileModified()
                }
            }
        }
        
        return hasFileStateChanged
    }
    
    /// Translation of Notepad_plus::doReload() behavior when alert=false
    /// From NppIO.cpp line 583-641
    private func reloadFile() {
        guard let document = document else { return }

        // Apply rate limiting as in original
        if let lastReload = lastReloadTime,
           Date().timeIntervalSince(lastReload) < reloadThrottleInterval {
            return
        }
        lastReloadTime = Date()

        guard let fileURL = document.fileURL else { return }
        let openAnsiAsUtf8 = AppSettings.shared.openAnsiAsUtf8

        // F42: read + decode + EOL scan OFF the main thread - it is the same heavy loadFileData
        // work as opening a file (EncodingManager.readFile is nonisolated for exactly this). The
        // former code ran the whole read on the main thread, freezing the UI whenever git, a build
        // tool or a sync client rewrote a clean buffer. Hop back to the main actor only for the
        // textStorage swap. Port of Buffer.cpp FileManager::loadFileData running off the UI thread.
        Task.detached(priority: .userInitiated) {
            do {
                let result = try EncodingManager.shared.readFile(at: fileURL, openAnsiAsUtf8: openAnsiAsUtf8)
                let newModDate = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
                await MainActor.run {
                    // F44: preserve the caret and scroll position across the reload content swap
                    // (Notepad++ doReload brackets the swap with saveCurrentPos/restoreCurrentPos,
                    // NppIO.cpp:603/629). forceUpdateContent alone would drop the selection.
                    document.forceUpdateContentPreservingViewState(result.content, encoding: result.encoding, eol: result.eolType)
                    self.lastModificationTime = newModDate ?? self.lastModificationTime
                    self.currentStatus = .regular
                }
            } catch {
                // The on-disk file is momentarily unreadable (e.g. another program is mid-write).
                // Leave the buffer untouched and reset status so the next change event retries; no
                // bytes are lost.
                await MainActor.run { self.currentStatus = .regular }
            }
        }
    }

    /// Handle file modification - translation of Notepad_plus onBufferChange DOC_MODIFIED handling
    /// (Notepad_plus.cpp:6644-6682):
    ///     bool autoUpdate = (nppGUI._fileAutoDetection & cdAutoUpdate) ? true : false;
    ///     if (!autoUpdate || buffer->isDirty()) { doReloadOrNot(...); if (No) { setDirty; abort } }
    ///     doReload(...);
    /// cdAutoUpdate (0x04) is the "Update Silently" preference, OFF by default (the default is
    /// cdEnabledNew = 0x02; NppConstants.h:188-194, Parameters.h:728). So by default EVERY external
    /// change PROMPTS, whether the buffer is clean or dirty; a clean buffer reloads silently only
    /// when the user has turned "Update Silently" on. A dirty buffer ALWAYS prompts and never
    /// silently reloads over unsaved edits.
    private func handleFileModified() {
        guard let document = document else { return }

        // Respect the "detect file changes" preference (Notepad++ file auto-detection); if it was
        // turned off after monitoring started, do nothing.
        guard AppSettings.shared.detectFileChanges else {
            currentStatus = .regular
            return
        }
        guard let fileURL = document.fileURL else { return }

        // Silent reload only when the buffer is clean AND "Update Silently" (cdAutoUpdate) is on.
        let updateSilently = AppSettings.shared.updateSilently
        if !document.isModified && updateSilently {
            reloadFile()
            return
        }

        // Otherwise prompt with doReloadOrNot. Two message variants (Notepad_plus.cpp:2479-2496):
        // the dirty one warns about losing changes; the clean one is a plain reload question.
        let dirty = document.isModified
        let alert = NSAlert()
        alert.messageText = "Reload"
        if dirty {
            alert.informativeText = "\"\(fileURL.lastPathComponent)\"\n\nThis file has been modified by another program.\nDo you want to reload it and lose the changes made in Notepad++?"
        } else {
            alert.informativeText = "\"\(fileURL.lastPathComponent)\"\n\nThis file has been modified by another program.\nDo you want to reload it?"
        }
        alert.alertStyle = dirty ? .warning : .informational
        let reloadButton = alert.addButton(withTitle: "Reload")   // IDYES
        let keepButton = alert.addButton(withTitle: "Cancel")     // IDNO
        // The dirty prompt uses MB_DEFBUTTON2 (default = keep my edits) so a reflexive Return does
        // not discard unsaved work; the clean prompt defaults to Reload (MB_ICONQUESTION, no
        // MB_DEFBUTTON2 in the C++).
        if dirty {
            reloadButton.keyEquivalent = ""
            keepButton.keyEquivalent = "\r"
        }

        if alert.runModal() == .alertFirstButtonReturn {
            reloadFile()
        } else {
            // Keep what is on screen. A dirty buffer stays dirty and needing reload (unsync,
            // Notepad_plus.cpp:6662-6668); a clean buffer is simply not reloaded. Accept the
            // current on-disk mtime so the SAME change is not re-prompted, while a later external
            // change still re-triggers.
            if dirty {
                document.setDirty(true)
                document.setNeedReload(true)
            }
            lastModificationTime = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
            currentStatus = .regular
        }
    }
    
    // MARK: - File System Monitoring
    
    func start() {
        // Make start() idempotent: cancel any source this monitor already armed BEFORE opening a
        // new fd. Without this, a second start() overwrites fileMonitorSource with a new source and
        // orphans the previous resumed one; its cancel handler (the only close(fd)) never runs, so a
        // file descriptor plus a live kevent source leak on every construction (F31, the fd leak that
        // exhausts the 256 soft limit after enough saves). One watch per buffer, re-armed, never
        // stacked, matches Notepad++ Buffer::checkFileState (Buffer.cpp), which keeps a single
        // file-status watch per buffer.
        stop()

        guard let fileURL = document?.fileURL else { return }

        // Get initial modification time
        lastModificationTime = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
        
        // Set up file system monitoring
        let fileDescriptor = open(fileURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        fileMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: monitorQueue
        )
        
        fileMonitorSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                // Call checkFileState as Notepad++ does
                _ = self?.checkFileState()
            }
        }
        
        fileMonitorSource?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileMonitorSource?.resume()
    }
    
    nonisolated func stop() {
        // Safe to call multiple times
        // This needs to be nonisolated so it can be called from deinit
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
    }
    
    func updateFileURL(_ newURL: URL) {
        stop()
        document?.fileURL = newURL
        start()
    }
}

// MARK: - Document Extension for File Monitoring
// Removed - handleExternalDeletion is now in Document.swift