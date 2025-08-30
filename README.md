# TerminalUI

A Swift library for building rich, interactive terminal user interfaces with a declarative SwiftUI-like DSL.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgray.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- 🎨 **Declarative DSL** - Build terminal UIs with a familiar SwiftUI-like syntax
- 🚀 **High Performance** - Efficient differential rendering with reconciliation
- 🎭 **Streamlined Components** - Essential terminal UI components without bloat (14 total)
- 🌈 **Smart Color Support** - Automatic fallback from TrueColor → 256 → 16 colors
- 📊 **Tracing Integration** - Optional observability via swift-distributed-tracing
- ⚡ **Async/Await** - Modern Swift concurrency with actor-based runtime
- 🔧 **Type-Safe** - Compile-time safety with strong typing and Sendable conformance

## Installation

Add TerminalUI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/TerminalUI.git", from: "1.0.0")
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

## Recent Changes

### ✨ New Components Added
- **Spacer** - Flexible space that expands to fill available area
- **Button** - Interactive button with keyboard shortcut support
- **Selector** - Selection UI for multiple options with ForEach-like syntax

### 🗑️ Components Removed
To streamline the library and follow terminal UI best practices, the following redundant components were removed:
- **Badge** - Use Text with styling instead
- **Code** - Use Text with monospace font instead  
- **Note** - Use Text with semantic colors instead
- **Grid** - Use Table for structured data display
- **KeyValue** - Use HStack with Text components instead
- **Meter** - Use ProgressView for progress indication

## Component Library (14 Total Components)

### Layout Components (7)

- **VStack** - Vertical stacking container
- **HStack** - Horizontal stacking container  
- **Spacer** - Flexible space that expands
- **Divider** - Horizontal line separator  
- **Panel** - Box container with optional border and title
- **Group** - Logical grouping without visual representation
- **EmptyView** - View that renders nothing

```swift
// Vertical stack
VStack(alignment: .leading, spacing: 1) {
    Text("Line 1")
    Text("Line 2")
}

// Horizontal stack  
HStack(spacing: 2) {
    Text("Left")
    Spacer()
    Text("Right")
}

// Panel with border
Panel(title: "Information") {
    Text("Panel content here")
}
```

### Text Components (2)

- **Text** - Basic text with style modifiers
- **List** - Display items in various list styles

```swift
// Styled text
Text("Important")
    .foreground(.red)
    .background(.yellow)
    .bold()
    .underline()
    
// Lists with different styles
List(items: listItems, style: .bulleted)  // • Item
List(items: listItems, style: .numbered)  // 1. Item
List(items: listItems, style: .checkbox)  // ☐ Item

// Nested lists
List {
    Text("Item 1")
    List {
        Text("Sub Item 1.1")
        Text("Sub Item 1.2")
    }
    Text("Item 2")
}
```

### Data Components (2)

- **Table** - Tabular data display with customizable columns
- **Tree** - Hierarchical tree structure display

```swift
// Table with columns
let columns = [
    TableColumn(id: "name", title: "Name", width: .fixed(20)),
    TableColumn(id: "status", title: "Status", width: .auto)
]

Table(columns: columns, rows: tableRows)

// Tree structure
let rootNode = TreeNode(
    id: "root",
    label: "Root",
    icon: "📁",
    children: [
        TreeNode(id: "child1", label: "Child 1"),
        TreeNode(id: "child2", label: "Child 2")
    ]
)

Tree(root: rootNode, showLines: true)
```

### Progress Components (2)

- **ProgressView** - Determinate/indeterminate progress bars
- **Spinner** - Animated loading indicators

```swift
// Determinate progress
ProgressView(label: "Processing", value: 0.65)

// Indeterminate progress
ProgressView(label: "Loading", indeterminate: true)

// Custom spinner styles
Spinner("Connecting...")
    .style(.dots)  // ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
```

### Input Components (3)

- **TextField** - Single-line text input
- **Button** - Interactive button with keyboard shortcuts
- **Selector** - Selection UI for multiple options with ForEach support

```swift
// Text input field
TextField(
    label: "Username",
    text: $username,
    placeholder: "Enter username"
)

// Button with action and keyboard shortcut
Button("Submit", shortcut: "s") {
    // Handle action
}

// Selector with ForEach
let options = ["Option 1", "Option 2", "Option 3"]
Selector($selectedOption) {
    ForEach(options, id: \.self) { option in
        Text(option)
    }
}
```

### Control Flow

- **ForEach** - Iterate over collections with stable IDs

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

### View Modifiers and Effects

```swift
// Text style modifiers
Text("Styled")
    .foreground(.cyan)
    .background(.blue)
    .bold()
    .italic()
    .underline()
    .dim()

// Animation effects (via ViewModifiers)
Text("Loading...")
    .shimmer(duration: 2.0)

Text("Alert!")
    .blink(duration: 0.5)

Text("Live")
    .pulse(duration: 1.0)
```

### Live Rendering

For dynamic updates without full screen refresh:

```swift
// Single element updates
let renderer = LiveRenderer()
await renderer.render(view)

// Multiple elements with LiveSession
let session = LiveSession()

// Add/update elements at specific positions
await session.update("header", at: Point(x: 0, y: 0), with: headerView)
await session.update("content", at: Point(x: 0, y: 2), with: contentView)
await session.update("footer", at: Point(x: 0, y: 10), with: footerView)

// Remove element
await session.remove("content")

// Redraw all elements
await session.redrawAll()
```

### Theming

```swift
// Use semantic colors
Text("Success").foreground(.semantic(.success))
Text("Error").foreground(.semantic(.error))
Text("Warning").foreground(.semantic(.warning))

// Custom themes
let customTheme = Theme(
    accent: .cyan,
    success: .green,
    warning: .yellow,
    error: .red,
    info: .blue
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
        Text(error.localizedDescription)
            .foreground(.red)
    }
}
```

## Architecture

TerminalUI uses a virtual DOM-like approach with efficient reconciliation:

1. **Declarative Views** → **Node Tree** → **Reconciliation** → **Render Commands** → **Terminal Output**

Key concepts:
- **NodeKind**: Enumeration of all component types (14 total)
- **Address**: Hierarchical position (e.g., "vstack.text.0")
- **LogicalID**: Stable identity for efficient diffing
- **Reconciler**: Efficient tree diffing algorithm
- **TerminalRuntime**: Central actor managing rendering
- **PropertyContainer**: Type-safe property storage system

## Performance

- Automatic frame rate limiting (default 15 FPS, configurable)
- Efficient diff-based updates via Reconciler
- Smart color degradation based on terminal capabilities
- Memory-efficient with immutable value types
- Sendable conformance for thread safety

## Requirements

- Swift 6.0+
- macOS 15.0+ / Linux
- Terminal with ANSI escape sequence support

## Dependencies

- [swift-distributed-tracing](https://github.com/apple/swift-distributed-tracing) (1.1.0+) - For optional tracing support

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

TerminalUI is available under the MIT license. See the LICENSE file for more details.