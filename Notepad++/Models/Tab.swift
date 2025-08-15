//
//  Tab.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import Foundation
import SwiftUI

@MainActor
struct EditorTab: Identifiable, Hashable {
    let id = UUID()
    let document: Document
    
    var title: String {
        let modifiedIndicator = document.isModified ? " •" : ""
        return document.fileName + modifiedIndicator
    }
    
    var icon: String {
        switch document.fileExtension?.lowercased() {
        case "swift":
            return "swift"
        case "js", "javascript":
            return "curlybraces"
        case "py", "python":
            return "chevron.left.slash.chevron.right"
        case "html", "htm":
            return "globe"
        case "css":
            return "paintbrush"
        case "json":
            return "curlybraces.square"
        case "md", "markdown":
            return "text.alignleft"
        case "txt", "text":
            return "doc.text"
        default:
            return "doc"
        }
    }
    
    nonisolated static func == (lhs: EditorTab, rhs: EditorTab) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}