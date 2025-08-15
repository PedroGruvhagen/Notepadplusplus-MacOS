//
//  FindReplaceTestView.swift
//  Notepad++
//
//  Test view for Find/Replace functionality
//

import SwiftUI

struct FindReplaceTestView: View {
    @StateObject private var document = Document(content: "", filePath: nil)
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    let testContent = """
    This is a test document with some text.
    We need to test the find and replace functionality.
    The word test appears multiple times in this text.
    Testing is important for any test application.
    This line also contains the word test.
    Let's add more content to test the search feature.
    Search and replace is a critical feature in any text editor.
    We should test both case-sensitive and case-insensitive search.
    TEST, Test, test - all these variations should be found.
    Regular expressions are also important to test.
    The find bar should highlight all matches.
    Navigation between matches should work with keyboard shortcuts.
    """
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Find/Replace Test Suite")
                .font(.title)
                .padding()
            
            // Main editor with Find/Replace
            VStack(spacing: 0) {
                FindReplaceBar(
                    document: document,
                    showReplace: .constant(true),
                    isVisible: .constant(true)
                )
                
                TextEditor(text: .constant(document.content))
                    .font(.system(size: 13, design: .monospaced))
                    .frame(minHeight: 300)
                    .border(Color.gray.opacity(0.3))
            }
            .padding()
            
            // Test Controls
            HStack(spacing: 20) {
                Button("Load Test Content") {
                    document.updateContent(testContent)
                    testResults.append("✅ Test content loaded")
                }
                
                Button("Run All Tests") {
                    runAllTests()
                }
                .disabled(isRunningTests)
                
                Button("Clear Results") {
                    testResults.removeAll()
                }
            }
            
            // Test Results
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: 200)
            .border(Color.gray.opacity(0.3))
        }
        .frame(width: 800, height: 700)
        .onAppear {
            document.updateContent(testContent)
        }
    }
    
    private func runAllTests() {
        isRunningTests = true
        testResults.removeAll()
        
        // Test 1: Basic search
        testResults.append("🔍 Test 1: Basic Search")
        let searchManager = SearchManager()
        let options = SearchOptions()
        options.searchText = "test"
        
        let matches = searchManager.findAll(
            in: document.content,
            searchText: "test",
            options: options
        )
        testResults.append("  Found \(matches.count) matches for 'test'")
        
        // Test 2: Case sensitive search
        testResults.append("🔍 Test 2: Case Sensitive Search")
        options.caseSensitive = true
        let caseSensitiveMatches = searchManager.findAll(
            in: document.content,
            searchText: "test",
            options: options
        )
        testResults.append("  Found \(caseSensitiveMatches.count) case-sensitive matches")
        
        // Test 3: Whole word search
        testResults.append("🔍 Test 3: Whole Word Search")
        options.caseSensitive = false
        options.wholeWord = true
        let wholeWordMatches = searchManager.findAll(
            in: document.content,
            searchText: "test",
            options: options
        )
        testResults.append("  Found \(wholeWordMatches.count) whole word matches")
        
        // Test 4: Regex search
        testResults.append("🔍 Test 4: Regex Search")
        options.wholeWord = false
        options.useRegex = true
        options.searchText = "test\\w*"
        let regexMatches = searchManager.findAll(
            in: document.content,
            searchText: "test\\w*",
            options: options
        )
        testResults.append("  Found \(regexMatches.count) regex matches for 'test\\w*'")
        
        // Test 5: Replace functionality
        testResults.append("🔄 Test 5: Replace Functionality")
        options.useRegex = false
        options.searchText = "test"
        let testDoc = Document(content: "This is a test.", filePath: nil)
        testDoc.updateContent("This is a test.")
        let replacedContent = searchManager.replace(
            in: testDoc,
            at: NSRange(location: 10, length: 4)
        )
        testResults.append("  Replace result: '\(replacedContent.prefix(20))...'")
        
        // Test 6: Replace All
        testResults.append("🔄 Test 6: Replace All")
        let (_, count) = searchManager.replaceAll(in: testDoc)
        testResults.append("  Replaced \(count) occurrences")
        
        testResults.append("\n✅ All tests completed!")
        isRunningTests = false
    }
}

#Preview {
    FindReplaceTestView()
}