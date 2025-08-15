// Test file for Notepad++ syntax highlighting
import SwiftUI

struct TestView: View {
    @State private var count = 0
    let message = "Hello, Notepad++!"
    
    var body: some View {
        VStack {
            Text(message)
                .font(.title)
            
            Button("Count: \(count)") {
                count += 1
            }
        }
        .padding()
    }
}

// This should show:
// - Blue keywords (struct, var, let, import)
// - Purple types (View, VStack, Text, Button)
// - Gray strings ("Hello, Notepad++!")
// - Orange numbers (0, 1)
// - Green comments (like this one)