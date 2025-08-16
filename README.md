# Notepad++ for macOS (Personal Project)

Hey! I'm trying to port Notepad++ to macOS because I really miss having it on my Mac. This is a personal project I'm working on in my free time.

## 🤷‍♂️ What This Is

I'm attempting to translate Notepad++ from Windows (C++) to macOS (Swift). I'm not a professional programmer - I'm just someone who loves Notepad++ and wants it on Mac. I'm basically "vibe coding" this whole thing, learning as I go.

**Why am I doing this?**
- I switched to Mac but really miss Notepad++
- Couldn't find a good Mac equivalent that feels the same
- Thought it would be a fun challenge to learn Swift
- Figured if I'm building it anyway, might as well share it in case it helps someone else

## 🎯 My Approach

I'm trying to do a literal translation of the original source code rather than reimagining it. I downloaded both the Notepad++ source and the Scintilla editor source, and I'm slowly translating functions from C++ to Swift. It's probably not the most efficient way, but it helps me understand how everything works.

**Fair warning**: This is very much a work in progress and I'm learning as I go. There will be bugs, missing features, and probably some questionable code. I'm doing my best though!

## 🙏 Credit Where Credit's Due

**HUGE thanks to Don Ho and the Notepad++ team** for creating such an amazing editor. This project is my attempt to port [Notepad++](https://notepad-plus-plus.org/) to macOS because I love it so much.

- **Original Notepad++**: [GitHub](https://github.com/notepad-plus-plus/notepad-plus-plus) | [Website](https://notepad-plus-plus.org/)
- **Original License**: GPL v3
- **Original Author**: Don Ho and contributors

**Disclaimer**: This is just my personal project and is NOT affiliated with or endorsed by the official Notepad++ team. I'm literally just a fan trying to get my favorite editor working on Mac. If the Notepad++ team has any concerns about this project, I'll happily make any changes they request or take it down.

## 📝 Note to the Notepad++ Team

Dear Don Ho and Notepad++ Team,

I'm just a fan who loves Notepad++ and missed it terribly after switching to Mac. This is my amateur attempt at porting it over. If you ever see this:

1. Thank you for making such an incredible editor
2. I hope you don't mind me trying to port it
3. If you have any concerns or requests, please let me know
4. If you ever want to make an official Mac version, I'd be happy to help or get out of the way - whatever you prefer!

This is really just a love letter to your amazing work.

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
- Apple Silicon Mac (M1/M2/M3/M4) - I only have an M1 Mac to test on
- Xcode 16.0+ (if you want to build from source)

## 🔨 Building from Source

```bash
# Clone the repository
git clone https://github.com/[yourusername]/notepadplusplus-mac.git
cd notepadplusplus-mac

# Open in Xcode
open Notepad++.xcodeproj

# Build and run (⌘R)
```

## 🤝 Want to Help?

I'd love some help! I'm learning as I go, so if you know Swift or just love Notepad++ and want to contribute, please feel free to jump in. Even just testing and reporting bugs would be super helpful.

### How You Can Help
- Tell me what I'm doing wrong (seriously, I need the feedback)
- Help implement features I haven't figured out yet
- Test it and let me know what breaks
- Teach me better Swift practices
- Or just give moral support 😅

## 📄 License

This macOS implementation is licensed under the **MIT License** - see [LICENSE](LICENSE) file.

The original Notepad++ is licensed under GPL v3.

## 🌟 Why Am I Doing This?

- **I miss Notepad++**: Seriously, I've tried so many Mac editors and none feel quite right
- **Learning experience**: What better way to learn Swift than porting your favorite app?
- **Sharing is caring**: If I'm building it anyway, why not share it?
- **It's fun**: In a masochistic, "why did I start this" kind of way

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

## 🙌 Thanks To

- Don Ho for creating the best text editor ever
- The Notepad++ community for keeping it awesome
- Stack Overflow for teaching me Swift (one error at a time)
- Coffee for making this possible
- Anyone who tries this out and doesn't immediately uninstall it

## 📧 Get in Touch

If you're from the Notepad++ team and have concerns about this project, please reach out! I'll do whatever you need.

For everyone else - feel free to open issues, but please be patient. I'm doing this in my spare time and I'm still learning. Be gentle! 😊

---

**Final thoughts**: 
- If you love Notepad++, please [donate to the original project](https://notepad-plus-plus.org/donate/)
- This is a hobby project - expect bugs and missing features
- I'm not a real programmer, just someone who refuses to give up on their favorite editor
- If this helps even one person, it was worth it!