//
//  FileMonitor.swift
//  Notepad++
//
//  Monitors file changes using DispatchSource for file system events
//  Port of Notepad++ ReadDirectoryChanges functionality
//

import Foundation
import AppKit

/// Monitors a file for external changes
class FileMonitor {
    private var fileURL: URL
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private weak var document: Document?
    private var lastModificationDate: Date?
    private var lastReloadTime: Date?
    private let reloadThrottleInterval: TimeInterval = 0.25 // 250ms rate limiting like original
    
    init(fileURL: URL, document: Document) {
        self.fileURL = fileURL
        self.document = document
        self.lastModificationDate = getModificationDate()
    }
    
    deinit {
        stop()
    }
    
    /// Start monitoring the file for changes
    func start() {
        guard AppSettings.shared.detectFileChanges else { return } // File monitoring disabled
        guard fileDescriptor == -1 else { return } // Already monitoring
        
        // Open file descriptor for monitoring
        fileDescriptor = open(fileURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open file for monitoring: \(fileURL.path)")
            return
        }
        
        // Create dispatch source for file system events
        let queue = DispatchQueue(label: "com.notepadplusplus.filemonitor.\(fileURL.lastPathComponent)")
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )
        
        source?.setEventHandler { [weak self] in
            self?.handleFileEvent()
        }
        
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd != -1 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }
        
        source?.resume()
    }
    
    /// Stop monitoring the file
    func stop() {
        source?.cancel()
        source = nil
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }
    
    /// Handle file system events
    /// Port of Notepad++ file monitoring behavior - NO USER PROMPTS
    private func handleFileEvent() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let _ = self.document else { return }
            
            // Check if file still exists
            let fileExists = FileManager.default.fileExists(atPath: self.fileURL.path)
            
            if !fileExists {
                // File was deleted - Original behavior: just stop monitoring
                // Port of NPPM_INTERNAL_STOPMONITORING
                self.stop()
                // Keep file in editor, mark as modified since it no longer exists on disk
                self.document?.isModified = true
            } else {
                // File was modified - check modification date to avoid false positives
                let currentModDate = self.getModificationDate()
                if let lastDate = self.lastModificationDate,
                   let currentDate = currentModDate,
                   currentDate > lastDate {
                    
                    self.lastModificationDate = currentDate
                    
                    // Original Notepad++ behavior: ALWAYS auto-reload, no prompts
                    // Port of NPPM_INTERNAL_RELOADSCROLLTOEND
                    self.reloadFile()
                }
            }
        }
    }
    
    /// Get file modification date
    private func getModificationDate() -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    /// Reload file from disk with rate limiting
    /// Port of Buffer::reload() from Buffer.cpp
    private func reloadFile() {
        // Rate limiting - Port of Sleep(250) from NppIO.cpp
        let now = Date()
        if let lastReload = lastReloadTime,
           now.timeIntervalSince(lastReload) < reloadThrottleInterval {
            return // Skip reload due to rate limiting
        }
        lastReloadTime = now
        
        Task { @MainActor in
            do {
                // Read file with encoding detection
                let (content, detectedEncoding, detectedEOL) = try EncodingManager.shared.readFile(
                    at: fileURL,
                    openAnsiAsUtf8: AppSettings.shared.openAnsiAsUtf8
                )
                
                // Update document - Port of direct buffer reload
                // Use forceUpdateContent to bypass content protection for external reloads
                document?.forceUpdateContent(content, encoding: detectedEncoding, eol: detectedEOL)
                
                // Original Notepad++ does NOT mark as saved after reload
                // It preserves the modified state for user awareness
                // document?.markAsSaved() // REMOVED - not in original
                
                // Update modification date
                lastModificationDate = getModificationDate()
                
                // Silent reload - no user notification (matches original)
            } catch {
                // Original Notepad++ behavior: Silent failure, no user prompt
                // Just stop monitoring on error
                stop()
            }
        }
    }
    
    /// Update file URL if document is saved to a new location
    func updateFileURL(_ newURL: URL) {
        stop()
        fileURL = newURL
        lastModificationDate = getModificationDate()
        start()
    }
}