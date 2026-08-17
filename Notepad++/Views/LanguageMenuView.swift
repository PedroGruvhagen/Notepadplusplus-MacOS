//
//  LanguageMenuView.swift
//  Notepad++
//
//  Language selection menu matching Notepad++ structure
//

import SwiftUI

// Translation of Notepad_plus::checkLangsMenu / doCheck (Notepad_plus.cpp:2778, 2749): exactly one
// Language menu item is radio-checked, matching the ACTIVE buffer's language. checkLangsMenu(-1) is
// invoked both when the active buffer changes (Notepad_plus.cpp:2633, part of the buffer-activation
// menu refresh) and whenever BufferChangeLanguage fires (Notepad_plus.cpp:6787-6789, the notify
// handler for a language change on the current buffer). A buffer with no language explicitly set
// defaults to L_TEXT / "Normal" (Buffer.h:419 `_lang = L_TEXT`), so a nil Document.language checks
// "Normal" too.
struct LanguageMenuView: View {
    // Injected explicitly from the App's @StateObject rather than @EnvironmentObject: the
    // .commands builder is not part of the WindowGroup content hierarchy, so the
    // .environmentObject(documentManager) applied to ContentView (Notepad__App.swift:26) does
    // not reach it. Menus that need observable state reference the App's objects directly
    // (same idiom as menuState, Notepad__App.swift:157).
    @ObservedObject var documentManager: DocumentManager

    var body: some View {
        if let activeTab = documentManager.activeTab {
            // Split into a subview so it can hold @ObservedObject on the concrete active Document
            // (an Optional can't itself conform to ObservableObject). This is what makes the
            // checkmark react to a language change on the active document, not just a tab switch.
            ActiveDocumentLanguageMenuItems(document: activeTab.document)
        } else {
            // No document open: harmless, matches doCheck(id: -1) unchecking everything. The guard
            // in ActiveDocumentLanguageMenuItems.body already no-ops the action when there's no
            // active tab, so this branch only needs to avoid crashing / show nothing checked.
            ForEach(LanguageManager.shared.availableLanguages, id: \.name) { language in
                Text(language.name.capitalized)
            }
        }
    }
}

private struct ActiveDocumentLanguageMenuItems: View {
    @ObservedObject var document: Document

    private static let topUsedCount = 5

    var body: some View {
        let currentName = document.language?.name ?? "normal"
        let allLanguages = LanguageManager.shared.availableLanguages
        let topLanguages = LanguageManager.shared.topUsedLanguages(limit: Self.topUsedCount)
        let topNames = Set(topLanguages.map { $0.name })
        let remainingLanguages = allLanguages.filter { !topNames.contains($0.name) }

        ForEach(topLanguages, id: \.name) { language in
            languageButton(for: language, currentName: currentName)
        }

        if !topLanguages.isEmpty {
            Divider()
        }

        ForEach(remainingLanguages, id: \.name) { language in
            languageButton(for: language, currentName: currentName)
        }
    }

    @ViewBuilder
    private func languageButton(for language: Lang, currentName: String) -> some View {
        let definition = language.toLanguageDefinition()

        Button(action: {
            // Set language for the current document only
            document.language = definition
            // Track real usage so the top-5 "most used" section reflects actual selections.
            AppSettings.shared.recordLanguageUsage(language.name)
        }) {
            HStack {
                Text(language.name.capitalized)
                if definition?.name == currentName {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
