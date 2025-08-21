//
//  Notepad__App.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

@main
struct Notepad__App: App {
    @StateObject private var backupManager = BackupManager.shared
    @StateObject private var documentManager = DocumentManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Restore session on app launch (will be handled in AppDelegate)
        // Don't restore here to avoid race conditions
    }
    
    var body: some Scene {
        WindowGroup("Notepad++") {
            ContentView()
                .environmentObject(documentManager)
                .onAppear {
                    // Connect documentManager to appDelegate when view appears
                    appDelegate.documentManager = documentManager
                }
                // Removed onOpenURL to prevent duplicate file opening
                // File opening is handled by AppDelegate's application(_:open:) method
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
            
            // File Menu - matching Notepad++ structure
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                // TODO: Open Containing Folder submenu
                // TODO: Open in Default Viewer
                // TODO: Open Folder as Workspace
                
                Button("Reload from Disk") {
                    NotificationCenter.default.post(name: .reloadDocument, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("Save a Copy As...") {
                    NotificationCenter.default.post(name: .saveCopyAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option, .shift])
                
                Button("Save All") {
                    NotificationCenter.default.post(name: .saveAllDocuments, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                
                Button("Rename...") {
                    NotificationCenter.default.post(name: .renameDocument, object: nil)
                }
                
                Divider()
                
                Button("Close") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
                
                Button("Close All") {
                    NotificationCenter.default.post(name: .closeAllTabs, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                
                // Close Multiple Documents submenu
                Menu("Close Multiple Documents") {
                    Button("Close All but Active Document") {
                        NotificationCenter.default.post(name: .closeOtherTabs, object: nil)
                    }
                    
                    Button("Close All to the Left") {
                        NotificationCenter.default.post(name: .closeAllToLeft, object: nil)
                    }
                    
                    Button("Close All to the Right") {
                        NotificationCenter.default.post(name: .closeAllToRight, object: nil)
                    }
                    
                    Button("Close All Unchanged") {
                        NotificationCenter.default.post(name: .closeAllUnchanged, object: nil)
                    }
                }
                
                Button("Move to Recycle Bin") {
                    NotificationCenter.default.post(name: .moveToTrash, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
                Divider()
                
                // TODO: Load Session...
                // TODO: Save Session...
                
                Divider()
                
                Button("Print...") {
                    NotificationCenter.default.post(name: .printDocument, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
                
                // TODO: Print Now
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
                
                Button("Go to Matching Bracket") {
                    NotificationCenter.default.post(name: .jumpToMatchingBracket, object: nil)
                }
                .keyboardShortcut("m", modifiers: .command)
                
                Divider()
                
                Menu("EOL Conversion") {
                    Button("Windows (CRLF)") {
                        NotificationCenter.default.post(name: .convertEOL, object: EOLType.windows)
                    }
                    
                    Button("Unix (LF)") {
                        NotificationCenter.default.post(name: .convertEOL, object: EOLType.unix)
                    }
                    
                    Button("Mac (CR)") {
                        NotificationCenter.default.post(name: .convertEOL, object: EOLType.macos)
                    }
                }
                
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
                
                Divider()
                
                Button("Find in Files...") {
                    NotificationCenter.default.post(name: .showFindInFiles, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                
                Button("Mark All") {
                    NotificationCenter.default.post(name: .markAll, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .option])
                
                Button("Clear Marks") {
                    NotificationCenter.default.post(name: .clearMarks, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift, .option])
                
                Divider()
                
                Button("Toggle Bookmark") {
                    NotificationCenter.default.post(name: .toggleBookmark, object: nil)
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Button("Next Bookmark") {
                    NotificationCenter.default.post(name: .nextBookmark, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                
                Button("Previous Bookmark") {
                    NotificationCenter.default.post(name: .previousBookmark, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .option])
                
                Button("Show Bookmarks...") {
                    NotificationCenter.default.post(name: .showBookmarks, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .control])
            }
            
            // View menu - matching Notepad++ structure
            CommandMenu("View") {
                Button(action: {
                    AppSettings.shared.showToolbar.toggle()
                }) {
                    HStack {
                        Text("Show Toolbar")
                        if AppSettings.shared.showToolbar {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    AppSettings.shared.showStatusBar.toggle()
                }) {
                    HStack {
                        Text("Show Status Bar")
                        if AppSettings.shared.showStatusBar {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    AppSettings.shared.showTabBar.toggle()
                }) {
                    HStack {
                        Text("Show Tab Bar")
                        if AppSettings.shared.showTabBar {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
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

// MARK: - AppDelegate for handling file opening from Finder
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var documentManager: DocumentManager?
    private var filesOpenedAtLaunch = false
    private var hasCheckedForUntitled = false
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle files dropped on dock icon or opened via "Open With"
        filesOpenedAtLaunch = true
        Task { @MainActor in
            for url in urls {
                await documentManager?.openDocument(from: url)
            }
        }
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Don't create untitled if files are being opened
        return false // We handle untitled creation ourselves
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Don't restore session - app should start fresh every time
        Task { @MainActor in
            // Give time for file opening from Finder if launched with file
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            guard !hasCheckedForUntitled else { return }
            hasCheckedForUntitled = true
            
            if let manager = documentManager, 
               manager.tabs.isEmpty && 
               !filesOpenedAtLaunch {
                // Only create untitled if truly nothing was opened
                manager.createNewDocument()
            }
        }
    }
}

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
    static let showPreferences = Notification.Name("showPreferences")
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let reloadDocument = Notification.Name("reloadDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let saveCopyAs = Notification.Name("saveCopyAs")
    static let saveAllDocuments = Notification.Name("saveAllDocuments")
    static let renameDocument = Notification.Name("renameDocument")
    static let closeTab = Notification.Name("closeTab")
    static let closeAllTabs = Notification.Name("closeAllTabs")
    static let closeOtherTabs = Notification.Name("closeOtherTabs")
    static let closeAllToLeft = Notification.Name("closeAllToLeft")
    static let closeAllToRight = Notification.Name("closeAllToRight")
    static let closeAllUnchanged = Notification.Name("closeAllUnchanged")
    static let moveToTrash = Notification.Name("moveToTrash")
    static let printDocument = Notification.Name("printDocument")
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
    static let showFindInFiles = Notification.Name("showFindInFiles")
    static let showBookmarks = Notification.Name("showBookmarks")
    static let toggleBookmark = Notification.Name("toggleBookmark")
    static let nextBookmark = Notification.Name("nextBookmark")
    static let previousBookmark = Notification.Name("previousBookmark")
    static let markAll = Notification.Name("markAll")
    static let clearMarks = Notification.Name("clearMarks")
    static let jumpToMatchingBracket = Notification.Name("jumpToMatchingBracket")
    static let convertEOL = Notification.Name("convertEOL")
}
