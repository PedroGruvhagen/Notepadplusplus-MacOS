//
//  UpdaterManager.swift
//  Notepad++
//
//  Sparkle 2 auto-update integration. Wraps SPUStandardUpdaterController and exposes what
//  Settings > General > Updates (GeneralSettingsView) and the "Check for Updates..." menu items
//  (Notepad__App CommandGroup(after: .appInfo), HelpCommands) need: whether a check can currently
//  run, triggering one, and pushing the persisted preferences (AppSettings.checkForUpdates /
//  updateIntervalDays) into the live updater so the UI and the updater never disagree.
//
//  This is new infrastructure (Notepad++ Windows has its own bespoke updater in
//  WinControls/DoSomethingWithFileDlg / the WinGup child process, NppNotification.cpp
//  IDM_UPDATE_NPP), not a Scintilla/Notepad++ C++ routine to translate; Sparkle is the standard
//  macOS equivalent, wired the same way its own documented SwiftUI integration recommends.
//

import Foundation
import Combine
import Sparkle

@MainActor
final class UpdaterManager: ObservableObject {
    static let shared = UpdaterManager()

    private let controller: SPUStandardUpdaterController

    /// Mirrors SPUUpdater.canCheckForUpdates (false while a check/update is already running, or
    /// before the updater has finished starting up), so menu items and the Settings button disable
    /// themselves instead of allowing a second overlapping check.
    @Published private(set) var canCheckForUpdates = false

    private init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)

        applyPersistedSettings()
    }

    /// Mirrors AppSettings.checkForUpdates (Settings > General > Updates > "Check for updates
    /// automatically"). Sparkle runs its own periodic timer against updateCheckInterval while true.
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Seconds between automatic checks. Sparkle enforces a 3600s (1 hour) floor internally;
    /// clampedInterval(days:) below applies the same floor before assigning so the stored value
    /// the Settings field shows and the value Sparkle actually uses never disagree.
    var updateCheckInterval: TimeInterval {
        get { controller.updater.updateCheckInterval }
        set { controller.updater.updateCheckInterval = newValue }
    }

    /// Applies the persisted AppSettings values to the live updater. Called at startup (so the
    /// updater and the Settings UI agree from the first launch, before any user interaction) and
    /// again whenever the Settings controls change.
    func applyPersistedSettings() {
        let settings = AppSettings.shared
        automaticallyChecksForUpdates = settings.checkForUpdates
        updateCheckInterval = Self.clampedInterval(days: settings.updateIntervalDays)
    }

    /// Days -> seconds, clamped to Sparkle's minimum interval (3600s).
    static func clampedInterval(days: Int) -> TimeInterval {
        max(3600, Double(days) * 86400)
    }

    /// "Check for Updates Now" (Settings), "Check for Updates..." (app menu and Help menu).
    /// SPUStandardUpdaterController presents Sparkle's own UI (checking spinner, "you're up to
    /// date" / update-available sheet, download+install), so no separate alert is needed here.
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
