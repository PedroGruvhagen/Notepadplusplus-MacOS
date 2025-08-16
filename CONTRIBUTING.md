# Contributing to Notepad++ for macOS

Hey there! 👋 Thanks for considering contributing to this project! I really appreciate any help I can get, this is a big undertaking and I'm learning as I go.

## 🎯 What This Project Is About

I'm trying to port Notepad++ from Windows to macOS because I miss it so much after switching to Mac. This is a **literal translation** project - I'm not trying to reimagine Notepad++ or make it "better", I just want the exact same experience on macOS.

## 🤝 How You Can Help

### I Really Need Help With:

1. **Translation Work** - Converting C++ code from Notepad++ to Swift
2. **Testing** - Finding bugs and missing features
3. **macOS Expertise** - Making it feel native on Mac
4. **Performance** - Optimizing for large files
5. **Missing Features** - There are SO many features still to port!

### Types of Contributions Welcome:

- 🐛 **Bug reports** - Tell me what's broken
- 🔧 **Bug fixes** - Even better, fix what's broken!
- ✨ **Feature ports** - Help translate features from the original
- 📝 **Documentation** - Help others understand the code
- 🎨 **UI/UX improvements** - Make it look and feel right on macOS
- 🧪 **Testing** - Try edge cases and report issues
- 💡 **Code reviews** - Tell me what I'm doing wrong (seriously!)

## 🚀 Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 16.0+
- An Apple Silicon Mac (M1/M2/M3/M4)
- Some patience 😅

### Setting Up

```bash
# Clone the repo
git clone https://github.com/PedroGruvhagen/Notepad--.git
cd Notepad++

# Open in Xcode
open Notepad++.xcodeproj

# Build and run (⌘R)
```

### Important Reference Materials

We have the complete Notepad++ source code for reference:
- **Notepad++ source**: `../notepad-plus-plus-reference/`
- **Scintilla source**: `../scintilla-reference/`

**PLEASE** check these sources before implementing anything! We're doing a literal port, not a reimplementation.

## 📋 Development Guidelines

### The Golden Rule: It's a PORT, Not a Rewrite!

This is super important - we're **translating** Notepad++ from C++ to Swift, not creating something new. That means:

1. **Check the original source first** - Always look at how Notepad++ does it
2. **Preserve the logic** - Keep the same algorithms and approaches
3. **Match the behavior** - It should work exactly like the Windows version
4. **Don't optimize prematurely** - First make it work, then make it fast

### Where to Find Things

#### Notepad++ Source Structure:
```
notepad-plus-plus-reference/
├── PowerEditor/src/
│   ├── Notepad_plus.cpp         # Main application logic
│   ├── Parameters.cpp           # Settings and configuration
│   ├── ScintillaComponent/      # Editor integration
│   └── WinControls/             # UI components
├── PowerEditor/installer/
│   ├── themes/                  # Color themes
│   ├── APIs/                    # Auto-completion data
│   └── functionList/            # Language parsing rules
└── PowerEditor/src/
    ├── langs.model.xml          # Language definitions
    └── stylers.model.xml        # Syntax styling rules
```

#### Our macOS Project Structure:
```
Notepad++/
├── Notepad++/
│   ├── Models/                  # Data models (Document, Tab, etc.)
│   ├── Views/                   # SwiftUI views
│   ├── ViewModels/              # Business logic
│   ├── Services/                # Core services (highlighting, etc.)
│   ├── Extensions/              # NSTextView extensions
│   └── ScintillaPort/           # Direct Scintilla translations
```

### How to Port a Feature

1. **Find it in the original** - Locate the feature in the C++ code
2. **Read the entire implementation** - Understand all the logic
3. **Check Scintilla if needed** - Many features use Scintilla APIs
4. **Translate to Swift** - Convert line by line, preserving logic
5. **Test thoroughly** - Make sure it works exactly the same
6. **Document what you did** - Help others understand the port

### Example: Porting Bracket Matching

```cpp
// Original from Notepad_plus.cpp
bool Notepad_plus::braceMatch()
{
    int braceAtCaret = -1;
    int braceOpposite = -1;
    findMatchingBracePos(braceAtCaret, braceOpposite);
    
    if (braceOpposite != -1)
    {
        _pEditView->execute(SCI_BRACEHIGHLIGHT, braceAtCaret, braceOpposite);
    }
}
```

```swift
// Our Swift translation
extension NSTextView {
    func braceMatch() -> Bool {
        var braceAtCaret = -1
        var braceOpposite = -1
        findMatchingBracePos(&braceAtCaret, &braceOpposite)
        
        if braceOpposite != -1 {
            execute(SCI_BRACEHIGHLIGHT, braceAtCaret, braceOpposite)
            return true
        }
        return false
    }
}
```

## 🐛 Reporting Issues

Found a bug? Please let me know! When reporting issues:

1. **Check if it's already reported** - Look through existing issues
2. **Provide details**:
   - What were you doing?
   - What did you expect to happen?
   - What actually happened?
   - Can you reproduce it?
3. **Include system info**:
   - macOS version
   - Mac model (M1, M2, etc.)
   - File type you were editing

## 💻 Making a Pull Request

1. **Fork the repo** and create your branch from `main`
2. **Name your branch** something descriptive like `fix-bracket-matching` or `port-macro-recording`
3. **Follow the porting guidelines** - Check the original source!
4. **Test your changes** - Make sure nothing breaks
5. **Update IMPLEMENTATION_STATUS.md** - Mark what you've implemented
6. **Create the PR** with a clear description

### PR Description Template

```markdown
## What This Does
[Brief description of the feature/fix]

## Original Notepad++ Reference
- Source file: [e.g., Notepad_plus.cpp line 2993]
- Related Scintilla APIs: [if any]

## How I Ported It
[Explain your translation approach]

## Testing Done
- [ ] Tested with small files
- [ ] Tested with large files
- [ ] Tested edge cases
- [ ] Compared behavior with Windows version

## Screenshots (if UI changes)
[Add screenshots here]
```

## 🎯 Current Priorities

Check `IMPLEMENTATION_STATUS.md` for what needs work, but here are the big ones:

1. **Session Management** - Save/restore open tabs ✅ DONE!
2. **Theme System** - Port the 20+ Notepad++ themes
3. **More Languages** - We have 94 to port from the XML! ✅ DONE!
4. **Plugin Architecture** - This is a big one
5. **Performance** - Large file handling needs work

## 🚦 Code Style

- Use Swift conventions (camelCase, etc.)
- Match the existing code style in the project
- Keep it simple and readable - remember, I'm learning too!
- Comment tricky parts, especially when translating complex C++ logic
- No unnecessary dependencies - we're keeping it lean

## 🤔 Not Sure About Something?

That's totally fine! You can:

1. **Open an issue** to discuss your idea
2. **Start a discussion** in the Discussions tab
3. **Make a draft PR** and ask for feedback
4. **Ask questions** - I don't bite, and I probably don't know either 😄

## 📜 Legal Stuff

- This project is MIT licensed
- The original Notepad++ is GPL v3
- By contributing, you agree your code will be MIT licensed
- We respect the original Notepad++ project and will comply with any requests they make

## 🙏 Thank You!

Seriously, thank you for even reading this! Whether you contribute code, report bugs, or just give the project a star, I really appreciate it. I'm just one person trying to bring their favorite editor to Mac, and any help makes a huge difference.

Remember: **We're not trying to reinvent the wheel, we're just trying to make the wheel roll on macOS!**

Happy coding! 🚀

---

*P.S. - If you're from the Notepad++ team and have any concerns about this project, please reach out! I'll do whatever you need.*
