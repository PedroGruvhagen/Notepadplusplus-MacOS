//
//  ContentView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var documentManager = DocumentManager()
    @State private var searchText = ""
    
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
    }
    
    private func setupMenuCommands() {
        // This will be used for menu bar customization
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
