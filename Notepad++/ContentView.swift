//
//  ContentView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var searchText = ""
    @State private var isShowingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(documentManager: documentManager)
            
            Divider()
            
            if let activeTab = documentManager.activeTab {
                EditorView(document: activeTab.document)
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    documentManager.createNewDocument()
                }) {
                    Label("New", systemImage: "doc.badge.plus")
                }
                
                Button(action: {
                    documentManager.openDocument()
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
