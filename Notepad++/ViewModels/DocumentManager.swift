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
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.text, .sourceCode, .json, .xml, .yaml]
        
        panel.begin { response in
            if response == .OK {
                Task {
                    for url in panel.urls {
                        await self.openDocument(from: url)
                    }
                }
            }
        }
    }
    
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
            print("Error opening document: \(error)")
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
    
    func saveDocumentAs(_ tab: EditorTab) async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = tab.document.fileName
        
        let response = await panel.begin()
        if response == .OK, let url = panel.url {
            do {
                try await tab.document.saveAs(to: url)
                addToRecentFiles(url)
            } catch {
                print("Error saving document: \(error)")
            }
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