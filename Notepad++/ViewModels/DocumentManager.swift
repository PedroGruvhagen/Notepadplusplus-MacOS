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
        // Notepad++ Save As allows any type (default filter "All types (*.*)"); an
        // empty array honors whatever extension the user types instead of forcing .txt.
        panel.allowedContentTypes = []
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

    // Close all tabs to the left of the active tab
    func closeAllToLeft() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }

        tabs = Array(tabs[currentIndex...])
        activeTab = currentTab
    }

    // Close all tabs to the right of the active tab
    func closeAllToRight() {
        guard let currentTab = activeTab,
              let currentIndex = tabs.firstIndex(of: currentTab) else { return }

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
    func moveToTrash() {
        guard let activeTab = activeTab,
              let url = activeTab.document.fileURL else { return }

        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            closeTab(activeTab)
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
            // Replace the document content
            activeTab.document.forceUpdateContent(
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
            // Save content to the new location without changing the document's file path
            try EncodingManager.shared.writeFile(
                content: tab.document.content,
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

        // Create attributed string with monospaced font
        let font = NSFont(name: "Menlo", size: 10) ?? NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attrString = NSAttributedString(string: activeTab.document.content, attributes: attributes)

        // Create text view for printing
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin, height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin))
        textView.textStorage?.setAttributedString(attrString)

        let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        printOperation.run()
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
