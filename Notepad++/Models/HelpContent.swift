//
//  HelpContent.swift
//  Notepad++
//
//  Structured content for the in-app Help window and the Help menu.
//  Every statement here is derived from the app's actual code paths, not from the
//  behavior of the original Windows Notepad++. When a control exists in the UI but is
//  not yet wired to an effect, that is stated plainly instead of describing a fiction.
//

import Foundation

// MARK: - Window scene identifiers
// Shared between the Window scenes declared in Notepad__App.swift and the Help menu
// buttons in HelpCommands.swift, so both refer to the same singleton windows.
enum HelpScene {
    static let help = "notepad-help"
    static let debugInfo = "notepad-debug-info"
}

// MARK: - Topic model

enum HelpSection: String, CaseIterable, Identifiable {
    case about = "About"
    case gettingStarted = "Getting Started"
    case interface = "Interface"
    case menus = "Menus"
    case settings = "Settings"
    case reference = "Reference"

    var id: String { rawValue }
}

/// One row of the keyboard-shortcut reference.
struct ShortcutRow: Hashable {
    let action: String
    let keys: String
}

/// A block of rendered help content. The detail view switches on the case.
enum HelpBlock: Hashable {
    case heading(String)
    case paragraph(String)
    case bullets([String])
    case shortcuts([ShortcutRow])

    /// Flattened text used for full-text search over a topic.
    var plainText: String {
        switch self {
        case .heading(let s), .paragraph(let s):
            return s
        case .bullets(let items):
            return items.joined(separator: " ")
        case .shortcuts(let rows):
            return rows.map { "\($0.action) \($0.keys)" }.joined(separator: " ")
        }
    }
}

struct HelpTopic: Identifiable, Hashable {
    let id: String
    let title: String
    let section: HelpSection
    let blocks: [HelpBlock]

    /// Title plus body, used to filter topics from the search field.
    var searchText: String {
        (title + " " + blocks.map(\.plainText).joined(separator: " ")).lowercased()
    }
}

// MARK: - Content

enum HelpContent {

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    static let projectURL = "https://github.com/PedroGruvhagen/Notepadplusplus-MacOS"

    static func topic(id: String?) -> HelpTopic? {
        guard let id else { return nil }
        return topics.first { $0.id == id }
    }

    static func topics(in section: HelpSection, matching query: String) -> [HelpTopic] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return topics.filter { topic in
            topic.section == section && (trimmed.isEmpty || topic.searchText.contains(trimmed))
        }
    }

    static let topics: [HelpTopic] = [

        // MARK: About
        HelpTopic(
            id: "about",
            title: "About Notepad++ for macOS",
            section: .about,
            blocks: [
                .paragraph("Notepad++ for macOS is a native macOS build of the Notepad++ text editor. It is written in Swift and AppKit and reproduces the behavior of the original Windows application on the Mac."),
                .paragraph("Developer: Pedro Gruvhagen."),
                .paragraph("Based on Notepad++ by Don Ho."),
                .paragraph("License: MIT. The project is open source."),
                .paragraph("Source code: \(projectURL)"),
                .paragraph("Version: \(appVersion) (build \(buildNumber))."),
                .paragraph("For a copy-ready summary of the version, system, and install location (useful when reporting a problem), open Help > Debug Info.")
            ]
        ),

        // MARK: Getting Started
        HelpTopic(
            id: "getting-started",
            title: "Getting started",
            section: .gettingStarted,
            blocks: [
                .heading("Windows and tabs"),
                .paragraph("A window holds a row of tabs, one per open document. The active tab's document fills the editor area. Show or hide the tab row with View > Show Tab Bar, and place it at the top or bottom of the window from Preferences > General."),
                .heading("Creating, opening and saving"),
                .bullets([
                    "New (Command-N) creates an empty untitled document named new 1, new 2, and so on. The lowest unused number is reused.",
                    "Open (Command-O) shows a file panel where you can select several files at once. Any file can be opened regardless of its extension.",
                    "Save (Command-S) writes the active document. An untitled document is redirected to Save As so you can choose a name and location.",
                    "Save As (Command-Shift-S) writes the document to a new file and points the tab at that file.",
                    "Save a Copy As (Command-Option-Shift-S) writes a copy to another location and leaves the current tab pointing at the original file.",
                    "Save All (Command-Option-S) saves every modified document."
                ]),
                .heading("The untitled document"),
                .paragraph("The app always keeps at least one document open. When you open a file while a single, clean (unmodified) untitled document is the only tab, that untitled document is replaced by the opened file instead of leaving an empty tab behind. Closing the last document, or closing the window, leaves one fresh untitled document."),
                .paragraph("Closing a modified document, quitting, or closing the window first prompts you to save.")
            ]
        ),

        // MARK: Interface
        HelpTopic(
            id: "toolbar",
            title: "Toolbar",
            section: .interface,
            blocks: [
                .paragraph("The window toolbar is shown when View > Show Toolbar is on. It groups the following controls."),
                .heading("File actions"),
                .bullets([
                    "New: create a new untitled document, the same as File > New.",
                    "Open: choose files to open, the same as File > Open.",
                    "Save: save the active document. Disabled when no document is open."
                ]),
                .heading("Editor toggles"),
                .bullets([
                    "Line numbers: show or hide the line-number margin.",
                    "Word wrap: turn word wrap on or off.",
                    "Syntax highlighting: turn syntax coloring on or off.",
                    "Decrease font size and Increase font size: step the editor font between 8 and 24 points."
                ]),
                .heading("Search field"),
                .paragraph("The toolbar includes a search field. In the current version this field is not connected to any action, so typing in it has no effect. To search inside the current document use Find (Command-F). To search across files on disk use Find in Files (Command-Shift-F).")
            ]
        ),
        HelpTopic(
            id: "status-bar",
            title: "Status bar",
            section: .interface,
            blocks: [
                .paragraph("The status bar appears at the bottom of the editor when View > Show Status Bar is on. From left to right it shows:"),
                .bullets([
                    "The document's name, with a Modified label when there are unsaved changes.",
                    "The caret position, as Line and Column.",
                    "The document's line-ending format (Windows, Unix, or Mac).",
                    "The character encoding. This is a menu: choosing another encoding converts the document, which is useful when a file cannot be saved in its current encoding."
                ])
            ]
        ),

        // MARK: Menus
        HelpTopic(
            id: "menu-app",
            title: "Notepad++ menu",
            section: .menus,
            blocks: [
                .paragraph("The application menu, named Notepad++, holds the macOS-standard items plus:"),
                .bullets([
                    "About Notepad++: the standard About panel, showing the version along with the developer and license credits.",
                    "Preferences (Command-comma): open the Preferences window. Each Preferences category is described in the Settings section of this help."
                ])
            ]
        ),
        HelpTopic(
            id: "menu-file",
            title: "File menu",
            section: .menus,
            blocks: [
                .bullets([
                    "New (Command-N): create a new untitled document.",
                    "Open (Command-O): open one or more files. Any file type is allowed.",
                    "Reload from Disk (Command-Shift-R): reload the active file from disk, keeping the caret and scroll position. If the document has unsaved changes you are asked to confirm.",
                    "Save (Command-S): save the active document.",
                    "Save As (Command-Shift-S): save to a new file and point the tab at it.",
                    "Save a Copy As (Command-Option-Shift-S): save a copy elsewhere without changing the current file.",
                    "Save All (Command-Option-S): save every modified document.",
                    "Rename: move the current file to a new name or location. An untitled document is sent to Save As instead.",
                    "Close (Command-W): close the active tab, prompting to save when needed.",
                    "Close All (Command-Shift-W): close every tab.",
                    "Close Multiple Documents: a submenu with Close All but Active Document, Close All to the Left, Close All to the Right, and Close All Unchanged.",
                    "Move to Recycle Bin (Command-Delete): move the current file to the Trash after confirmation, then close its tab.",
                    "Print (Command-P): print the active document using the standard print panel."
                ])
            ]
        ),
        HelpTopic(
            id: "menu-edit",
            title: "Edit menu",
            section: .menus,
            blocks: [
                .heading("Standard editing"),
                .paragraph("Undo, Redo, Cut, Copy, Paste, and Select All are provided by the standard macOS Edit menu and act on the focused editor. Undo history is kept separately for each document, so undo never reaches into another tab."),
                .heading("Notepad++ additions"),
                .bullets([
                    "Go to Matching Bracket (Command-M): jump to the bracket that matches the one at the caret. Enabled only while the caret is on a matching bracket.",
                    "EOL Conversion: a submenu that converts all line endings in the document to Windows (CRLF), Unix (LF), or Mac (CR).",
                    "Find (Command-F): open the find bar at the top of the editor.",
                    "Find and Replace (Command-Option-F): open the find bar with the replace row shown.",
                    "Find Next (Command-G) and Find Previous (Command-Shift-G): move to the next or previous match of the term in the find bar. Open the find bar first.",
                    "Find in Files (Command-Shift-F): open the Find in Files panel to search files on disk.",
                    "Mark All (Command-Option-M): highlight every occurrence of the selection, or of the word under the caret when there is no selection.",
                    "Clear Marks (Command-Shift-Option-M): remove the highlights added by Mark All.",
                    "Toggle Bookmark (Command-B): add or remove a bookmark on the caret's line.",
                    "Next Bookmark (Command-Shift-B) and Previous Bookmark (Command-Option-B): move between bookmarks, wrapping around at the ends.",
                    "Show Bookmarks (Command-Control-B): open the Bookmarks panel. Double-clicking a row opens the file and jumps to the bookmarked line."
                ])
            ]
        ),
        HelpTopic(
            id: "menu-view",
            title: "View menu",
            section: .menus,
            blocks: [
                .paragraph("The View menu toggles editor and window features. A checkmark shows next to a toggle that is on."),
                .bullets([
                    "Show Toolbar, Show Status Bar, Show Tab Bar: show or hide those parts of the window.",
                    "Word Wrap (Command-Option-W): wrap long lines to the editor width.",
                    "Show Line Numbers: show the line-number margin.",
                    "Syntax Highlighting: color the text according to the document's language.",
                    "Code Folding: allow foldable regions to be collapsed. When on, fold controls appear in the margin.",
                    "Fold All (Command-Option-0) and Unfold All (Command-Option-9): collapse or expand every foldable region. Available only when Code Folding is on.",
                    "Show All Characters: show whitespace marks for spaces and tabs.",
                    "Show Indent Guides: draw a faint vertical guide at each indent level."
                ])
            ]
        ),
        HelpTopic(
            id: "menu-language",
            title: "Language menu",
            section: .menus,
            blocks: [
                .paragraph("The Language menu lists programming and markup languages. Choosing one sets the syntax-highlighting language for the active document only; other tabs are unchanged."),
                .paragraph("The menu currently shows the first twenty languages from the bundled language definitions. To set the language that new documents start with, use Preferences > New Document.")
            ]
        ),
        HelpTopic(
            id: "menu-help",
            title: "Help menu",
            section: .menus,
            blocks: [
                .bullets([
                    "Notepad++ Help (Command-?): open this help window.",
                    "Notepad++ Home: open the Notepad++ website in your browser.",
                    "Notepad++ macOS Project Page: open this port's page on GitHub.",
                    "Online User Manual: open the Notepad++ user manual website.",
                    "Community (Forum): open the Notepad++ community forum.",
                    "Check for Updates: open the project's Releases page on GitHub, where the latest version is listed.",
                    "Debug Info: open a panel with the version, system, and install-path information, with a button to copy it for bug reports."
                ]),
                .paragraph("The About item, which shows the version and credits, is in the Notepad++ application menu, not the Help menu, following the macOS convention.")
            ]
        ),

        // MARK: Settings
        HelpTopic(
            id: "settings-overview",
            title: "Preferences overview",
            section: .settings,
            blocks: [
                .paragraph("Open Preferences from the Notepad++ menu or with Command-comma. The window has a sidebar of categories, each described in its own topic below."),
                .paragraph("Buttons at the top of the window reset the current category to its defaults, and export or import all settings as a JSON file."),
                .paragraph("A few options are shown for completeness but are not yet active. Where that is the case it is noted in the topic, and in the window those controls appear dimmed or carry a Coming Soon or Partial label.")
            ]
        ),
        HelpTopic(
            id: "settings-general",
            title: "General settings",
            section: .settings,
            blocks: [
                .heading("User Interface"),
                .bullets([
                    "Show Toolbar, Show Status Bar, Show Tab Bar: the same toggles as the View menu.",
                    "Tab Bar Position: place the tab row at the Top or Bottom of the window."
                ]),
                .heading("Session"),
                .bullets([
                    "Remember last session: when on, the documents from your previous run are restored at launch. This is on by default. The toggle itself is currently disabled, so this behavior stays on.",
                    "Maximum recent files and Show recent files in submenu: not yet active, shown with a Coming Soon label."
                ]),
                .heading("Updates"),
                .paragraph("Check for updates automatically, the check interval, and Check for Updates Now are not yet active. To get updates, use Help > Check for Updates, which opens the Releases page where the latest version is listed.")
            ]
        ),
        HelpTopic(
            id: "settings-editing",
            title: "Editing settings",
            section: .settings,
            blocks: [
                .heading("Font"),
                .bullets([
                    "Font Family: choose a monospaced font family.",
                    "Font Size: 8 to 24 points, with a live preview."
                ]),
                .heading("Display"),
                .paragraph("These toggles all take effect immediately: Show line numbers, Show bookmarks margin, Show indent guides, Highlight current line, Word wrap, Show whitespace, Show end of line, and Scroll beyond last line."),
                .heading("Caret"),
                .bullets([
                    "Caret Width: 1 to 5 pixels.",
                    "Blink Rate: set to 0 for a caret that does not blink. A non-zero value keeps the caret blinking at the system rate.",
                    "Enable multi-selection: not available on macOS in this version, and shown disabled."
                ])
            ]
        ),
        HelpTopic(
            id: "settings-appearance",
            title: "Appearance settings",
            section: .settings,
            blocks: [
                .heading("Theme"),
                .bullets([
                    "Enable Dark Mode: apply a dark appearance.",
                    "Color Theme: choose a color theme by name. Customize Theme is disabled."
                ]),
                .heading("Syntax Highlighting"),
                .bullets([
                    "Enable syntax highlighting: color the text by language.",
                    "Match braces: highlight the bracket that matches the one at the caret.",
                    "Highlight matching tags: recorded but not yet applied by the editor.",
                    "Current Line Color: the highlight color for the current line, available when Highlight current line is on."
                ]),
                .heading("Smart Highlighting"),
                .bullets([
                    "Enable smart highlighting: automatically highlight every occurrence of the selected word.",
                    "Match case and Match whole word only: refine which occurrences are highlighted."
                ])
            ]
        ),
        HelpTopic(
            id: "settings-tabs",
            title: "Tabs and Indentation settings",
            section: .settings,
            blocks: [
                .heading("Tab Settings"),
                .bullets([
                    "Tab Size: 2, 4, or 8 spaces.",
                    "Replace tabs with spaces: insert spaces instead of a tab character."
                ]),
                .heading("Indentation"),
                .bullets([
                    "Maintain indentation: a new line starts at the same indentation as the previous line.",
                    "Auto indent and Smart indent: adjust indentation as you type. Smart indent depends on Auto indent being on."
                ]),
                .paragraph("Language-specific indentation overrides are not yet available.")
            ]
        ),
        HelpTopic(
            id: "settings-newdoc",
            title: "New Document settings",
            section: .settings,
            blocks: [
                .paragraph("These defaults are applied to every new document."),
                .heading("Default Encoding"),
                .bullets([
                    "Character Encoding: UTF-8, UTF-8 with BOM, UTF-16 BE, UTF-16 LE, ASCII, or a legacy single-byte encoding.",
                    "Open ANSI files as UTF-8: treat non-Unicode files as UTF-8 when opening."
                ]),
                .heading("Line Endings"),
                .paragraph("Default Format sets the line ending for new documents: Windows (CRLF), Unix (LF), or Mac (CR)."),
                .heading("Default Language"),
                .paragraph("Language sets the syntax highlighting a new document starts with, either Plain Text or any bundled language. Manage Language Definitions is disabled.")
            ]
        ),
        HelpTopic(
            id: "settings-backup",
            title: "Backup and Auto-Save settings",
            section: .settings,
            blocks: [
                .heading("Backup"),
                .bullets([
                    "Enable backup on save: keep a backup copy when saving.",
                    "Backup Type: None, Simple (a .bak file beside the original), or Verbose (a timestamped copy in a chosen directory).",
                    "Backup Directory: the folder used for Verbose backups."
                ]),
                .heading("Auto-Save"),
                .bullets([
                    "Enable auto-save: save automatically at a set interval.",
                    "Auto-save interval: minutes between saves (minimum 1). Auto-save applies only to documents that have been saved at least once."
                ]),
                .heading("Session Snapshot and Periodic Backup"),
                .paragraph("Session snapshots are taken periodically so that open work can be recovered after an unexpected quit. The on/off toggle and the interval are shown but are currently fixed. Open Backup Folder reveals the snapshot location in the Finder.")
            ]
        ),
        HelpTopic(
            id: "settings-autocompletion",
            title: "Auto-Completion settings",
            section: .settings,
            blocks: [
                .heading("Auto-Completion"),
                .bullets([
                    "Enable auto-completion: suggest words while typing. Off by default.",
                    "Trigger from character: how many characters to type before suggestions appear (minimum 1).",
                    "Ignore numbers: do not suggest completions for all-digit fragments."
                ]),
                .paragraph("Show function parameters hint is shown but not yet applied by the editor."),
                .heading("Auto-Insert"),
                .paragraph("The options for automatically inserting closing parentheses, brackets, braces, quotes, and HTML or XML tags are recorded but are not yet applied by the editor."),
                .heading("Advanced"),
                .paragraph("The completion selection behavior, case sensitivity, and sorting options are recorded but are not yet applied.")
            ]
        ),
        HelpTopic(
            id: "settings-search",
            title: "Search settings",
            section: .settings,
            blocks: [
                .heading("Default Search Options"),
                .paragraph("Match case, Match whole word only, Wrap around, and Use regular expressions are the options used by the find bar. The find bar's Aa, W, and .* buttons change the same settings. The Search Mode picker is not yet applied."),
                .heading("Smart Highlighting"),
                .paragraph("Enable smart highlighting, Match case, and Match whole word only control the automatic highlighting of the selected word. Use find dialog settings and Highlight on another view are not yet applied."),
                .heading("Search History and Find Dialog"),
                .paragraph("The history-size limits and the find-dialog appearance options (always visible, transparency, two-button mode) are recorded but are not yet applied. Clear Search History clears the stored Find in Files search history. Replace history is not stored in this version, so Clear Replace History has nothing to clear.")
            ]
        ),
        HelpTopic(
            id: "settings-performance",
            title: "Performance settings",
            section: .settings,
            blocks: [
                .paragraph("These options limit heavy features on very large files so the editor stays responsive."),
                .heading("Active"),
                .bullets([
                    "Enable Large File Restriction: when on, syntax highlighting is turned off for files larger than the size below.",
                    "Define Large File Size: the size threshold in megabytes, from 1 to 2046. Opening a file above this size shows a warning, and code folding is turned off for that file automatically."
                ]),
                .heading("Shown but not yet applied"),
                .bullets([
                    "Allow Auto-Completion, Allow Smart Highlighting, Allow Brace Match, Allow URL Clickable Link, and Deactivate Word Wrap globally: recorded but not yet applied by the editor.",
                    "Suppress warning when opening files of 2 GB or more: recorded but not yet applied. There is no separate 2 GB warning; the large-file warning above uses the size threshold you set."
                ])
            ]
        ),

        // MARK: Reference
        HelpTopic(
            id: "shortcuts",
            title: "Keyboard shortcuts",
            section: .reference,
            blocks: [
                .paragraph("The shortcuts defined by the app are listed below. Undo, Redo, and the clipboard commands use the standard macOS keys."),
                .heading("File"),
                .shortcuts([
                    ShortcutRow(action: "New", keys: "\u{2318}N"),
                    ShortcutRow(action: "Open", keys: "\u{2318}O"),
                    ShortcutRow(action: "Reload from Disk", keys: "\u{21E7}\u{2318}R"),
                    ShortcutRow(action: "Save", keys: "\u{2318}S"),
                    ShortcutRow(action: "Save As", keys: "\u{21E7}\u{2318}S"),
                    ShortcutRow(action: "Save a Copy As", keys: "\u{2325}\u{21E7}\u{2318}S"),
                    ShortcutRow(action: "Save All", keys: "\u{2325}\u{2318}S"),
                    ShortcutRow(action: "Close", keys: "\u{2318}W"),
                    ShortcutRow(action: "Close All", keys: "\u{21E7}\u{2318}W"),
                    ShortcutRow(action: "Move to Recycle Bin", keys: "\u{2318}\u{232B}"),
                    ShortcutRow(action: "Print", keys: "\u{2318}P")
                ]),
                .heading("Edit and search"),
                .shortcuts([
                    ShortcutRow(action: "Go to Matching Bracket", keys: "\u{2318}M"),
                    ShortcutRow(action: "Find", keys: "\u{2318}F"),
                    ShortcutRow(action: "Find and Replace", keys: "\u{2325}\u{2318}F"),
                    ShortcutRow(action: "Find Next", keys: "\u{2318}G"),
                    ShortcutRow(action: "Find Previous", keys: "\u{21E7}\u{2318}G"),
                    ShortcutRow(action: "Find in Files", keys: "\u{21E7}\u{2318}F"),
                    ShortcutRow(action: "Mark All", keys: "\u{2325}\u{2318}M"),
                    ShortcutRow(action: "Clear Marks", keys: "\u{2325}\u{21E7}\u{2318}M")
                ]),
                .heading("Bookmarks"),
                .shortcuts([
                    ShortcutRow(action: "Toggle Bookmark", keys: "\u{2318}B"),
                    ShortcutRow(action: "Next Bookmark", keys: "\u{21E7}\u{2318}B"),
                    ShortcutRow(action: "Previous Bookmark", keys: "\u{2325}\u{2318}B"),
                    ShortcutRow(action: "Show Bookmarks", keys: "\u{2303}\u{2318}B")
                ]),
                .heading("View"),
                .shortcuts([
                    ShortcutRow(action: "Word Wrap", keys: "\u{2325}\u{2318}W"),
                    ShortcutRow(action: "Fold All", keys: "\u{2325}\u{2318}0"),
                    ShortcutRow(action: "Unfold All", keys: "\u{2325}\u{2318}9")
                ]),
                .heading("Application"),
                .shortcuts([
                    ShortcutRow(action: "Preferences", keys: "\u{2318},"),
                    ShortcutRow(action: "Notepad++ Help", keys: "\u{2318}?")
                ]),
                .heading("Standard editing (provided by macOS)"),
                .shortcuts([
                    ShortcutRow(action: "Undo", keys: "\u{2318}Z"),
                    ShortcutRow(action: "Redo", keys: "\u{21E7}\u{2318}Z"),
                    ShortcutRow(action: "Cut", keys: "\u{2318}X"),
                    ShortcutRow(action: "Copy", keys: "\u{2318}C"),
                    ShortcutRow(action: "Paste", keys: "\u{2318}V"),
                    ShortcutRow(action: "Select All", keys: "\u{2318}A")
                ])
            ]
        )
    ]
}
