//
//  LanguageMenuView.swift
//  Notepad++
//
//  Language selection menu matching Notepad++ structure
//

import SwiftUI

struct LanguageMenuView: View {
    var body: some View {
        // Simplified menu for now - will expand later
        ForEach(LanguageManager.shared.availableLanguages.prefix(20), id: \.name) { language in
            Button(language.name.capitalized) {
                LanguageManager.shared.setLanguage(language)
            }
        }
    }
}