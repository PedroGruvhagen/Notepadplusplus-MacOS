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
    @Published var tabs: [EditorTab] = []
    @Published var activeTab: EditorTab?
    @Published var recentFiles: [URL] = []
    
    init() {
        loadRecentFiles()
        if tabs.isEmpty {
            createNewDocument()
        }
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
        if let existingTab = tabs.first(where: { $0.document.filePath == url }) {
            activeTab = existingTab
            return
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
        
        if document.filePath == nil {
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
    
    func closeAllTabs() {
        tabs.removeAll()
        createNewDocument()
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