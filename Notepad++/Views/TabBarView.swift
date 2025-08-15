//
//  TabBarView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var documentManager: DocumentManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(documentManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isActive: documentManager.activeTab == tab,
                        onSelect: {
                            documentManager.activeTab = tab
                        },
                        onClose: {
                            documentManager.closeTab(tab)
                        }
                    )
                }
                
                Button(action: {
                    documentManager.createNewDocument()
                }) {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 28)
                        .background(Color(NSColor.controlBackgroundColor))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("New Tab")
            }
        }
        .frame(height: 32)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TabItemView: View {
    let tab: EditorTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 11))
                .foregroundColor(isActive ? .accentColor : .secondary)
            
            Text(tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isActive ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isActive ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}