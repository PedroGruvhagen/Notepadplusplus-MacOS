# Notepad++ for macOS (Unofficial PORT)

A DIRECT PORT of Notepad++ ARM version to macOS, built with Swift and SwiftUI, optimized exclusively for Apple Silicon.

## 🎯 Project Goal

PORT the exact functionality of Notepad++ Windows ARM version to macOS with a fully native experience that runs seamlessly on Apple Silicon (M1/M2/M3/M4) Macs.

**THIS IS A PORT**: We are directly porting features, settings, and behaviors from the original Notepad++ source code, not creating a "similar" or "inspired by" application.

## 🙏 Attribution

This project is a **DIRECT PORT of [Notepad++](https://notepad-plus-plus.org/)** to macOS, the fantastic open-source text editor created by Don Ho. We have tremendous respect for the original project and its community.

- **Original Notepad++**: [GitHub](https://github.com/notepad-plus-plus/notepad-plus-plus) | [Website](https://notepad-plus-plus.org/)
- **Original License**: GPL v3
- **Original Author**: Don Ho and contributors

**Important**: This is an independent PORT of Notepad++ to macOS and is NOT officially affiliated with or endorsed by Notepad++ unless explicitly stated. We are porting the exact features and functionality from the original source code.

## 📝 Letter to Notepad++ Team

Dear Don Ho and Notepad++ Team,

We've created this macOS port out of love for Notepad++ and a desire to bring its functionality to Mac users. We would be honored if you would consider:

1. Reviewing this implementation
2. Potentially adopting it as an official macOS version
3. Providing guidance on feature parity with the Windows ARM version
4. Advising on trademark usage and naming

We're committed to respecting your project and will make any changes you request.

## 🚀 Features

### Core Editing ✅
- ✅ Multi-tab interface with tab management
- ✅ File operations (New, Open, Save, Save As, Save All)
- ✅ Close Tab, Close All Tabs, Close Other Tabs
- ✅ Recent files menu
- ✅ Line numbers display
- ✅ Status bar with cursor position
- ✅ Modified indicator with asterisk
- ✅ Undo/Redo functionality
- ✅ Cut/Copy/Paste/Select All
- ✅ Word wrap toggle
- ✅ Bracket matching (jump to matching bracket)

### Search & Replace ✅
- ✅ Find functionality with live search
- ✅ Find & Replace with Replace All
- ✅ Case sensitive search
- ✅ Whole word search
- ✅ Regular expression search
- ✅ Search highlighting with lifecycle management
- ✅ Current match highlighting
- ✅ Match counter
- ✅ Find Next/Previous navigation
- ✅ Mark All occurrences
- ✅ Bookmarks with navigation

### Syntax & Languages ✅
- ✅ Syntax highlighting for 94 languages (full Notepad++ parity)
- ✅ Language auto-detection by file extension
- ✅ Manual language selection via menu
- ✅ All Notepad++ language definitions ported
- ✅ Keyword highlighting
- ✅ Comment highlighting
- ✅ String literal highlighting
- ✅ Number highlighting
- ✅ Operator highlighting

### Advanced Features ✅
- ✅ Code folding support
- ✅ Find in Files functionality
- ✅ Advanced search options
- ✅ Preferences/Settings window
- ✅ Font customization
- ✅ Tab size configuration
- ✅ Auto-indentation settings

### Platform Integration ✅
- ✅ Native Apple Silicon support (ARM64 only)
- ✅ macOS native menus and keyboard shortcuts
- ✅ Native file dialogs
- ✅ Drag and drop file support
- ✅ macOS appearance (light/dark mode)

### In Progress 🚧
- 🚧 EOL type detection and conversion
- 🚧 File encoding detection (UTF-8, UTF-16, etc.)
- 🚧 External file change detection
- 🚧 Session management (persist/restore open files)
- 🚧 Theme import from Notepad++
- 🚧 Auto-indentation per language
- 🚧 Settings persistence

### Planned 📋
- 📋 Split view (horizontal/vertical)
- 📋 Multi-cursor editing
- 📋 Column mode editing
- 📋 Macro recording and playback
- 📋 Plugin system architecture
- 📋 Auto-completion
- 📋 Function list panel
- 📋 Document map
- 📋 Print functionality
- 📋 Export as HTML/RTF

## 💻 System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1/M2/M3/M4) - **Apple Silicon ONLY**
- Xcode 16.0+ (for building from source)

## 🔨 Building from Source

```bash
# Clone the repository
git clone https://github.com/[yourusername]/notepadplusplus-mac.git
cd notepadplusplus-mac

# Open in Xcode
open Notepad++.xcodeproj

# Build and run (⌘R)
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### How You Can Help
- Implement missing Notepad++ features
- Test on different macOS versions
- Report bugs and issues
- Improve performance
- Add language definitions
- Create themes

## 📄 License

This macOS implementation is licensed under the **MIT License** - see [LICENSE](LICENSE) file.

The original Notepad++ is licensed under GPL v3.

## 🌟 Why This Project?

- **Direct Port**: Exact feature-for-feature port of Notepad++ Windows ARM version
- **Native Performance**: Built specifically for macOS and Apple Silicon
- **macOS Integration**: Uses native macOS APIs while maintaining Notepad++ functionality
- **Feature Parity**: Direct port of all Notepad++ Windows ARM version features
- **Open Source**: Free and open for the community

## 📊 Comparison with Original

| Feature | Notepad++ Windows | This macOS Version |
|---------|-------------------|-------------------|
| Multi-tab | ✅ | ✅ |
| Syntax Highlighting (94 languages) | ✅ | ✅ |
| Find/Replace | ✅ | ✅ |
| Regular Expression Search | ✅ | ✅ |
| Code Folding | ✅ | ✅ |
| Bookmarks | ✅ | ✅ |
| Save All/Close All | ✅ | ✅ |
| Settings/Preferences | ✅ | ✅ |
| EOL Detection | ✅ | 🚧 In Progress |
| Encoding Detection | ✅ | 🚧 In Progress |
| Session Management | ✅ | 🚧 In Progress |
| Plugins | ✅ | 📋 Planned |
| Themes | ✅ | 📋 Planned |
| Macros | ✅ | 📋 Planned |
| Apple Silicon Native | N/A | ✅ |
| macOS Integration | N/A | ✅ |

## 🔗 Links

- [Original Notepad++ Website](https://notepad-plus-plus.org/)
- [Original Notepad++ GitHub](https://github.com/notepad-plus-plus/notepad-plus-plus)
- [Report Issues](https://github.com/[yourusername]/notepadplusplus-mac/issues)
- [Discussions](https://github.com/[yourusername]/notepadplusplus-mac/discussions)

## 🙌 Acknowledgments

- Don Ho for creating Notepad++
- The entire Notepad++ community
- Contributors to this macOS port

## 📧 Contact

If you're from the Notepad++ team and have questions or requests about this project, please open an issue or contact us directly.

---

**Note to Users**: If you love Notepad++ on Windows, please consider [donating to the original project](https://notepad-plus-plus.org/donate/).

**Note to Notepad++ Team**: We're ready to transfer this repository to your organization or make any changes you request. This project exists to serve the Notepad++ community.