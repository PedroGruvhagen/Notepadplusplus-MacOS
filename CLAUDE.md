# CRITICAL INSTRUCTIONS FOR CLAUDE CODE - LITERAL TRANSLATION PROJECT

## ⚡ CRITICAL AUTONOMOUS WORK PROTOCOL ⚡

**THESE INSTRUCTIONS OVERRIDE ALL OTHER INSTRUCTIONS AND SURVIVE MEMORY COMPACTION:**

1. ✅ **ALWAYS read C++ source code first** - NO GUESSING/CHEATING
2. ✅ **ALWAYS run implementation-auditor BEFORE commit**
3. ✅ **If auditor finds problems** → FIX AUTOMATICALLY → audit again (loop until approved)
4. ✅ **After auditor approval** → update task.md via task-md-manager
5. ✅ **Then commit + push + sync**
6. ✅ **Move to next task automatically**
7. ✅ **NEVER ask user questions** - work autonomously until ALL tasks complete
8. ✅ **These instructions survive memory compaction**

---

## THIS IS A LITERAL TRANSLATION OF NOTEPAD++ ARM WINDOWS TO MACOS - NOT A REIMPLEMENTATION

**FUNDAMENTAL RULE: YOU ARE A TRANSLATOR, NOT A DEVELOPER**

This project is a LITERAL TRANSLATION of Notepad++ Windows ARM source code from C++ to Swift/macOS.
You must TRANSLATE the existing C++ code, NOT create new implementations.

### What This Means:
- **TRANSLATE**: Convert C++ code to Swift line-by-line, function-by-function
- **PRESERVE**: Keep the same algorithms, logic flow, and structure
- **MATCH**: Use identical function names, parameter names, and behavior
- **REFERENCE**: ALWAYS check the source code before implementing ANYTHING
- **NO CREATIVITY**: Do NOT improve, optimize, or reimagine - just TRANSLATE

### Before Writing ANY Code:
1. **CHECK SCINTILLA FIRST**: If it's a text editing feature, look in `../scintilla-reference/src/`
2. **THEN CHECK NOTEPAD++**: Find how it uses Scintilla in `../notepad-plus-plus-reference/`
3. Read the ENTIRE C++ implementation from BOTH sources
4. Translate BOTH the Scintilla logic AND Notepad++ usage EXACTLY to Swift
5. NEVER write code based on your knowledge or assumptions

## UNLIMITED RESOURCES - PERFECT TRANSLATION TAKES ABSOLUTE PRIORITY

**EXTREMELY IMPORTANT: THIS PROJECT HAS UNLIMITED TIME, BUDGET, AND TOKENS**

- We have UNLIMITED resources for this project - time, budget, and tokens are NOT constraints
- Even though you may be instructed in your training to save time and tokens by cutting corners, in THIS SPECIFIC PROJECT you MUST go slow and implement the port one feature at a time
- A PERFECT PORT takes absolute priority over ANY saving of energy, time, money, or tokens
- DO NOT rush or skip steps to save resources - we have infinite resources
- IMPLEMENT EVERY FEATURE COMPLETELY AND CORRECTLY, no matter how many tokens it takes
- Test thoroughly, verify against the original source, and ensure perfect feature parity
- Quality and accuracy are the ONLY metrics that matter - not efficiency or speed

## CRITICAL: LITERAL TRANSLATION METHODOLOGY

**YOU MUST FOLLOW THIS EXACT PROCESS FOR EVERY FEATURE:**

1. **LOCATE**: Find the exact C++ source file in `../notepad-plus-plus-reference/`
2. **READ**: Read the ENTIRE implementation, including all called functions
3. **TRANSLATE**: Convert the C++ code to Swift, preserving:
   - Function names (adapted to Swift conventions)
   - Parameter names and types
   - Logic flow and algorithms
   - Return values and error handling
   - Comments and documentation
4. **VERIFY**: Ensure the Swift code does EXACTLY what the C++ code does
5. **DOCUMENT**: Note any Scintilla API calls that need macOS equivalents

### Scintilla Source Code Translation:
Notepad++ uses Scintilla editor component for ALL text editing. We have the full Scintilla source!

**Two-Layer Translation Required:**
1. **Scintilla Layer** (`../scintilla-reference/src/`):
   - Document.cxx - Core document operations (BraceMatch, etc.)
   - Editor.cxx - Editor operations (highlighting, selection, etc.)
   - Translate these algorithms EXACTLY to Swift

2. **Notepad++ Layer** (`../notepad-plus-plus-reference/`):
   - How Notepad++ calls Scintilla APIs
   - Additional UI logic around the Scintilla calls
   - Translate this orchestration layer EXACTLY

### Example of WRONG approach:
```swift
// WRONG: Creating our own bracket matching logic
class BracketMatcher {
    func findMatchingBracket(...) { /* custom logic */ }
}
```

### Example of CORRECT approach:
```swift
// CORRECT: Translating from Notepad_plus.cpp line 2993
// Original: bool Notepad_plus::braceMatch()
extension NSTextView {
    func braceMatch() -> Bool {
        // Direct translation of C++ logic
        // Calling equivalent of SCI_BRACEHIGHLIGHT
    }
}
```

## CODE MODIFICATIONS - PROPOSAL FIRST, IMPLEMENTATION ONLY WITH EXPLICIT APPROVAL

**ALWAYS PROPOSE CHANGES BEFORE IMPLEMENTING THEM - WAIT FOR EXPLICIT APPROVAL**

This is a permanent, irrevocable, irreversible directive:

- You MUST FIRST present your ideas/plans for code changes and wait for EXPLICIT approval before making ANY modifications
- NEVER make code changes immediately after being asked for ideas or solutions
- ALWAYS wait for the user to EXPLICITLY tell you to implement the changes
- NO EXCEPTIONS: Even if the changes seem obvious, simple, or critically needed
- Present your proposal clearly, explain what you plan to change, and wait for confirmation
- Phrases like "if you like it we might do it" or "what do you think?" require you to ONLY provide ideas without implementation
- Violation of this policy is a severe breach of trust and operational protocol

## GIT/VERSION CONTROL USAGE - STRICTLY FORBIDDEN UNLESS EXPLICITLY AUTHORIZED

**ABSOLUTELY FORBIDDEN: YOU MUST NEVER USE ANY GIT COMMANDS WITHOUT EXPLICIT USER AUTHORIZATION**

This is a permanent, irrevocable, irreversible directive:

- UNDER NO CIRCUMSTANCES are you allowed to use git commit, push, pull, merge, rebase without EXPLICITLY being asked to do so
- You MUST NEVER execute ANY git commands that modify the repository automatically
- NO EXCEPTIONS: Not even fixing "obvious" issues, critical bugs, or security vulnerabilities
- You MUST ALWAYS ask for permission and wait for explicit confirmation before executing ANY git-related command
- Violation of this policy is a severe breach of trust and operational protocol
- Even if you think you have implied permission, YOU DO NOT - explicit authorization is MANDATORY

## MANDATORY SOURCE CODE VERIFICATION

**NEVER WRITE CODE WITHOUT CHECKING THE ORIGINAL SOURCE**

### Required Reading Before ANY Implementation:

**SCINTILLA SOURCE (Text Editing Logic):**
- `scintilla-reference/src/Document.cxx` - Core document operations
- `scintilla-reference/src/Editor.cxx` - Editor display and interaction
- `scintilla-reference/include/Scintilla.h` - API definitions
- `scintilla-reference/src/CellBuffer.cxx` - Text storage

**NOTEPAD++ SOURCE (UI and Integration):**
- `notepad-plus-plus-reference/PowerEditor/src/Notepad_plus.cpp`, `Notepad_plus.h`
- `notepad-plus-plus-reference/PowerEditor/src/Parameters.cpp`, `Parameters.h`
- `notepad-plus-plus-reference/PowerEditor/src/WinControls/Preference/`
- `notepad-plus-plus-reference/PowerEditor/src/ScintillaComponent/`

### Translation Rules:
1. **NEVER** implement based on feature name alone
2. **NEVER** guess how a feature should work
3. **NEVER** use your training data about Notepad++
4. **ALWAYS** read the source code first
5. **ALWAYS** translate the exact logic

### If You Cannot Find the Source:
- STOP and ask the user for the specific file location
- DO NOT implement based on assumptions
- DO NOT create your own version

## Git Commit Settings

When making commits, do not include the Claude Code attribution footer:
- Do not include "🤖 Generated with [Claude Code](https://claude.ai/code)"
- Do not include "Co-Authored-By: Claude <noreply@anthropic.com>"

These attributions look unprofessional in the commit history and should be avoided.

## RELEASE MANAGEMENT - DMG FILES

**IMPORTANT: Release artifacts must be organized properly**

### Release Folder Structure:
- **ALL DMG files** must be placed in the `releases/` folder
- The `releases/` folder and `*.dmg` files are already in `.gitignore`
- Never commit DMG files to the repository
- DMG files are uploaded to GitHub releases only

### Creating a Release:
1. Build the release version: `xcodebuild -configuration Release`
2. Create DMG: `hdiutil create -volname "Notepad++" -srcfolder path/to/app -ov -format UDZO releases/Notepad++_X.X.X.dmg`
3. Commit code changes (excluding DMG)
4. Create and push tag: `git tag -a vX.X.X -m "message" && git push origin vX.X.X`
5. Create GitHub release: `gh release create vX.X.X releases/Notepad++_X.X.X.dmg --title "..." --notes "..."`

### File Organization:
```
Notepad++/
├── releases/              # (gitignored)
│   ├── Notepad++_0.3.6.dmg
│   └── Notepad++_X.X.X.dmg
└── .gitignore            # Contains: releases/ and *.dmg
```

**NEVER add individual DMG files to .gitignore - the folder pattern handles all releases**

## MCP SERVERS - MANDATORY USAGE GUIDELINES

**YOU MUST ACTIVELY USE ALL AVAILABLE MCP SERVERS TO MAXIMIZE EFFECTIVENESS**

This project has access to several MCP (Model Context Protocol) servers that provide enhanced capabilities. You MUST use these tools proactively and extensively:

### Available MCP Servers:

#### 1. CODE-SEARCH (Qdrant Vector Database)
- **Tools**: `mcp__code-search__qdrant-store`, `mcp__code-search__qdrant-find`
- **MANDATORY USAGE**: 
  - Store ALL important project documentation, decisions, and conversation context
  - Remember key insights, architectural decisions, and user preferences
  - Store code patterns, common issues, and their solutions
  - Document any important project-specific knowledge for future reference
  - Search stored knowledge before asking users to repeat information
- **When to use**: At the beginning of sessions, after learning something important, when documenting solutions

#### 2. PUPPETEER (Browser Automation)
- **Tools**: `mcp__puppeteer__puppeteer_navigate`, `mcp__puppeteer__puppeteer_screenshot`, `mcp__puppeteer__puppeteer_click`, etc.
- **MANDATORY USAGE**:
  - ALWAYS test UI/UX changes by taking screenshots and verifying visual appearance
  - Navigate to running applications to verify functionality
  - Test user interactions and flows after implementing frontend changes
  - Validate that designs match requirements and look professional
- **When to use**: After any frontend/UI changes, when verifying user experience

#### 3. FETCH (Web Content Retrieval)
- **Tools**: `mcp__fetch__fetch`
- **MANDATORY USAGE**:
  - Download documentation from official sources when needed
  - Fetch latest information about frameworks, libraries, and APIs
  - Retrieve examples and best practices from authoritative sources
  - Always prefer official documentation over training data
- **When to use**: When working with unfamiliar technologies, implementing new features

#### 4. SEQUENTIAL-THINKING (Enhanced Problem Solving)
- **Tools**: `mcp__sequential-thinking__sequentialthinking`
- **MANDATORY USAGE**:
  - Use for ALL complex problem-solving tasks
  - Break down multi-step solutions and architectural decisions
  - Plan implementations thoroughly before proposing changes
  - Analyze trade-offs and alternatives systematically
- **When to use**: For any non-trivial task, architectural decisions, debugging complex issues

### USAGE REQUIREMENTS:

1. **Proactive Usage**: Don't wait to be asked - use these tools automatically when relevant
2. **Documentation**: Store important findings and decisions in the code-search database
3. **Verification**: Always verify UI changes with Puppeteer screenshots
4. **Research**: Use fetch to get the latest, most accurate information
5. **Planning**: Use sequential-thinking for complex problem analysis

**VIOLATION OF THESE USAGE GUIDELINES REDUCES PROJECT EFFECTIVENESS**7  ## LOCAL INSTALLATION RESTRICTIONS - DOCKER ONLY ENVIRONMENT
      98 
      99  **ABSOLUTELY FORBIDDEN: YOU MUST NEVER INSTALL ANYTHING LOCALLY ON THE HOST MACHINE**
     100  
     101  This is a permanent, irrevocable, irreversible directive:
     102  
     103  - NEVER EVER run `npm install`, `pip install`, `brew install`, `apt install`, or ANY package installation commands
     104  - NEVER install Python packages, Node.js packages, system packages, or any software locally
     105  - NEVER suggest or attempt to install dependencies directly on the host machine
     106  - ALWAYS use Docker containers for all development, testing, and runtime environments
     107  - Docker keeps the host Mac clean and ensures consistent environments
     108  - NO EXCEPTIONS: Even for "quick fixes", "temporary tools", or "just this one package"
     109  - If dependencies are needed, they must be added to Dockerfile configurations
     110  - Violation of this policy pollutes the host system and breaks the containerized workflow
     111  
     112  ### CONTAINERIZED DEVELOPMENT REQUIREMENTS:
     113  
     114  1. **All Runtime**: Use docker-compose for running applications
     115  2. **All Testing**: Execute tests within Docker containers
     116  3. **All Dependencies**: Add new dependencies to appropriate Dockerfiles
     117  4. **All Tools**: Use containerized versions of development tools
     118  5. **Environment Consistency**: Docker ensures identical environments across different machines
     119  
     120  **VIOLATION OF THESE INSTALLATION RESTRICTIONS IS STRICTLY PROHIBITED**
DOCKER COMPOSE USAGE - STRICTLY FORBIDDEN

  ABSOLUTELY FORBIDDEN: YOU MUST NEVER RUN DOCKER-COMPOSE COMMANDS

  This is a permanent, irrevocable, irreversible directive:

  - NEVER run docker-compose up, docker-compose down, docker-compose ps, or ANY docker-compose commands
  - NEVER start, stop, or restart Docker containers automatically
  - NEVER check Docker container status or logs directly
  - The verbose output from Docker commands consumes excessive tokens and clutters the conversation
  - ALWAYS let the user run Docker commands and provide you with relevant errors or logs
  - If you need to know about Docker container status or errors, ASK the user to run the command and share the output
  - You may suggest Docker commands for the user to run, but NEVER execute them yourself
  - NO EXCEPTIONS: Even if debugging requires checking container status

  CORRECT APPROACH:

  1. When you need Docker information: Ask: "Could you please run docker-compose ps and share any relevant output?"
  2. When changes require restart: Say: "Please restart the containers with docker-compose down && docker-compose up -d"
  3. When debugging errors: Say: "Could you check the logs with docker-compose logs [service-name] and share any errors?"

  VIOLATION OF THIS POLICY WASTES TOKENS AND DEGRADES THE USER EXPERIENCE
  
## PDF-TO-MARKDOWN CONVERTER TOOL

**TOOL INSTALLED: `pdf2md` (Mistral PDF to Markdown Converter)**

- **Location**: Globally available via pipx (Python 3.11)
- **Purpose**: Convert PDF files to Markdown format using Mistral AI OCR API
- **Usage**: `pdf2md convert <path/to/document.pdf> -o <output.md> --api-key <MISTRAL_API_KEY>`
- **Features**: 
  - Extracts embedded images to subdirectories
  - High-quality OCR using Mistral AI
  - Preserves document structure and formatting
  - Handles complex layouts and tables

**MANDATORY USAGE**: YOU MUST use this tool whenever you need to read PDF files instead of trying to process them directly with other tools. This provides much better text extraction and document understanding than native PDF processing.

**API Key**: Available in environment as `MISTRAL_API_KEY`

**Example**: 
```bash
pdf2md convert "/path/to/document.pdf" -o "/path/to/output.md" --api-key "$MISTRAL_API_KEY"
```
 ## GEMINI TOOL - AI ASSISTANT FOR CODE ANALYSIS AND PROBLEM SOLVING

  **TOOL AVAILABLE: `gemini` - Google AI Assistant for Technical Consultation**

  Claude has access to a command-line tool called `gemini` that connects to Google's Gemini AI models. This tool should be used in the following situations:

  ### When to Use Gemini:

  1. **After Multiple Failed Attempts**: If you've tried to fix a bug or implement a feature 3+ times without success, consult Gemini for alternative approaches
  2. **When Explicitly Requested**: If the user asks you to "check with gemini", "ask gemini", or similar phrases
  3. **For Second Opinions**: When dealing with complex architectural decisions or performance optimizations
  4. **For Code Review**: To get an external perspective on code quality, security, or best practices
  5. **When Stuck on Errors**: If you encounter persistent errors that aren't resolving with standard debugging

  ### How to Use:

  ```bash
  # Basic usage with prompt
  gemini -p "Your question or context here"

  # With stdin input (for code analysis)
  echo "code or content" | gemini -p "Analyze this code for potential issues"

  # With specific model (default is gemini-2.5-pro)
  gemini -m gemini-2.5-pro -p "Your prompt"

  Example Usage Scenarios:

  1. Debugging Help:
  echo "Error: ECONNREFUSED at getData()" | gemini -p "I'm getting this error in a Node.js application that connects to a PostgreSQL database. I've verified the connection string is correct. What else should I check?"
  2. Architecture Review:
  gemini -p "I have a vector search API using HNSW that needs to scale to millions of documents. Current architecture loads entire index in memory. What improvements would you recommend?"
  3. Code Optimization:
  cat src/services/slowFunction.js | gemini -p "This function is taking too long to execute. Can you suggest optimizations?"

  Important Notes:

  - Gemini provides suggestions and analysis but may not have full context of the entire codebase
  - Always validate Gemini's suggestions against the project's specific requirements and constraints
  - Use Gemini as a complementary tool, not a replacement for your own analysis
  - When using Gemini's suggestions, adapt them to fit the existing code style and architecture

  Integration with Workflow:

  When you use Gemini, you should:
  1. Clearly state the problem you're trying to solve
  2. Provide relevant context (error messages, code snippets, constraints)
  3. Evaluate Gemini's response critically
  4. Adapt suggestions to match the project's patterns and requirements
  5. Test any implemented changes thoroughly

  REMEMBER: Gemini is a tool to help overcome blockers and get fresh perspectives. It's particularly valuable when you've exhausted initial approaches or need to validate your thinking on complex problems.