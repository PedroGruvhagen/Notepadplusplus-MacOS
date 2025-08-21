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
                    documentManager.closeTab(activeTab)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeAllTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                documentManager.closeAllTabs()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeOtherTabs,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                documentManager.closeOtherTabs()
            }
        }
        
        // Copy/Paste/Cut handlers
        NotificationCenter.default.addObserver(
            forName: .copy,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's performTextFinderAction to handle copy
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder.responds(to: #selector(NSText.copy(_:))) {
                firstResponder.perform(#selector(NSText.copy(_:)), with: nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .paste,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's performTextFinderAction to handle paste
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder.responds(to: #selector(NSText.paste(_:))) {
                firstResponder.perform(#selector(NSText.paste(_:)), with: nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .cut,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's performTextFinderAction to handle cut
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder.responds(to: #selector(NSText.cut(_:))) {
                firstResponder.perform(#selector(NSText.cut(_:)), with: nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .selectAll,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's performTextFinderAction to handle select all
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder.responds(to: #selector(NSText.selectAll(_:))) {
                firstResponder.perform(#selector(NSText.selectAll(_:)), with: nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .undo,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's undo manager
            if let undoManager = NSApp.keyWindow?.firstResponder?.undoManager {
                undoManager.undo()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .redo,
            object: nil,
            queue: .main
        ) { _ in
            // Use the system's undo manager
            if let undoManager = NSApp.keyWindow?.firstResponder?.undoManager {
                undoManager.redo()
            }
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
