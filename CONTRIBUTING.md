# Contributing to Notepad++ for macOS

First off, thank you for considering contributing to this project! This is a DIRECT PORT of Notepad++ Windows ARM version to macOS, not a reimplementation.

## 🎯 Project Goals

This is a direct port - we aim for 100% feature parity with Notepad++ Windows ARM version while maintaining:
- Native macOS performance
- Apple Silicon optimization
- Respect for the original Notepad++ project

## 📋 Before You Contribute

1. **Check existing issues** - Someone might already be working on it
2. **Discuss major changes** - Open an issue first to discuss your idea
3. **Respect Notepad++ design** - We aim to match the original UX where possible

## 🚀 How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- macOS version
- Mac type (Intel or Apple Silicon)
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots if applicable

### Suggesting Features

We primarily focus on features that exist in Notepad++ Windows. When suggesting features:

1. Check if it exists in Notepad++ Windows
2. Explain the use case
3. Provide examples from Notepad++ if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Test on both Intel and Apple Silicon if possible
5. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
6. Push to the branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

## 🏗️ Development Setup

```bash
# Prerequisites
# - Xcode 16.0+
# - macOS 14.0+
# - Swift 5.9+

# Clone your fork
git clone https://github.com/yourusername/Notepad--.git
cd Notepad--

# Open in Xcode
open Notepad++.xcodeproj

# Build and run
# Press ⌘R in Xcode
```

## 📝 Coding Standards

### Swift Style Guide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI where possible
- Prefer `@StateObject` and `@ObservedObject` for view models
- Use meaningful variable names
- Add comments for complex logic

### File Organization

```
Notepad++/
├── Models/          # Data models
├── Views/           # SwiftUI views
├── ViewModels/      # View logic and state
├── Services/        # Business logic
├── Extensions/      # Swift extensions
└── Resources/       # Assets, themes, languages
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests

Examples:
```
Add syntax highlighting for Swift
Fix memory leak in document manager
Update README with build instructions
```

## 🎨 UI/UX Guidelines

- **Match Notepad++ where possible** - Users expect familiar functionality
- **Follow macOS conventions** - Use native controls and behaviors
- **Support Dark Mode** - Ensure all UI works in both light and dark modes
- **Keyboard shortcuts** - Implement standard Mac shortcuts (⌘ instead of Ctrl)

## 🧪 Testing

- Test your changes on both Intel and Apple Silicon Macs if possible
- Test with large files (>10MB)
- Test with various file encodings
- Verify no memory leaks using Instruments

## 📚 Priority Features

High priority (please help with these!):

1. **Syntax Highlighting** - Core feature needed
2. **Find & Replace** - Essential for any text editor
3. **Multi-cursor editing** - Popular Notepad++ feature
4. **Code folding** - Important for code editing
5. **Theme support** - Users love customization

## 🤝 Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what's best for the community
- Show empathy towards others

### Attribution

This is a DIRECT PORT of Notepad++. Always:
- Give credit to the original project
- Respect their trademark and branding
- Follow the exact feature implementation from the original
- Check the original source code when implementing features

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙋 Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Contact maintainers

## 🌟 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Special thanks in About dialog

Thank you for helping bring Notepad++ to macOS! 🎉