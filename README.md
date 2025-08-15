# Notepad++ for macOS (Unofficial)

A native macOS implementation of the beloved Notepad++ text editor, built with Swift and SwiftUI, optimized for Apple Silicon.

## 🎯 Project Goal

Bring the power and simplicity of Notepad++ to macOS users with a fully native experience that runs seamlessly on Apple Silicon (M1/M2/M3) Macs.

## 🙏 Attribution

This project is **inspired by [Notepad++](https://notepad-plus-plus.org/)**, the fantastic open-source text editor created by Don Ho. We have tremendous respect for the original project and its community.

- **Original Notepad++**: [GitHub](https://github.com/notepad-plus-plus/notepad-plus-plus) | [Website](https://notepad-plus-plus.org/)
- **Original License**: GPL v3
- **Original Author**: Don Ho and contributors

**Important**: This is an independent implementation and is NOT officially affiliated with or endorsed by Notepad++ unless explicitly stated.

## 📝 Letter to Notepad++ Team

Dear Don Ho and Notepad++ Team,

We've created this macOS port out of love for Notepad++ and a desire to bring its functionality to Mac users. We would be honored if you would consider:

1. Reviewing this implementation
2. Potentially adopting it as an official macOS version
3. Providing guidance on feature parity with the Windows ARM version
4. Advising on trademark usage and naming

We're committed to respecting your project and will make any changes you request.

## 🚀 Features

### Currently Implemented
- ✅ Multi-tab interface
- ✅ Native Apple Silicon support (ARM64)
- ✅ File operations (New, Open, Save, Save As)
- ✅ Line numbers
- ✅ Status bar with line/column info
- ✅ Font size adjustment
- ✅ Modified indicator
- ✅ File type detection with icons

### Roadmap (Matching Notepad++ ARM)
- [ ] Syntax highlighting for 70+ languages
- [ ] Find & Replace with regex
- [ ] Multi-cursor editing
- [ ] Code folding
- [ ] Split view
- [ ] Macro recording
- [ ] Plugin system
- [ ] Theme support
- [ ] Session management
- [ ] Auto-completion
- [ ] Function list
- [ ] Document map

## 💻 System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1/M2/M3) or Intel Mac
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

- **Native Performance**: Built specifically for macOS and Apple Silicon
- **macOS Integration**: Uses native macOS APIs and follows Apple's Human Interface Guidelines
- **Feature Parity**: Aims to match Notepad++ Windows ARM version features
- **Open Source**: Free and open for the community

## 📊 Comparison with Original

| Feature | Notepad++ Windows | This macOS Version |
|---------|-------------------|-------------------|
| Multi-tab | ✅ | ✅ |
| Syntax Highlighting | ✅ | 🚧 In Progress |
| Find/Replace | ✅ | 🚧 In Progress |
| Plugins | ✅ | 📋 Planned |
| Themes | ✅ | 📋 Planned |
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