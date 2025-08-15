//
//  Document.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI

class Document: ObservableObject, Identifiable {
    let id = UUID()
    
    @Published var content: String
    @Published var filePath: URL?
    @Published var isModified: Bool = false
    @Published var fileName: String
    @Published var fileExtension: String?
    @Published var language: LanguageDefinition?
    
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
            } else {
                // Default to plain text if no language detected
                self.language = nil
            }
        } else {
            self.fileName = "Untitled"
            self.fileExtension = nil
            self.language = nil
        }
    }
    
    func updateContent(_ newContent: String) {
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
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        markAsSaved()
    }
    
    func saveAs(to url: URL) async throws {
        filePath = url
        fileName = url.lastPathComponent
        fileExtension = url.pathExtension.isEmpty ? nil : url.pathExtension
        // Use the new LanguageManager to detect language
        if let nppLanguage = LanguageManager.shared.detectLanguage(for: url.lastPathComponent) {
            language = nppLanguage.toLanguageDefinition()
        } else {
            // Default to plain text if no language detected
            language = nil
        }
        try await save()
    }
    
    static func open(from url: URL) async throws -> Document {
        let content = try String(contentsOf: url, encoding: .utf8)
        return Document(content: content, filePath: url)
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