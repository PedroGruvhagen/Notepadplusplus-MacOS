//
//  Document.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI

@MainActor
class Document: ObservableObject, Identifiable {
    let id = UUID()
    
    @Published var content: String {
        didSet {
            print("DEBUG Document.content didSet: old=\(oldValue.count), new=\(content.count)")
            // Detect if content is being reset to original file content
            if content.count == 29 && oldValue.count > 29 && content == lastSavedContent {
                print("ERROR: Content being reset to original! Reverting...")
                content = oldValue
            }
        }
    }
    @Published var filePath: URL?
    @Published var isModified: Bool = false
    @Published var fileName: String
    @Published var fileExtension: String?
    @Published var language: LanguageDefinition?
    @Published var foldingState = FoldingState()
    
    private var lastSavedContent: String
    
    init(content: String = "", filePath: URL? = nil) {
        self.content = content
        self.filePath = filePath
        self.lastSavedContent = content
        
        if let path = filePath {
            self.fileName = path.lastPathComponent
            self.fileExtension = path.pathExtension.isEmpty ? nil : path.pathExtension
            // Use the new LanguageManager to detect language
            if let nppLanguage = LanguageManager.shared.detectLanguage(for: path.lastPathComponent) {
                self.language = nppLanguage.toLanguageDefinition()
                print("DEBUG: Language detected: \(nppLanguage.name)")
            } else {
                // Try the old language manager as fallback
                if let oldLanguage = OldLanguageManager.shared.detectLanguage(for: path) {
                    self.language = oldLanguage
                    print("DEBUG: Language detected (fallback): \(oldLanguage.name)")
                } else {
                    self.language = nil
                    print("DEBUG: No language detected for \(path.lastPathComponent)")
                }
            }
        } else {
            self.fileName = "Untitled"
            self.fileExtension = nil
            self.language = nil
        }
    }
    
    func updateContent(_ newContent: String) {
        print("DEBUG Document.updateContent: old=\(content.count), new=\(newContent.count), isModified=\(newContent != lastSavedContent)")
        content = newContent
        isModified = (newContent != lastSavedContent)
    }
    
    func markAsSaved() {
        lastSavedContent = content
        isModified = false
    }
    
    func save() async throws {
        guard let url = filePath else {
            throw DocumentError.noFilePath
        }
        
        let contentToSave = content
        try await Task {
            try contentToSave.write(to: url, atomically: true, encoding: .utf8)
        }.value
        markAsSaved()
    }
    
    func saveAs(to url: URL) async throws {
        filePath = url
        fileName = url.lastPathComponent
        fileExtension = url.pathExtension.isEmpty ? nil : url.pathExtension
        // Use the new LanguageManager to detect language
        if let nppLanguage = LanguageManager.shared.detectLanguage(for: url.lastPathComponent) {
            language = nppLanguage.toLanguageDefinition()
            print("DEBUG: Language detected on save: \(nppLanguage.name)")
        } else {
            // Try the old language manager as fallback
            if let oldLanguage = OldLanguageManager.shared.detectLanguage(for: url) {
                language = oldLanguage
                print("DEBUG: Language detected on save (fallback): \(oldLanguage.name)")
            } else {
                language = nil
                print("DEBUG: No language detected on save for \(url.lastPathComponent)")
            }
        }
        try await save()
    }
    
    static func open(from url: URL) async throws -> Document {
        // Read file content on background thread
        let content = try await Task.detached {
            try String(contentsOf: url, encoding: .utf8)
        }.value
        
        // Create Document on main thread
        return await MainActor.run {
            Document(content: content, filePath: url)
        }
    }
}

enum DocumentError: LocalizedError {
    case noFilePath
    case saveError(String)
    case openError(String)
    
    var errorDescription: String? {
        switch self {
        case .noFilePath:
            return "No file path specified"
        case .saveError(let message):
            return "Save error: \(message)"
        case .openError(let message):
            return "Open error: \(message)"
        }
    }
}