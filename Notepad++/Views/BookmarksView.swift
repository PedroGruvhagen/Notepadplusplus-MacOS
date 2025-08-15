//
//  BookmarksView.swift
//  Notepad++
//
//  Bookmarks management interface
//

import SwiftUI

struct BookmarksView: View {
    @StateObject private var searchManager = AdvancedSearchManager.shared
    @State private var selectedBookmark: Bookmark?
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var filteredBookmarks: [Bookmark] {
        if searchText.isEmpty {
            return searchManager.bookmarks
        } else {
            return searchManager.bookmarks.filter { bookmark in
                bookmark.fileName.localizedCaseInsensitiveContains(searchText) ||
                bookmark.lineContent.localizedCaseInsensitiveContains(searchText) ||
                (bookmark.label?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Bookmarks list
            if searchManager.bookmarks.isEmpty {
                emptyStateView
            } else {
                bookmarksListView
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle("Bookmarks")
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search bookmarks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            Spacer()
            
            Button(action: {
                searchManager.clearBookmarks()
            }) {
                Label("Clear All", systemImage: "trash")
            }
            .disabled(searchManager.bookmarks.isEmpty)
            
            Button("Close") {
                dismiss()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No bookmarks")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Press ⌘B to bookmark the current line")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bookmarksListView: some View {
        List(selection: $selectedBookmark) {
            ForEach(filteredBookmarks) { bookmark in
                BookmarkRow(bookmark: bookmark)
                    .tag(bookmark)
                    .onTapGesture(count: 2) {
                        navigateToBookmark(bookmark)
                    }
            }
        }
        .contextMenu {
            if let selected = selectedBookmark {
                Button("Go to Bookmark") {
                    navigateToBookmark(selected)
                }
                
                Button("Remove Bookmark") {
                    searchManager.removeBookmark(selected)
                }
                
                Divider()
                
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(selected.filePath.path, forType: .string)
                }
            }
        }
    }
    
    private func navigateToBookmark(_ bookmark: Bookmark) {
        NotificationCenter.default.post(
            name: .navigateToBookmark,
            object: nil,
            userInfo: [
                "filePath": bookmark.filePath,
                "lineNumber": bookmark.lineNumber
            ]
        )
        dismiss()
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bookmark.fileName)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Line \(bookmark.lineNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let label = bookmark.label {
                        Text("• \(label)")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    Text(relativeDateString(for: bookmark.dateCreated))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(bookmark.lineContent)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(bookmark.filePath.path)
                    .font(.caption2)
                    .foregroundColor(Color.secondary.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension Bookmark {
    var fileName: String {
        filePath.lastPathComponent
    }
}