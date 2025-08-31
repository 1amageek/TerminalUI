# TerminalUI

A Swift library for building rich, interactive terminal user interfaces with a declarative SwiftUI-like DSL.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgray.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/1amageek/TerminalUI)

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

### Simple Text Output

```swift
import TerminalUI

Text("Hello, Terminal!")
    .foreground(.cyan)
    .bold()
```

**Output:**
```
Hello, Terminal!  // In cyan color with bold style
```

### Progress Bar

```swift
ProgressView(label: "Downloading", value: 0.7)
```

**Output:**
```
Downloading [████████████████████████████░░░░░░░░░░░] 70%
```

### Spinner Animation

```swift
Spinner("Loading...")
    .style(.dots)
```

**Output:** (animated)
```
⠋ Loading...
⠙ Loading...
⠹ Loading...
⠸ Loading...
⠼ Loading...
⠴ Loading...
```

### Layout with VStack

```swift
VStack {
    Text("Terminal UI").bold()
    Divider()
    Text("Build beautiful terminal interfaces")
}
```

**Output:**
```
Terminal UI        // Bold text
────────────────   // Horizontal line
Build beautiful terminal interfaces
```

### Data Display with ForEach

```swift
let items = ["Apple", "Banana", "Cherry"]
VStack {
    Text("Fruits:").bold()
    ForEach(items, id: \.self) { item in
        Text("• \(item)")
    }
}
```

**Output:**
```
Fruits:    // Bold text
• Apple
• Banana
• Cherry
```

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
```

**Output:**
```
Line 1
Line 2
```

```swift
// Horizontal stack  
HStack(spacing: 2) {
    Text("Left")
    Spacer()
    Text("Right")
}
```

**Output:**
```
Left  Right
```

```swift
// Panel with border
Panel(title: "Information") {
    Text("Panel content here")
}
```

**Output:**
```
┌─ Information ─────────────┐
│ Panel content here        │
└───────────────────────────┘
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
```

**Output:**
```
Important  // Red text on yellow background, bold and underlined
```

```swift
// Lists with different styles
List(items: ["Apple", "Banana"], style: .bulleted)
List(items: ["First", "Second"], style: .numbered)
List(items: ["Task 1", "Task 2"], style: .checkbox)
```

**Output:**
```
• Apple
• Banana

1. First
2. Second

☐ Task 1
☐ Task 2
```

```swift
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

**Output:**
```
• Item 1
  ◦ Sub Item 1.1
  ◦ Sub Item 1.2
• Item 2
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

let rows = [
    ["name": "Service A", "status": "Running"],
    ["name": "Service B", "status": "Stopped"]
]

Table(columns: columns, rows: rows)
```

**Output:**
```
┌────────────────────┬──────────┐
│ Name               │ Status   │
├────────────────────┼──────────┤
│ Service A          │ Running  │
│ Service B          │ Stopped  │
└────────────────────┴──────────┘
```

```swift
// Tree structure
let rootNode = TreeNode(
    id: "root",
    label: "Root",
    icon: "📁",
    children: [
        TreeNode(id: "child1", label: "Child 1", icon: "📄"),
        TreeNode(id: "child2", label: "Child 2", icon: "📁",
            children: [
                TreeNode(id: "grandchild", label: "Grandchild", icon: "📄")
            ])
    ]
)

Tree(root: rootNode, showLines: true)
```

**Output:**
```
📁 Root
├── 📄 Child 1
└── 📁 Child 2
    └── 📄 Grandchild
```

### Progress Components (2)

- **ProgressView** - Determinate/indeterminate progress bars
- **Spinner** - Animated loading indicators

```swift
// Determinate progress
ProgressView(label: "Processing", value: 0.65)
```

**Output:**
```
Processing [██████████████████████████░░░░░░░░░░░░░░] 65%
```

```swift
// Indeterminate progress
ProgressView(label: "Loading", indeterminate: true)
```

**Output:** (animated)
```
Loading [░░░░░░████░░░░░░]  // Moving bar animation
```

```swift
// Custom spinner styles
Spinner("Connecting...")
    .style(.dots)
```

**Output:** (animated)
```
⠋ Connecting...
⠙ Connecting...
⠹ Connecting...
⠸ Connecting...
⠼ Connecting...
⠴ Connecting...
⠦ Connecting...
⠧ Connecting...
⠇ Connecting...
⠏ Connecting...
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
```

**Output:**
```
Username: [Enter username                    ]
          ↑ Cursor position (blinking)
```

```swift
// Button with action and keyboard shortcut
Button("Submit", shortcut: "s") {
    // Handle action
}
```

**Output:**
```
[ Submit (s) ]  // Highlighted when focused
```

```swift
// Selector with ForEach
let options = ["Option 1", "Option 2", "Option 3"]
Selector($selectedOption) {
    ForEach(options, id: \.self) { option in
        Text(option)
    }
}
```

**Output:**
```
> Option 1    // Selected with arrow indicator
  Option 2
  Option 3
```

### Control Flow

- **ForEach** - Iterate over collections with stable IDs

```swift
// ForEach with Identifiable items
struct Todo: Identifiable {
    let id = UUID()
    let title: String
}

let todos = [
    Todo(title: "Write documentation"),
    Todo(title: "Fix bugs")
]

VStack {
    ForEach(todos) { todo in
        Text("• \(todo.title)")
    }
}
```

**Output:**
```
• Write documentation
• Fix bugs
```

```swift
// ForEach with ranges
VStack {
    ForEach(0..<3) { index in
        Text("Item \(index + 1)")
    }
}
```

**Output:**
```
Item 1
Item 2
Item 3
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
```

**Output:**
```
Styled  // Cyan text on blue background, bold, italic, underlined, dimmed
```

```swift
// Animation effects (via ViewModifiers)
Text("Loading...")
    .shimmer(duration: 2.0)
```

**Output:** (animated)
```
Loading...  // Shimmering effect moving across the text
```

```swift
Text("Alert!")
    .blink(duration: 0.5)
```

**Output:** (animated)
```
Alert!  // Text appears and disappears every 0.5 seconds
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
VStack {
    Text("✓ Success").foreground(.semantic(.success))
    Text("✗ Error").foreground(.semantic(.error))
    Text("⚠ Warning").foreground(.semantic(.warning))
}
```

**Output:**
```
✓ Success   // Green text
✗ Error     // Red text
⚠ Warning   // Yellow text
```

### Conditional Rendering

```swift
// Conditional rendering example
VStack {
    if isLoggedIn {
        Text("Welcome back!")
    } else {
        Text("Please log in")
    }
    
    Divider()
    
    switch status {
    case .loading:
        Spinner("Loading...")
    case .success(let message):
        Text(message).foreground(.green)
    case .error(let error):
        Text("Error: \(error)").foreground(.red)
    }
}
```

**Output (when logged in and loading):**
```
Welcome back!
────────────────
⠋ Loading...
```

**Output (when not logged in with error):**
```
Please log in
────────────────
Error: Connection failed  // In red color
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