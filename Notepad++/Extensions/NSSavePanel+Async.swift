//
//  NSSavePanel+Async.swift
//  Notepad++
//
//  Extension to add async/await support to NSSavePanel
//

import AppKit

extension NSSavePanel {
    @MainActor
    func beginAsync() async -> NSApplication.ModalResponse {
        await withCheckedContinuation { continuation in
            self.begin { response in
                continuation.resume(returning: response)
            }
        }
    }
}

// NSOpenPanel inherits from NSSavePanel, so it already has beginAsync()