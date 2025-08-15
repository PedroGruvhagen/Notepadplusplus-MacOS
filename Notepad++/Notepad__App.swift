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
            
            // Edit menu - replacing standard text editing commands
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NotificationCenter.default.post(name: .undo, object: nil)
                }
                .keyboardShortcut("z", modifiers: .command)
                
                Button("Redo") {
                    NotificationCenter.default.post(name: .redo, object: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }
            
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    NotificationCenter.default.post(name: .cut, object: nil)
                }
                .keyboardShortcut("x", modifiers: .command)
                
                Button("Copy") {
                    NotificationCenter.default.post(name: .copy, object: nil)
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Paste") {
                    NotificationCenter.default.post(name: .paste, object: nil)
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Divider()
                
                Button("Select All") {
                    NotificationCenter.default.post(name: .selectAll, object: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
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
            
            // View menu - matching Notepad++ structure
            CommandMenu("View") {
                Button(action: {
                    AppSettings.shared.wordWrap.toggle()
                }) {
                    HStack {
                        Text("Word Wrap")
                        if AppSettings.shared.wordWrap {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .keyboardShortcut("w", modifiers: [.command, .option])
                
                Button(action: {
                    AppSettings.shared.showLineNumbers.toggle()
                }) {
                    HStack {
                        Text("Show Line Numbers")
                        if AppSettings.shared.showLineNumbers {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    AppSettings.shared.syntaxHighlighting.toggle()
                }) {
                    HStack {
                        Text("Syntax Highlighting")
                        if AppSettings.shared.syntaxHighlighting {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    AppSettings.shared.codeFolding.toggle()
                }) {
                    HStack {
                        Text("Code Folding")
                        if AppSettings.shared.codeFolding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    NotificationCenter.default.post(name: .foldAll, object: nil)
                }) {
                    Text("Fold All")
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                .disabled(!AppSettings.shared.codeFolding)
                
                Button(action: {
                    NotificationCenter.default.post(name: .unfoldAll, object: nil)
                }) {
                    Text("Unfold All")
                }
                .keyboardShortcut("9", modifiers: [.command, .option])
                .disabled(!AppSettings.shared.codeFolding)
                
                Divider()
                
                Button(action: {
                    AppSettings.shared.showWhitespace.toggle()
                }) {
                    HStack {
                        Text("Show All Characters")
                        if AppSettings.shared.showWhitespace {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    AppSettings.shared.showIndentGuides.toggle()
                }) {
                    HStack {
                        Text("Show Indent Guides")
                        if AppSettings.shared.showIndentGuides {
                            Image(systemName: "checkmark")
                        }
                    }
                }
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
    static let undo = Notification.Name("undo")
    static let redo = Notification.Name("redo")
    static let cut = Notification.Name("cut")
    static let copy = Notification.Name("copy")
    static let paste = Notification.Name("paste")
    static let selectAll = Notification.Name("selectAll")
    static let foldAll = Notification.Name("foldAll")
    static let unfoldAll = Notification.Name("unfoldAll")
}
