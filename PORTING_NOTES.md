# NOTEPAD++ LITERAL TRANSLATION NOTES

## CRITICAL: THIS IS A LITERAL TRANSLATION PROJECT

**⚠️ FUNDAMENTAL RULE: TRANSLATE THE C++ CODE, DO NOT REIMAGINE IT**

This project is a LITERAL, LINE-BY-LINE TRANSLATION of Notepad++ Windows ARM source code from C++ to Swift.
Every function, every algorithm, every setting must be a direct translation from the original source.

## Reference Source Code Locations:

1. **Notepad++ Source**: `../notepad-plus-plus-reference/`
2. **Scintilla Source**: `../scintilla-reference/`

Both sources are essential because:
- Notepad++ uses Scintilla for all text editing operations
- We must translate BOTH Notepad++ UI code AND Scintilla editor code

## Translation Methodology (MANDATORY PROCESS)

### For EVERY Feature Implementation:

1. **FIND THE SOURCE**: Locate the exact C++ file in `../notepad-plus-plus-reference/`
2. **READ ENTIRELY**: Read the complete implementation including all called functions
3. **TRANSLATE LITERALLY**: Convert C++ to Swift preserving:
   - Exact logic and control flow
   - Same algorithm and data structures
   - Identical variable/function names (adapted to Swift style)
   - All comments and documentation
   - Same error handling patterns
4. **VERIFY EQUIVALENCE**: The Swift code must do EXACTLY what the C++ code does
5. **DOCUMENT APIS**: Note all Win32/Scintilla APIs that need macOS equivalents

## Scintilla API Translation Requirements

Notepad++ is built on top of Scintilla editor component. We MUST create exact equivalents:

### Critical Scintilla APIs to Implement:

| Scintilla API | Scintilla Source | Notepad++ Usage | Swift Translation | Status |
|--------------|------------------|-----------------|-------------------|--------|
| SCI_BRACEMATCH | Document.cxx:3010 | Notepad_plus.cpp:2989 | NSTextView.braceMatch() | ✅ IMPLEMENTED |
| SCI_BRACEHIGHLIGHT | Editor.cxx | Notepad_plus.cpp:3010 | NSTextView.braceHighlight() | ✅ IMPLEMENTED |
| SCI_BRACEBADLIGHT | Editor.cxx | Notepad_plus.cpp:3005 | NSTextView.braceBadLight() | ✅ IMPLEMENTED |
| SCI_SETHIGHLIGHTGUIDE | Editor.cxx | Notepad_plus.cpp:3006,3016 | NSTextView.setHighlightGuide() | ✅ IMPLEMENTED |
| SCI_GETCOLUMN | Editor.cxx | Notepad_plus.cpp:3014-3015 | NSTextView.getColumn() | ✅ IMPLEMENTED |
| SCI_LINEFROMPOSITION | Editor.cxx | Multiple locations | NSTextView.lineFromPosition() | ✅ IMPLEMENTED |
| SCI_GETLINEINDENT | Editor.cxx | Notepad_plus.cpp:3756 | NSTextView.getLineIndent() | ✅ IMPLEMENTED |

## Source File Translation Status

### Core Files That MUST Be Translated:

| Original C++ File | Purpose | Swift File | Translation Status |
|------------------|---------|------------|-------------------|
| PowerEditor/src/Notepad_plus.cpp | Main application logic | Multiple files | ❌ NOT TRANSLATED - Custom implementation |
| PowerEditor/src/Parameters.cpp | Settings/preferences | AppSettings.swift | ❌ NOT TRANSLATED - Custom implementation |
| PowerEditor/src/NppCommands.cpp | Command handlers | Not created | ❌ NOT TRANSLATED |
| PowerEditor/src/NppNotification.cpp | Event handlers | Not created | ❌ NOT TRANSLATED |
| PowerEditor/src/WinControls/Preference/*.cpp | Preferences UI | SettingsView.swift | ❌ NOT TRANSLATED - Custom UI |
| PowerEditor/src/ScintillaComponent/*.cpp | Editor functionality | Various | ❌ NOT TRANSLATED |

## CRITICAL IMPLEMENTATION ERRORS FOUND

### 1. BracketMatcher.swift - COMPLETELY WRONG
**CURRENT**: Custom bracket matching logic
**REQUIRED**: Direct translation of `Notepad_plus::braceMatch()` (line 2993)
```cpp
// ORIGINAL C++ (Notepad_plus.cpp:2993-3024)
bool Notepad_plus::braceMatch() {
    Buffer* currentBuf = _pEditView->getCurrentBuffer();
    if (!currentBuf->allowBraceMach())
        return false;
    // ... exact logic must be translated
}
```

### 2. Settings/Preferences - COMPLETELY WRONG
**CURRENT**: Custom SwiftUI settings panels
**REQUIRED**: Exact translation of preference dialogs from:
- `PowerEditor/src/WinControls/Preference/preference.rc` (dialog layouts)
- `PowerEditor/src/WinControls/Preference/preferenceDlg.cpp` (logic)
- Must have EXACT same tabs, options, and layout

### 3. Parameters/Settings Storage - WRONG STRUCTURE
**CURRENT**: Custom AppSettings structure
**REQUIRED**: Direct translation of:
- `PowerEditor/src/Parameters.h` (NppGUI structure)
- `PowerEditor/src/Parameters.cpp` (loading/saving logic)

## Correct Translation Example

### ❌ WRONG (Current Approach):
```swift
// Creating our own implementation
class BracketMatcher {
    func findMatchingBracket(text: String, position: Int) -> Int? {
        // Custom logic we invented
    }
}
```

### ✅ CORRECT (Required Approach):
```swift
// Direct translation from:
// 1. Notepad_plus.cpp line 2993-3024 (UI layer)
// 2. Document.cxx line 3010-3041 (Scintilla BraceMatch)
extension NSTextView {
    // Translation of: bool Notepad_plus::braceMatch()
    func performBraceMatch() -> Bool {
        // Line 2995-2996: Check if brace matching is allowed
        guard let currentBuffer = self.currentBuffer,
              currentBuffer.allowBraceMatch() else {
            return false
        }
        
        // Line 2999-3000: Initialize brace positions
        var braceAtCaret: Int = -1
        var braceOpposite: Int = -1
        
        // Line 3001: Find matching brace positions
        findMatchingBracePos(&braceAtCaret, &braceOpposite)
        
        // Line 3003-3007: Handle bad brace
        if braceAtCaret != -1 && braceOpposite == -1 {
            self.braceBadLight(braceAtCaret) // SCI_BRACEBADLIGHT
            self.setHighlightGuide(0) // SCI_SETHIGHLIGHTGUIDE
        }
        // Line 3008-3018: Handle matched braces
        else {
            self.braceHighlight(braceAtCaret, braceOpposite) // SCI_BRACEHIGHLIGHT
            
            if self.isShownIndentGuide() {
                let columnAtCaret = self.getColumn(braceAtCaret) // SCI_GETCOLUMN
                let columnOpposite = self.getColumn(braceOpposite) // SCI_GETCOLUMN
                self.setHighlightGuide(min(columnAtCaret, columnOpposite)) // SCI_SETHIGHLIGHTGUIDE
            }
        }
        
        // Line 3020-3023: Enable/disable menu commands
        let enable = (braceAtCaret != -1) && (braceOpposite != -1)
        self.enableCommand(.searchGotoMatchingBrace, enable)
        self.enableCommand(.searchSelectMatchingBraces, enable)
        
        return braceAtCaret != -1
    }
}
```

## Required Translation Process

1. **CHECK SCINTILLA FIRST**: For any text editing feature, look in `scintilla-reference/src/`
2. **THEN CHECK NOTEPAD++**: See how Notepad++ calls the Scintilla API
3. **TRANSLATE BOTH**: Create Swift equivalents for both layers
4. **PRESERVE LOGIC**: Keep exact algorithms from both sources
5. **NO SHORTCUTS**: Even if macOS has a similar API, translate the original logic

## Translation Checklist for Each File

- [ ] Located corresponding C++ source file
- [ ] Read entire C++ implementation
- [ ] Created Swift file with same structure
- [ ] Translated each function preserving logic
- [ ] Matched all variable/function names
- [ ] Implemented all required Scintilla APIs
- [ ] Verified behavior matches original
- [ ] Documented any platform-specific adaptations

## Platform Adaptation Rules

When platform differences require adaptation:
1. **PRESERVE** the original logic and behavior
2. **DOCUMENT** the Win32/Scintilla API being replaced
3. **CREATE** exact functional equivalent for macOS
4. **NEVER** add features or change behavior

## NO CREATIVITY ALLOWED

- DO NOT optimize algorithms
- DO NOT modernize code patterns  
- DO NOT add features
- DO NOT skip features
- DO NOT change UI layouts
- DO NOT rename settings
- DO NOT restructure code

**ONLY TRANSLATE WHAT EXISTS IN THE ORIGINAL SOURCE**