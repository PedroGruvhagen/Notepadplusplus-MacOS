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
    @StateObject private var menuState = MenuCommandState.shared
    @StateObject private var updaterManager = UpdaterManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Disable macOS window state restoration to prevent files from being pre-opened
        // This ensures the app starts fresh every time
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
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
            // Sparkle 2 (UpdaterManager.swift). Placed after .appInfo (About Notepad++), the
            // conventional macOS location for "Check for Updates...", matching Sparkle's own
            // default template. canCheckForUpdates mirrors SPUUpdater.canCheckForUpdates, so this
            // greys out while a check/update is already in progress instead of allowing a second
            // overlapping one.
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterManager.checkForUpdates()
                }
                .disabled(!updaterManager.canCheckForUpdates)
            }

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
            
            // Undo/Redo and Cut/Copy/Paste/Select All are intentionally NOT overridden:
            // the standard AppKit Edit menu drives the first-responder NSTextView directly
            // (allowsUndo is enabled), so Cmd+Z/X/C/V/A work natively. Replacing them with
            // notification-posting buttons routed to a dead listener, which is why undo and
            // the clipboard commands did nothing.

            CommandGroup(after: .textEditing) {
                Divider()
                
                Button("Go to Matching Bracket") {
                    NotificationCenter.default.post(name: .jumpToMatchingBracket, object: nil)
                }
                .keyboardShortcut("m", modifiers: .command)
                // F57: greyed out unless the caret is on a matching brace, driven by the real
                // enableCommand(IDM_SEARCH_GOTOMATCHINGBRACE, ...) state (Notepad_plus.cpp:3020).
                .disabled(!menuState.canGotoMatchingBracket)
                
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
                LanguageMenuView(documentManager: documentManager)
            }

            // Help menu - replaces the default, non-functional macOS Help group with working
            // links, a Debug Info panel, and the in-app Help window. Kept in its own Commands
            // type so it can use @Environment(\.openWindow) (the App struct cannot read the
            // environment). Translated from the Windows "?" menu (Notepad_plus.rc).
            HelpCommands()
        }

        // Secondary windows opened from the Help menu. They are declared after the primary
        // WindowGroup so the document window is what opens at launch; these stay closed until
        // openWindow(id:) is called from HelpCommands. Deployment target is macOS 15.5, so the
        // Window scene and openWindow are available (both require macOS 13+).
        Window("Notepad++ Help", id: HelpScene.help) {
            HelpWindowView()
        }
        .defaultSize(width: 820, height: 560)

        Window("Debug Info", id: HelpScene.debugInfo) {
            HelpDebugInfoView()
        }
        .defaultSize(width: 560, height: 420)
    }
}

// MARK: - Menu command enable state (F57)
// Notepad++ greys menu items via enableCommand -> ::EnableMenuItem (Notepad_plus.cpp:2521); braceMatch
// enables/disables "Go to Matching Bracket" as the caret moves on/off a matching brace
// (Notepad_plus.cpp:3020). The Swift editor already posts .commandStateChanged from enableCommand
// (NSTextView+ScintillaAPI.swift:334) but nothing observed it, so the item never greyed out. This
// observable turns those posts into a @Published flag the SwiftUI menu binds its .disabled() to.
@MainActor
final class MenuCommandState: ObservableObject {
    static let shared = MenuCommandState()
    @Published var canGotoMatchingBracket = false

    private init() {
        NotificationCenter.default.addObserver(forName: .commandStateChanged, object: nil, queue: .main) { [weak self] note in
            guard let enabled = note.userInfo?["enabled"] as? Bool,
                  let command = note.userInfo?["commandID"] as? CommandID else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                // Only publish on an actual change: braceMatch posts this on every caret move, and an
                // unconditional assignment would rebuild the menu each keystroke/arrow-key.
                if case .searchGotoMatchingBrace = command, self.canGotoMatchingBracket != enabled {
                    self.canGotoMatchingBracket = enabled
                }
            }
        }
    }
}

// MARK: - AppDelegate for handling file opening from Finder
class AppDelegate: NSObject, NSApplicationDelegate {
    // Assigned in ContentView.onAppear. Kept only as an extra drain trigger: opens go through
    // DocumentManager.shared directly so a launch URL is never dropped while this weak
    // reference is still nil (F28).
    weak var documentManager: DocumentManager? {
        didSet { drainPendingLaunchURLs() }
    }
    private var hasCheckedForUntitled = false

    // Launch/open URLs are queued the instant AppKit delivers them and drained through the
    // shared DocumentManager, independent of when the SwiftUI window wiring runs. AppKit can
    // deliver application(_:open:) for a double-clicked file before applicationDidFinishLaunching
    // and before ContentView.onAppear assigns documentManager; the previous code read a
    // not-yet-wired weak var and silently dropped every such URL. Translation of the never-drop
    // contract of loadCommandlineParams (Notepad_plus.cpp:6893), where command-line files are
    // opened in the launch path after the core is initialised and are never lost to UI timing (F28).
    private var pendingLaunchURLs: [URL] = []
    private var isDrainingLaunchURLs = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Disable window state restoration BEFORE anything happens
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Files dropped on the dock icon or opened via Finder / "Open With". Queue them and
        // drain immediately; never drop a URL because the SwiftUI wiring has not run yet.
        pendingLaunchURLs.append(contentsOf: urls)
        drainPendingLaunchURLs()
    }

    // Drains queued launch URLs through the shared DocumentManager. isDrainingLaunchURLs is set
    // synchronously so applicationDidFinishLaunching can tell a launch open is in flight and skip
    // the fresh-untitled fallback. The lone-clean-untitled guard in openDocument(from:) (F27)
    // keeps every ordering correct: if an untitled was created first, the opened file replaces it.
    private func drainPendingLaunchURLs() {
        guard !pendingLaunchURLs.isEmpty, !isDrainingLaunchURLs else { return }
        isDrainingLaunchURLs = true
        let urls = pendingLaunchURLs
        pendingLaunchURLs.removeAll()
        Task { @MainActor in
            for url in urls {
                await DocumentManager.shared.openDocument(from: url)
            }
            isDrainingLaunchURLs = false
            // Anything queued while we were awaiting gets drained on the next pass.
            drainPendingLaunchURLs()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Don't create untitled if files are being opened
        return false // We handle untitled creation ourselves
    }

    // Guard Cmd+Q / Quit so unsaved documents prompt to save first (NppIO.cpp fileCloseAll).
    // Uses DocumentManager.shared directly so the prompt is never skipped by a nil weak var.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let manager = DocumentManager.shared
        guard manager.hasModifiedDocuments else {
            return .terminateNow
        }
        Task { @MainActor in
            let canTerminate = await manager.confirmCloseAllForQuit()
            sender.reply(toApplicationShouldTerminate: canTerminate)
        }
        return .terminateLater
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Drain any launch URLs that AppKit delivered before launch finished, so a double-clicked
        // file is opened and never dropped (loadCommandlineParams, Notepad_plus.cpp:6893).
        // openDocument(from:) replaces a lone clean untitled when a real file is opened (F27 guard).
        drainPendingLaunchURLs()

        guard !hasCheckedForUntitled else { return }
        hasCheckedForUntitled = true

        Task { @MainActor in
            // F35: restore the previous session (crash recovery / remember-last-session) BEFORE
            // falling back to a fresh untitled, but never when a launch-file open is in flight -
            // the double-clicked file wins, exactly as Notepad++ loads the session in the startup
            // path before command-line files. The periodic snapshot timer (BackupManager) is what
            // makes this survive a crash or force-quit, where appWillTerminate never fires.
            if AppSettings.shared.rememberLastSession,
               !self.isDrainingLaunchURLs,
               self.pendingLaunchURLs.isEmpty,
               DocumentManager.shared.tabs.isEmpty {
                await BackupManager.shared.restoreSession()
            }

            // Only fall back to a fresh untitled when nothing else populated tabs (no launch file,
            // no restored session).
            if !self.isDrainingLaunchURLs, self.pendingLaunchURLs.isEmpty, DocumentManager.shared.tabs.isEmpty {
                DocumentManager.shared.createNewDocument()
            }
        }
    }
}

// MARK: - Window close guard
// SwiftUI WindowGroup windows have no save-on-close hook, so closing via the red
// traffic-light button discarded unsaved documents silently. This accessor installs an
// NSWindowDelegate that runs the same unsaved-changes prompt as Quit before the window closes.
struct WindowCloseGuard: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { context.coordinator.attach(to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.window == nil {
            DispatchQueue.main.async { context.coordinator.attach(to: nsView.window) }
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        weak var window: NSWindow?
        private var isClosing = false
        // F08: SwiftUI installs its own NSWindowDelegate (AppKitWindowController) that handles
        // ~19 scene-bookkeeping callbacks (resize policy, zoom frame, fullscreen options,
        // restorable state, close bookkeeping). Keep a reference so we can forward every selector
        // we do not implement to it. weak: the controller is retained by the window/scene, so a
        // strong reference here would create a retain cycle.
        private weak var previousDelegate: NSWindowDelegate?

        func attach(to window: NSWindow?) {
            guard let window, self.window == nil else { return }
            self.window = window
            // F08: keep SwiftUI's own window delegate so its scene-bookkeeping callbacks (resize,
            // zoom, fullscreen, restorable state, close bookkeeping) keep firing; we intercept only
            // windowShouldClose. Forwarding is via responds(to:)/forwardingTarget(for:) below. This
            // restores the SwiftUI WindowGroup delegate chain while preserving the WM_CLOSE ->
            // fileCloseAll save prompt (NppBigSwitch.cpp:2710, NppIO.cpp:1377-1394) that
            // windowShouldClose implements. No direct Scintilla counterpart; AppKit integration hygiene.
            if let existing = window.delegate, existing !== self {
                previousDelegate = existing
            }
            window.delegate = self
        }

        // F08: forward every NSWindowDelegate selector we do not implement to SwiftUI's original
        // delegate, overriding ONLY windowShouldClose (below).
        override func responds(to aSelector: Selector!) -> Bool {
            if super.responds(to: aSelector) { return true }
            return previousDelegate?.responds(to: aSelector) ?? false
        }

        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            if let previousDelegate, previousDelegate.responds(to: aSelector) { return previousDelegate }
            return super.forwardingTarget(for: aSelector)
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            if isClosing { return true }
            Task { @MainActor in
                if await DocumentManager.shared.confirmCloseAllForQuit() {
                    // The prompts have been answered (saved or discarded). Actually close the
                    // buffers and leave one fresh untitled, matching WM_CLOSE -> fileCloseAll
                    // (NppBigSwitch.cpp:2710, NppIO.cpp:1377-1394). Without this the discarded
                    // dirty tabs survive and the next close re-prompts for documents the user
                    // already declined (F30).
                    DocumentManager.shared.resetToFreshUntitled()
                    isClosing = true
                    sender.close()
                }
            }
            return false  // defer; close happens above only if the user did not cancel
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
