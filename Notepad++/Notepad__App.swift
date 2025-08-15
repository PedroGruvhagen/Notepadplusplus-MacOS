//
//  Notepad__App.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

@main
struct Notepad__App: App {
    var body: some Scene {
        WindowGroup("Notepad++") {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Preferences...") {
                    NotificationCenter.default.post(name: .showPreferences, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .textEditing) {
                Divider()
                Button("Find...") {
                    NotificationCenter.default.post(name: .showFind, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Find and Replace...") {
                    NotificationCenter.default.post(name: .showReplace, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .option])
                
                Button("Find Next") {
                    NotificationCenter.default.post(name: .findNext, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)
                
                Button("Find Previous") {
                    NotificationCenter.default.post(name: .findPrevious, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
            
            // Language menu - matching Notepad++ structure
            CommandMenu("Language") {
                LanguageMenuView()
            }
        }
    }
}

extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
    static let newDocument = Notification.Name("newDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let findNext = Notification.Name("findNext")
    static let findPrevious = Notification.Name("findPrevious")
}
