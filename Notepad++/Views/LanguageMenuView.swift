//
//  LanguageMenuView.swift
//  Notepad++
//
//  Language selection menu matching Notepad++ structure
//

import SwiftUI

struct LanguageMenuView: View {
    @EnvironmentObject var documentManager: DocumentManager
    
    var body: some View {
        // Simplified menu for now - will expand later
        ForEach(LanguageManager.shared.availableLanguages.prefix(20), id: \.name) { language in
            Button(language.name.capitalized) {
                // Set language for the current document only
                if let activeTab = documentManager.activeTab {
                    activeTab.document.language = language.toLanguageDefinition()
                }
            }
        }
    }
}