//
//  HelpDebugInfoView.swift
//  Notepad++
//
//  A small panel that reports version, system, and install-path information for bug
//  reports, with a button to copy it to the clipboard. This is the macOS translation of
//  the Windows IDM_DEBUGINFO dialog (PowerEditor/src/WinControls/AboutDlg/AboutDlg.cpp),
//  which assembles a version + architecture + path block and offers a copy button. Every
//  value here is read at runtime; only the field labels are fixed text.
//

import SwiftUI

struct HelpDebugInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Info")
                .font(.title2)
                .fontWeight(.bold)

            ScrollView {
                Text(Self.debugInfoText)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 200)
            .background(Color(NSColor.textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Button {
                    copyToClipboard()
                } label: {
                    Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }

                Spacer()

                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 320)
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(Self.debugInfoText, forType: .string)
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { didCopy = false }
    }

    // MARK: - Runtime values

    /// The whole block, also what the Copy button places on the pasteboard.
    static var debugInfoText: String {
        var lines: [String] = []
        lines.append("Notepad++ for macOS \(HelpContent.appVersion) (build \(HelpContent.buildNumber))")
        lines.append("Architecture: \(machineArchitecture)")
        lines.append("macOS: \(operatingSystemVersion)")
        lines.append("Path: \(Bundle.main.bundlePath)")
        lines.append("Project: \(HelpContent.projectURL)")
        return lines.joined(separator: "\n")
    }

    /// The hardware architecture the process is running on (for example arm64 or x86_64).
    /// Read from uname so it reflects the CPU, including when running under Rosetta.
    static var machineArchitecture: String {
        var info = utsname()
        uname(&info)
        let machine = withUnsafeBytes(of: &info.machine) { raw -> String in
            let bytes = raw.prefix { $0 != 0 }
            return String(decoding: bytes, as: UTF8.self)
        }
        return machine.isEmpty ? "unknown" : machine
    }

    static var operatingSystemVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
}
