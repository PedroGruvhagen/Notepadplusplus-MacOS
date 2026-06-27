//
//  TabBarView.swift
//  Notepad++
//
//  Created by Pedro Gruvhagen on 2025-08-15.
//

import SwiftUI
import AppKit

// Port of the Notepad++ middle-click-close behaviour: clicking the scroll-wheel
// button (buttonNumber == 2) anywhere on a tab closes it via the same path as the
// xmark button, including the unsaved-changes prompt.
//
// NSViewRepresentable whose backing view intercepts otherMouseDown events.
// hitTest returns self only for other-mouse events so that left-clicks and
// right-clicks continue to reach SwiftUI's onTapGesture and context menus.
private struct MiddleClickCloseArea: NSViewRepresentable {
    let onMiddleClick: () -> Void

    func makeNSView(context: Context) -> MiddleClickView {
        let view = MiddleClickView()
        view.onMiddleClick = onMiddleClick
        return view
    }

    func updateNSView(_ nsView: MiddleClickView, context: Context) {
        nsView.onMiddleClick = onMiddleClick
    }

    class MiddleClickView: NSView {
        var onMiddleClick: (() -> Void)?

        // Pass-through for all pointer events except other-mouse-down: returning nil
        // lets SwiftUI's gesture recognisers process left/right clicks normally.
        override func hitTest(_ point: NSPoint) -> NSView? {
            if let event = NSApp.currentEvent, event.type == .otherMouseDown {
                return self
            }
            return nil
        }

        override func otherMouseDown(with event: NSEvent) {
            if event.buttonNumber == 2 {
                onMiddleClick?()
            }
        }
    }
}

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
                            Task { @MainActor in
                                await documentManager.closeTab(tab)
                            }
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
        .overlay(
            // Middle-click (scroll-wheel button) closes the tab via the same path
            // as the xmark button, including the unsaved-changes prompt. Left-click
            // and right-click pass through because hitTest returns nil for them.
            MiddleClickCloseArea(onMiddleClick: onClose)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}