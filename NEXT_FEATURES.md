# Next Features Priority List

## 🎯 Current Task: Ready for Next Feature
Advanced Search features completed successfully!

## Priority Order (User Approved 2025-08-15)

### 1. Find & Replace ✅ COMPLETED (2025-08-15)
- [x] Find bar (⌘F)
- [x] Search highlighting
- [x] Next/Previous buttons
- [x] Case sensitive option
- [x] Whole word option
- [x] Replace functionality (⌘⌥F)
- [x] Replace All button
- [x] Match counter
- [x] Regex support

### 2. Settings/Preferences Window ✅ COMPLETED
- [x] Font selection
- [x] Theme selection
- [x] Tab size configuration
- [x] Auto-save settings
- [x] Syntax highlighting options
- [x] Editor preferences
- [x] Performance settings (direct port from Notepad++)
- [x] All preference dialogs matching original
- [x] UserDefaults persistence
- [x] Integration with editor

### 3. Port All Languages ✅ COMPLETED (2025-08-15)
- [x] Parse langs.model.xml
- [x] Convert to Swift models
- [x] Add all 94 languages (more than expected!)
- [x] Language menu in UI
- [x] Auto-detection by file extension
- [x] Complete keyword sets for each language

### 4. Fix Core Editing ✅ COMPLETED (2025-08-15)
- [x] Word wrap (fixed - connected to AppSettings)
- [x] Undo/Redo system (Edit menu with keyboard shortcuts)
- [x] Cut/Copy/Paste improvements (Edit menu with proper handlers)
- [x] Drag and drop text (enabled in text editor)
- [x] View menu with toggles for Word Wrap, Line Numbers, Syntax Highlighting
- [x] Edit menu with Undo, Redo, Cut, Copy, Paste, Select All

### 5. Code Folding ✅ COMPLETED (2025-08-15)
- [x] Detect foldable regions (language-specific)
- [x] Fold/unfold buttons in line number view
- [x] Fold all/unfold all commands (View menu)
- [x] Remember fold state during editing
- [x] Support for multiple languages (C-style, Python, XML, Ruby, YAML)
- [x] Toggle via View menu with keyboard shortcuts

### 6. Advanced Search ✅ COMPLETED (2025-08-15)
- [x] Find in Files with directory traversal and filters
- [x] Search history with persistent storage
- [x] Bookmarks system with line-level markers
- [x] Mark all occurrences highlighting
- [x] Keyboard shortcuts for all features
- [x] Context-aware search results display

### 7. File Encoding Detection ✅ COMPLETED (2025-08-16)
- [x] Detect file encoding (UTF-8, UTF-16, ANSI, ASCII)
- [x] BOM detection and handling
- [x] Display encoding in status bar
- [x] Preserve encoding on save
- [x] "Open ANSI as UTF-8" setting support

### 8. Session Management
- [ ] Save open tabs
- [ ] Restore on launch
- [ ] Multiple sessions
- [ ] Workspace concept

### 9. Theme System
- [ ] Port 20+ Notepad++ themes
- [ ] Theme switcher
- [ ] Custom theme editor
- [ ] Dark/Light mode support

## Notes
- User wants action, not discussion
- Build features completely before moving on
- Test each feature thoroughly
- Commit frequently