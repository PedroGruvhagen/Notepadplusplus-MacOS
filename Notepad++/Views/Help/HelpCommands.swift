//
//  HelpCommands.swift
//  Notepad++
//
//  Replaces the default (non-functional) macOS Help menu with a working one. Translated
//  from the Windows "?" menu (PowerEditor/src/Notepad_plus.rc, the POPUP "&?" block) and
//  its command handlers in PowerEditor/src/NppCommands.cpp: Notepad++ Home
//  (IDM_HOMESWEETHOME), Project Page (IDM_PROJECTPAGE), Online User Manual
//  (IDM_ONLINEDOCUMENT), Community Forum (IDM_FORUM), Update Notepad++ (IDM_UPDATE_NPP),
//  and Debug Info (IDM_DEBUGINFO). The Windows-only items (Command Line Arguments and
//  Set Updater Proxy) have no macOS counterpart and are deliberately not included.
//
//  A separate Commands type is used so @Environment(\.openWindow) is available; the App
//  struct itself cannot read environment values.
//

import SwiftUI

struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Notepad++ Help") {
                openWindow(id: HelpScene.help)
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Button("Notepad++ Home") {
                Self.open("https://notepad-plus-plus.org/")
            }
            Button("Notepad++ macOS Project Page") {
                Self.open(HelpContent.projectURL)
            }
            Button("Online User Manual") {
                Self.open("https://npp-user-manual.org/")
            }
            Button("Community (Forum)") {
                Self.open("https://community.notepad-plus-plus.org/")
            }

            Divider()

            Button("Check for Updates...") {
                Self.open("\(HelpContent.projectURL)/releases")
            }

            Divider()

            Button("Debug Info...") {
                openWindow(id: HelpScene.debugInfo)
            }
        }
    }

    private static func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
