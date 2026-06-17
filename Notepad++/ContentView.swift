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
            setupMenuCommands()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPreferences)) { _ in
            isShowingSettings = true
        }
    }
    
    private func setupMenuCommands() {
        // Listen for menu commands
        NotificationCenter.default.addObserver(
            forName: .newDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                documentManager.createNewDocument()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .openDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.openDocument()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .saveDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = documentManager.activeTab {
                    await documentManager.saveDocument(activeTab)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .saveDocumentAs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = documentManager.activeTab {
                    await documentManager.saveDocumentAs(activeTab)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .saveAllDocuments,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.saveAllDocuments()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = documentManager.activeTab {
                    await documentManager.closeTab(activeTab)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeAllTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.closeAllTabs()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeOtherTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.closeOtherTabs()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeAllToLeft,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.closeAllToLeft()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeAllToRight,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.closeAllToRight()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .closeAllUnchanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                documentManager.closeAllUnchanged()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .moveToTrash,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.moveToTrash()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .reloadDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await documentManager.reloadDocument()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .saveCopyAs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = documentManager.activeTab {
                    await documentManager.saveCopyAs(activeTab)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .renameDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let activeTab = documentManager.activeTab {
                    await documentManager.renameDocument(activeTab)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .printDocument,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                documentManager.printDocument()
            }
        }

        // Copy/Paste/Cut/SelectAll/Undo/Redo handlers are now handled by SyntaxTextEditor.Coordinator
        // to prevent duplicate event handling and paste duplication bugs
        // This centralizes all text editing commands in one location for better maintainability
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
