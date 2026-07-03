//
//  ContentView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var menuCommands = MenuCommandCoordinator()
    @State private var searchText = ""
    @State private var isShowingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            if settings.showTabBar {
                if settings.tabBarPosition == .top {
                    TabBarView(documentManager: documentManager)
                    Divider()
                }
            }
            
            if let activeTab = documentManager.activeTab {
                EditorView(document: activeTab.document)
            } else {
                EmptyStateView()
            }
            
            if settings.showTabBar {
                if settings.tabBarPosition == .bottom {
                    Divider()
                    TabBarView(documentManager: documentManager)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(WindowCloseGuard())
        .toolbar(settings.showToolbar ? .visible : .hidden)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    documentManager.createNewDocument()
                }) {
                    Label("New", systemImage: "doc.badge.plus")
                }
                
                Button(action: {
                    Task { @MainActor in
                        await documentManager.openDocument()
                    }
                }) {
                    Label("Open", systemImage: "folder")
                }
                
                Button(action: {
                    if let activeTab = documentManager.activeTab {
                        Task {
                            await documentManager.saveDocument(activeTab)
                        }
                    }
                }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(documentManager.activeTab == nil)
            }
        }
        .searchable(text: $searchText, placement: .toolbar)
        .onAppear {
            menuCommands.start()
        }
        .onDisappear {
            menuCommands.stop()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPreferences)) { _ in
            isShowingSettings = true
        }
    }
}

// F32: Menu command NotificationCenter observers used to be registered directly in
// ContentView.onAppear via setupMenuCommands(), and every returned token was discarded.
// Block-based observers persist until removed via their token, so with the tokens gone
// they could never be removed. Each window close/reopen cycle created a fresh ContentView
// and added another full set, so after k cycles every menu command fired k+1 times
// (Cmd+N made k+1 tabs, Cmd+W fired k+1 close tasks, etc.).
//
// This coordinator fixes that by retaining every observer token in `observers` so they can
// be removed, and by making start() idempotent (guard observers.isEmpty) so repeated
// onAppear calls never stack duplicates. stop() (from onDisappear) and deinit (safety net)
// remove every token, so window reopen cycles never accumulate observers.
//
// It references DocumentManager.shared directly. The @EnvironmentObject documentManager that
// ContentView injects IS DocumentManager.shared (Notepad__App.swift:13/25), matching the
// existing app pattern (AppDelegate also uses DocumentManager.shared directly).
@MainActor
final class MenuCommandCoordinator: ObservableObject {
    private var observers: [NSObjectProtocol] = []

    func start() {
        // Idempotent: if observers are already registered, do nothing so repeated
        // onAppear calls never stack duplicate handlers.
        guard observers.isEmpty else { return }

        observers.append(NotificationCenter.default.addObserver(
            forName: .newDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                DocumentManager.shared.createNewDocument()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .openDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.openDocument()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .saveDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = DocumentManager.shared.activeTab {
                    await DocumentManager.shared.saveDocument(activeTab)
                }
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .saveDocumentAs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = DocumentManager.shared.activeTab {
                    await DocumentManager.shared.saveDocumentAs(activeTab)
                }
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .saveAllDocuments,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.saveAllDocuments()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = DocumentManager.shared.activeTab {
                    await DocumentManager.shared.closeTab(activeTab)
                }
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeAllTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.closeAllTabs()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeOtherTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.closeOtherTabs()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeAllToLeft,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.closeAllToLeft()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeAllToRight,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.closeAllToRight()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .closeAllUnchanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                DocumentManager.shared.closeAllUnchanged()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .moveToTrash,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.moveToTrash()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .reloadDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await DocumentManager.shared.reloadDocument()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .saveCopyAs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = DocumentManager.shared.activeTab {
                    await DocumentManager.shared.saveCopyAs(activeTab)
                }
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .renameDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = DocumentManager.shared.activeTab {
                    await DocumentManager.shared.renameDocument(activeTab)
                }
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .printDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                DocumentManager.shared.printDocument()
            }
        })

        // F51: double-clicking a row in the Bookmarks panel posts .navigateToBookmark with a file path
        // and 1-based line. Open that file (reusing the Phase 6 open + dedup) and reveal the line,
        // like Notepad++ jumping to a bookmarked location.
        observers.append(NotificationCenter.default.addObserver(
            forName: .navigateToBookmark,
            object: nil,
            queue: .main
        ) { note in
            guard let url = note.userInfo?["filePath"] as? URL,
                  let lineNumber = note.userInfo?["lineNumber"] as? Int else { return }
            Task { @MainActor in
                await DocumentManager.shared.openDocument(from: url)
                if let document = DocumentManager.shared.activeTab?.document {
                    let start = document.lineStartPosition(max(0, lineNumber - 1))
                    document.revealRange(NSRange(location: start, length: 0))
                }
            }
        })

        // Copy/Paste/Cut/SelectAll/Undo/Redo are handled by the live editor (DocumentTextEditor)
        // and the standard AppKit responder chain, not by a NotificationCenter observer here.
        // Keeping them out of this observer set avoids duplicate event handling and paste duplication.
    }

    func stop() {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
        observers.removeAll()
    }

    deinit {
        // Safety net: remove any still-registered tokens even if onDisappear did not fire
        // on teardown. deinit is nonisolated and NotificationCenter.removeObserver is
        // thread-safe, so iterating the stored tokens here is safe.
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Document Open")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Create a new document or open an existing file")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

#Preview {
    ContentView()
}
