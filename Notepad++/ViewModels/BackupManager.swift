//
//  BackupManager.swift
//  Notepad++
//
//  Manages automatic backup and auto-save functionality
//

import Foundation
import AppKit

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    private var autoSaveTimer: Timer?
    private var sessionSnapshotTimer: Timer?
    private let fileManager = FileManager.default
    
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
        // Don't save session - app should start fresh every time
        // Task { @MainActor in
        //     saveSessionSnapshot()
        // }
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
            let interval = TimeInterval(settings.autoSaveInterval * 60) // Convert minutes to seconds
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                Task { @MainActor in
                    await self.performAutoSave()
                }
            }
        }
        
        // Don't setup session snapshot timer - app should start fresh every time
        // if settings.enableSessionSnapshot {
        //     let interval = TimeInterval(settings.snapshotInterval) // Already in seconds
        //     sessionSnapshotTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
        //         Task { @MainActor in
        //             self.saveSessionSnapshot()
        //         }
        //     }
        // }
    }
    
    @MainActor
    private func performAutoSave() async {
        let documentManager = DocumentManager.shared
        
        for tab in documentManager.tabs {
            if tab.document.isModified && tab.document.fileURL != nil {
                do {
                    try await tab.document.save()
                    print("Auto-saved: \(tab.document.fileName)")
                } catch {
                    print("Auto-save failed for \(tab.document.fileName): \(error)")
                }
            }
        }
    }
    
    @MainActor
    func saveSessionSnapshot() {
        let documentManager = DocumentManager.shared
        
        // Create session data
        var sessionData: [[String: Any]] = []
        
        for tab in documentManager.tabs {
            var tabData: [String: Any] = [
                "content": tab.document.content,
                "fileName": tab.document.fileName,
                "language": tab.document.language?.name ?? "Plain Text",
                "isModified": tab.document.isModified,
                "caretPosition": tab.document.caretPosition,
                "scrollX": tab.document.scrollPosition.x,
                "scrollY": tab.document.scrollPosition.y,
                "selectedLocation": tab.document.selectedRange.location,
                "selectedLength": tab.document.selectedRange.length,
                "encoding": tab.document.encoding.rawValue,
                "eolType": tab.document.eolType.rawValue
            ]
            
            if let url = tab.document.fileURL {
                tabData["filePath"] = url.path
            }
            
            sessionData.append(tabData)
        }
        
        // Also save the active tab index
        if let activeTab = documentManager.activeTab,
           let activeIndex = documentManager.tabs.firstIndex(where: { $0.id == activeTab.id }) {
            let metadata: [String: Any] = ["activeTabIndex": activeIndex]
            if let metaData = try? JSONSerialization.data(withJSONObject: metadata) {
                let metaURL = getSessionSnapshotURL().deletingPathExtension().appendingPathExtension("meta.json")
                try? metaData.write(to: metaURL)
            }
        }
        
        // Save session to disk
        let sessionURL = getSessionSnapshotURL()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: sessionData, options: .prettyPrinted)
            try data.write(to: sessionURL)
            print("Session snapshot saved")
        } catch {
            print("Failed to save session snapshot: \(error)")
        }
    }
    
    func restoreSession() {
        guard AppSettings.shared.rememberLastSession else { return }
        
        let sessionURL = getSessionSnapshotURL()
        
        guard fileManager.fileExists(atPath: sessionURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: sessionURL)
            if let sessionData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                
                Task { @MainActor in
                    let documentManager = DocumentManager.shared
                    
                    for tabData in sessionData {
                        // If file path exists, try to load from disk for fresh content
                        let document: Document
                        if let filePath = tabData["filePath"] as? String {
                            let fileURL = URL(fileURLWithPath: filePath)
                            if FileManager.default.fileExists(atPath: filePath) {
                                // Load fresh content from disk
                                do {
                                    document = try await Document.open(from: fileURL)
                                } catch {
                                    // Fall back to saved content
                                    document = Document()
                                    document.content = tabData["content"] as? String ?? ""
                                    document.fileURL = fileURL
                                }
                            } else {
                                // File doesn't exist anymore, use saved content
                                document = Document()
                                document.content = tabData["content"] as? String ?? ""
                                document.fileURL = fileURL
                            }
                        } else {
                            // No file path, create new document with saved content
                            document = Document()
                            document.content = tabData["content"] as? String ?? ""
                        }
                        
                        // Restore document properties
                        // fileName is read-only in Buffer translation, set via fileURL
                        document.isModified = tabData["isModified"] as? Bool ?? false
                        
                        // Restore position data
                        document.caretPosition = tabData["caretPosition"] as? Int ?? 0
                        document.scrollPosition = CGPoint(
                            x: tabData["scrollX"] as? CGFloat ?? 0,
                            y: tabData["scrollY"] as? CGFloat ?? 0
                        )
                        document.selectedRange = NSRange(
                            location: tabData["selectedLocation"] as? Int ?? 0,
                            length: tabData["selectedLength"] as? Int ?? 0
                        )
                        
                        // Restore encoding and EOL
                        if let encodingRaw = tabData["encoding"] as? Int,
                           let encoding = FileEncoding(rawValue: encodingRaw) {
                            document.encoding = encoding
                        }
                        if let eolRaw = tabData["eolType"] as? Int,
                           let eol = EOLType(rawValue: eolRaw) {
                            document.eolType = eol
                        }
                        
                        if let _ = tabData["language"] as? String {
                            if let nppLang = LanguageManager.shared.detectLanguage(for: document.fileName) {
                                document.language = nppLang.toLanguageDefinition()
                            }
                        }
                        
                        let tab = EditorTab(document: document)
                        documentManager.tabs.append(tab)
                    }
                    
                    // Restore active tab
                    let metaURL = getSessionSnapshotURL().deletingPathExtension().appendingPathExtension("meta.json")
                    if let metaData = try? Data(contentsOf: metaURL),
                       let metadata = try? JSONSerialization.jsonObject(with: metaData) as? [String: Any],
                       let activeIndex = metadata["activeTabIndex"] as? Int,
                       activeIndex < documentManager.tabs.count {
                        documentManager.activeTab = documentManager.tabs[activeIndex]
                    } else if !documentManager.tabs.isEmpty {
                        documentManager.activeTab = documentManager.tabs.first
                    }
                }
            }
        } catch {
            print("Failed to restore session: \(error)")
        }
    }
    
    private func getSessionSnapshotURL() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Notepad++", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        return appDir.appendingPathComponent("session.json")
    }
    
    // MARK: - Backup functionality
    
    @MainActor
    func createBackup(for document: Document) {
        let settings = AppSettings.shared
        
        guard settings.enableBackup,
              let fileURL = document.fileURL else { return }
        
        let backupURL: URL
        
        switch settings.backupMode {
        case .simple:
            backupURL = createSimpleBackup(for: fileURL)
        case .verbose:
            backupURL = createVerboseBackup(for: fileURL)
        case .none:
            return
        }
        
        do {
            let data = document.content.data(using: .utf8) ?? Data()
            try data.write(to: backupURL)
            print("Backup created: \(backupURL.lastPathComponent)")
        } catch {
            print("Backup failed: \(error)")
        }
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
}

extension DateFormatter {
    static let backupTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}

