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
    /// From NppIO.cpp line 555-641
    private func reloadFile() {
        guard let document = document else { return }
        
        // Apply rate limiting as in original
        if let lastReload = lastReloadTime,
           Date().timeIntervalSince(lastReload) < reloadThrottleInterval {
            return
        }
        lastReloadTime = Date()
        
        // Line 557-566: When alert is false (no dirty), skip the dialog
        // This matches Notepad++ behavior of auto-reloading without prompts
        
        guard let fileURL = document.fileURL else { return }
        
        do {
            // Read file content
            let (content, encoding, eol) = try EncodingManager.shared.readFile(
                at: fileURL,
                openAnsiAsUtf8: AppSettings.shared.openAnsiAsUtf8
            )
            
            // Line 594: MainFileManager.reloadBuffer(id)
            // Force update content - bypass the normal update to prevent reverting
            document.forceUpdateContent(content, encoding: encoding, eol: eol)
            
            // Update our tracking
            lastModificationTime = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
            currentStatus = .regular
            
        } catch {
            print("Failed to reload file: \(error)")
        }
    }
    
    /// Handle file modification - translation of notification behavior
    private func handleFileModified() {
        guard let document = document else { return }
        
        // If document is not dirty, reload automatically
        // This matches Notepad++ behavior from checkModifiedDocument
        if !document.isModified {
            reloadFile()
        }
        // If dirty, Notepad++ shows status but doesn't prompt
        // The user can manually reload if needed
    }
    
    // MARK: - File System Monitoring
    
    func start() {
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