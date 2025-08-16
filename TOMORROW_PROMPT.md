# Prompt for Tomorrow's Audit Session

## Context Setting

I'm working on a LITERAL TRANSLATION/PORT of Notepad++ Windows ARM version to macOS. This is NOT a reimplementation or "inspired by" project - it's a direct, line-by-line translation of the C++ source code to Swift.

We now have TWO reference sources:
1. **Notepad++ source**: `../notepad-plus-plus-reference/` 
2. **Scintilla source**: `../scintilla-reference/` (the text editor component Notepad++ uses)

## CRITICAL UNDERSTANDING

This project requires translating BOTH:
- The Scintilla text editing engine (from C++ to NSTextView equivalents)
- The Notepad++ application layer (UI, settings, file management)

Every feature must be traced back to the original C++ source. NO custom implementations allowed.

## Today's Audit Task

Please perform a comprehensive audit of everything implemented so far:

### 1. Check Core Components Against Source

For each major component we've created, verify it matches the original:

- **BracketMatcher**: Should be a direct translation of:
  - `scintilla-reference/src/Document.cxx` line 3010 (BraceMatch function)
  - `notepad-plus-plus-reference/PowerEditor/src/Notepad_plus.cpp` line 2993 (braceMatch)
  
- **Settings/Parameters**: Should match:
  - `notepad-plus-plus-reference/PowerEditor/src/Parameters.h` (NppGUI structure)
  - All preference dialogs from `.rc` files

- **Syntax Highlighting**: Should translate:
  - Scintilla lexers from `scintilla-reference/lexers/`
  - Language definitions from `notepad-plus-plus-reference/PowerEditor/src/langs.model.xml`

### 2. Identify Deviations

List every place where we:
- Created custom logic instead of translating
- Used macOS APIs without translating the original algorithm first
- Added features that don't exist in original
- Skipped features that exist in original

### 3. Create Fix List

For each deviation found:
1. Note the file and function
2. Find the corresponding C++ source (both Scintilla and Notepad++)
3. Document what needs to be changed to match original
4. Priority: Critical (breaks functionality) vs Minor (cosmetic)

### 4. Scintilla API Coverage

Check which Scintilla APIs we're using vs which we've actually implemented:
- Look for all `SCI_` constants in Notepad++ source
- Verify we have Swift equivalents for each
- Note which are missing

## Important Notes

- I'm doing this project solo as a hobby - I'm not a professional programmer
- I'm "vibe coding" and learning as I go
- The goal is to have Notepad++ on my Mac for personal use
- Making it public in case it helps others too
- We have UNLIMITED time and tokens - accuracy matters more than speed
- Always check the source code before implementing anything

## Specific Questions to Answer

1. Are we actually translating the Scintilla `Document::BraceMatch()` algorithm or did we create our own?
2. Do our Settings match the exact structure of Parameters.h?
3. Are we using the actual Scintilla lexer logic or custom syntax highlighting?
4. What percentage of our code is direct translation vs custom implementation?
5. Which critical Notepad++ features are completely missing?

## Expected Output

Please provide:
1. A detailed audit report of current implementation accuracy
2. A prioritized list of what needs to be fixed to be a true port
3. Specific C++ source locations for each fix needed
4. An estimate of how much work remains for a faithful port

Remember: This is a TRANSLATION project. Every line of Swift should correspond to a line of C++ in either Notepad++ or Scintilla source.