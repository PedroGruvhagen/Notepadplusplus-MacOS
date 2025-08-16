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
        let tab = EditorTab(document: document)
        tabs.append(tab)
        activeTab = tab
    }
    
    @MainActor
    func openDocument() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.text, .sourceCode, .json, .xml, .yaml]
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
            tabs.append(tab)
            activeTab = tab
            addToRecentFiles(url)
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
            do {
                try await document.save()
            } catch {
                print("Error saving document: \(error)")
            }
        }
    }
    
    @MainActor
    func saveDocumentAs(_ tab: EditorTab) async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = tab.document.fileName
        
        let response = await panel.beginAsync()
        
        guard response == .OK, let url = panel.url else {
            // User cancelled or panel error
            return
        }
        
        do {
            try await tab.document.saveAs(to: url)
            addToRecentFiles(url)
        } catch {
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = "Could not save the document: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func closeTab(_ tab: EditorTab) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            
            if tabs.isEmpty {
                createNewDocument()
            } else if activeTab == tab {
                activeTab = tabs[max(0, index - 1)]
            }
        }
    }
    
    func saveAllDocuments() async {
        for tab in tabs where tab.document.isModified {
            if tab.document.fileURL != nil {
                do {
                    try await tab.document.save()
                } catch {
                    // Show error alert
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Save Failed"
                        alert.informativeText = "Could not save \(tab.document.fileName): \(error.localizedDescription)"
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            } else {
                // For untitled documents, show save dialog
                await saveDocumentAs(tab)
            }
        }
    }
    
    func closeAllTabs() {
        tabs.removeAll()
        createNewDocument()
    }
    
    func closeOtherTabs() {
        guard let currentTab = activeTab else { return }
        tabs = [currentTab]
        activeTab = currentTab
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
