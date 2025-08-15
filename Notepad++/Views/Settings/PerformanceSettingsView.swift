//
//  PerformanceSettingsView.swift
//  Notepad++
//
//  Performance settings - DIRECT PORT from Notepad++ preference.rc
//  Based on IDD_PREFERENCE_SUB_PERFORMANCE dialog
//

import SwiftUI

struct PerformanceSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    
    // These match the exact settings from Notepad++ preference.rc
    @State private var enableLargeFileRestriction: Bool = UserDefaults.standard.bool(forKey: "enableLargeFileRestriction")
    @State private var largeFileSize: Int = UserDefaults.standard.integer(forKey: "largeFileSize") == 0 ? 200 : UserDefaults.standard.integer(forKey: "largeFileSize")
    @State private var deactivateWordWrapGlobally: Bool = UserDefaults.standard.bool(forKey: "deactivateWordWrapGlobally")
    @State private var allowAutoCompletion: Bool = UserDefaults.standard.bool(forKey: "allowAutoCompletionForLargeFiles")
    @State private var allowSmartHighlighting: Bool = UserDefaults.standard.bool(forKey: "allowSmartHighlightingForLargeFiles")
    @State private var allowBraceMatch: Bool = UserDefaults.standard.bool(forKey: "allowBraceMatchForLargeFiles")
    @State private var allowClickableLink: Bool = UserDefaults.standard.bool(forKey: "allowClickableLinkForLargeFiles")
    @State private var suppress2GBWarning: Bool = UserDefaults.standard.bool(forKey: "suppress2GBWarning")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Large File Restriction - matches IDC_GROUPSTATIC_PERFORMANCE_RESTRICTION
            GroupBox("Large File Restriction") {
                VStack(alignment: .leading, spacing: 12) {
                    // Help tip - matches IDD_PERFORMANCE_TIP_QUESTION_BUTTON
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                            .help("Large file restriction helps maintain performance when opening very large files by disabling certain features")
                        Spacer()
                    }
                    
                    // Enable Large File Restriction - matches IDC_CHECK_PERFORMANCE_ENABLE
                    Toggle("Enable Large File Restriction (no syntax highlighting)", isOn: $enableLargeFileRestriction)
                        .onChange(of: enableLargeFileRestriction) {
                            UserDefaults.standard.set(enableLargeFileRestriction, forKey: "enableLargeFileRestriction")
                            settings.disableHighlightingForLargeFiles = enableLargeFileRestriction
                        }
                    
                    // Define Large File Size - matches IDC_EDIT_PERFORMANCE_FILESIZE
                    HStack {
                        Text("Define Large File Size:")
                        TextField("", value: $largeFileSize, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: largeFileSize) {
                                let clampedValue = min(max(largeFileSize, 1), 2046)
                                UserDefaults.standard.set(clampedValue, forKey: "largeFileSize")
                                settings.largeFileSize = clampedValue
                            }
                        Text("MB   (1 - 2046)")
                    }
                    
                    // Options for large files - all from the original dialog
                    VStack(alignment: .leading, spacing: 8) {
                        // Deactivate Word Wrap globally - matches IDC_CHECK_PERFORMANCE_DEACTIVATEWORDWRAP
                        Toggle("Deactivate Word Wrap globally", isOn: $deactivateWordWrapGlobally)
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: deactivateWordWrapGlobally) {
                                UserDefaults.standard.set(deactivateWordWrapGlobally, forKey: "deactivateWordWrapGlobally")
                            }
                            .padding(.leading, 40)
                        
                        // Allow Auto-Completion - matches IDC_CHECK_PERFORMANCE_ALLOWAUTOCOMPLETION
                        Toggle("Allow Auto-Completion", isOn: $allowAutoCompletion)
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: allowAutoCompletion) {
                                UserDefaults.standard.set(allowAutoCompletion, forKey: "allowAutoCompletionForLargeFiles")
                                settings.disableAutoCompletionForLargeFiles = !allowAutoCompletion
                            }
                            .padding(.leading, 40)
                        
                        // Allow Smart Highlighting - matches IDC_CHECK_PERFORMANCE_ALLOWSMARTHILITE
                        Toggle("Allow Smart Highlighting", isOn: $allowSmartHighlighting)
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: allowSmartHighlighting) {
                                UserDefaults.standard.set(allowSmartHighlighting, forKey: "allowSmartHighlightingForLargeFiles")
                            }
                            .padding(.leading, 40)
                        
                        // Allow Brace Match - matches IDC_CHECK_PERFORMANCE_ALLOWBRACEMATCH
                        Toggle("Allow Brace Match", isOn: $allowBraceMatch)
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: allowBraceMatch) {
                                UserDefaults.standard.set(allowBraceMatch, forKey: "allowBraceMatchForLargeFiles")
                            }
                            .padding(.leading, 40)
                        
                        // Allow URL Clickable Link - matches IDC_CHECK_PERFORMANCE_ALLOWCLICKABLELINK
                        Toggle("Allow URL Clickable Link", isOn: $allowClickableLink)
                            .disabled(!enableLargeFileRestriction)
                            .onChange(of: allowClickableLink) {
                                UserDefaults.standard.set(allowClickableLink, forKey: "allowClickableLinkForLargeFiles")
                            }
                            .padding(.leading, 40)
                    }
                    
                    Divider()
                    
                    // Suppress warning when opening ≥2GB files - matches IDC_CHECK_PERFORMANCE_SUPPRESS2GBWARNING
                    Toggle("Suppress warning when opening ≥2GB files", isOn: $suppress2GBWarning)
                        .onChange(of: suppress2GBWarning) {
                            UserDefaults.standard.set(suppress2GBWarning, forKey: "suppress2GBWarning")
                        }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}