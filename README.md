# TerminalUI

A Swift library for building rich, interactive terminal user interfaces with a declarative SwiftUI-like DSL.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgray.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- 🎨 **Declarative DSL** - Build terminal UIs with a familiar SwiftUI-like syntax
- 🚀 **High Performance** - Efficient differential rendering with reconciliation
- 🎭 **Rich Components** - Text styling, progress bars, spinners, tables, and more
- 🌈 **Smart Color Support** - Automatic fallback from TrueColor → 256 → 16 colors
- 📊 **Tracing Integration** - Built on swift-distributed-tracing for observability
- ⚡ **Async/Await** - Modern Swift concurrency with actor-based runtime
- 🔧 **Type-Safe** - Compile-time safety with strong typing throughout

## Installation

Add TerminalUI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/TerminalUI.git", from: "1.0.0")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["TerminalUI"]
)
```

## Quick Start

```swift
import TerminalUI

// Simple text output
Text("Hello, Terminal!")
    .foreground(.cyan)
    .bold()

// Progress bar
ProgressView(label: "Downloading", value: 0.7)

// Spinner animation
Spinner("Loading...")
    .style(.dots)

// Layout with VStack
VStack {
    Text("Terminal UI").bold()
    Divider()
    Text("Build beautiful terminal interfaces")
    Badge("NEW").tint(.success)
}

// Data display with ForEach
let items = ["Apple", "Banana", "Cherry"]
VStack {
    Text("Fruits:").bold()
    ForEach(items, id: \.self) { item in
        Text("• \(item)")
    }
}
```

## Component Library

### Layout Components

```swift
// Vertical stack
VStack(alignment: .leading, spacing: 1) {
    Text("Line 1")
    Text("Line 2")
}

// Horizontal stack
HStack(spacing: 2) {
    Badge("Status")
    Text("Running")
}

// Panel with border
Panel(title: "Information") {
    Text("Panel content here")
}
```

### Text Components

```swift
// Styled text
Text("Important")
    .foreground(.red)
    .background(.yellow)
    .bold()
    .underline()

// Semantic notes
Note("Success!", kind: .success)
Note("Warning!", kind: .warning)
Note("Error occurred", kind: .error)

// Badges
Badge("NEW").tint(.accent)
Badge("BETA").tint(.warning)

// Code blocks with syntax highlighting
Code("""
    func hello() {
        print("World")
    }
    """, language: .swift)
```

### Progress Components

```swift
// Determinate progress
ProgressView(label: "Processing", value: 0.65)

// Indeterminate progress
ProgressView.spinning("Loading")

// Custom spinner styles
Spinner("Connecting...")
    .style(.dots)  // or .line, .arc, .bounce, .braille

// Visual meter
Meter(value: 0.8, width: 20)
    .style(.blocks)
```

### Data Components

```swift
// Tables
Table(data: users) { user in
    TableRow {
        TableCell(user.name)
        TableCell(user.email)
        TableCell(user.status)
    }
}

// Key-value pairs
KeyValue([
    ("Name", "John Doe"),
    ("Email", "john@example.com"),
    ("Status", "Active")
], alignment: .aligned(keyWidth: 10))

// Lists
List(items) { item in
    Text("• \(item.title)")
}
```

### Data Iteration

```swift
// ForEach with Identifiable items
struct Todo: Identifiable {
    let id = UUID()
    let title: String
}

ForEach(todos) { todo in
    Text(todo.title)
}

// ForEach with explicit ID
ForEach(items, id: \.name) { item in
    Text(item.name)
}

// ForEach with ranges
ForEach(0..<10) { index in
    Text("Item \(index)")
}
```

## Advanced Features

### Animations

```swift
// Shimmer effect
Text("Loading...")
    .shimmer(duration: 2.0)

// Pulse animation
Badge("LIVE")
    .pulse(duration: 1.0)

// Blink effect
Text("Alert!")
    .blink(duration: 0.5)
```

### Theming

```swift
// Use semantic colors
Text("Success").foreground(.semantic(.success))
Text("Error").foreground(.semantic(.error))

// Custom themes
let customTheme = Theme(
    accent: .cyan,
    success: .green,
    warning: .yellow,
    error: .red
)
```

### Conditional Rendering

```swift
VStack {
    if isLoggedIn {
        Text("Welcome back!")
    } else {
        Text("Please log in")
    }
    
    switch status {
    case .loading:
        Spinner("Loading...")
    case .success(let data):
        Text(data)
    case .error(let error):
        Note(error.localizedDescription, kind: .error)
    }
}
```

## Architecture

TerminalUI uses a virtual DOM-like approach with efficient reconciliation:

1. **Declarative Views** → **Node Tree** → **Reconciliation** → **Render Commands** → **Terminal Output**

Key concepts:
- **Address**: Hierarchical position (e.g., "vstack.text.0")
- **LogicalID**: Stable identity for diffing
- **Reconciler**: Efficient tree diffing algorithm
- **TerminalRuntime**: Central actor managing rendering

## Performance

- Automatic frame rate limiting (default 15 FPS)
- Efficient diff-based updates
- Smart color degradation based on terminal capabilities
- Memory-efficient node recycling

## Requirements

- Swift 5.9+
- macOS 12.0+ / Linux
- Terminal with ANSI escape sequence support

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Author

Created by [@1amageek](https://x.com/1amageek)

## License

TerminalUI is available under the MIT license. See the LICENSE file for more details.