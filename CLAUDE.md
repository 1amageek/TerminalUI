# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TerminalUI is a Swift library for creating rich terminal interfaces with a SwiftUI-like declarative DSL. It provides components for text, layout, data display, progress indicators, and input handling, all rendered to the terminal with ANSI escape sequences. The library includes optional distributed tracing support via swift-distributed-tracing for observability.

## Key Design Principles

1. **Declarative DSL**: SwiftUI-like syntax for building terminal UIs
2. **Immutable Value Types**: All views are immutable and optimized for differential rendering
3. **Non-blocking**: All operations are async and non-blocking with actor-based runtime
4. **ID/Address Separation**: Logical IDs for stable identity in diffing, Addresses for hierarchical position
5. **Tracing Integration**: Optional observability through swift-distributed-tracing (ConsoleSession)
6. **Thread Safety**: Sendable conformance and actor isolation for safe concurrent use

## Build and Development Commands

```bash
# Build the library
swift build

# Run tests
swift test

# Run tests with verbose output
swift test --verbose

# Run a specific test
swift test --filter TerminalUITests.YourTestName

# Clean build artifacts
swift package clean

# Update dependencies (when added)
swift package update
```

## Architecture

### Core Components

1. **Node System**
   - `Address`: Hierarchical position identifier (e.g., "vstack.text.0")
   - `LogicalID`: Stable identity for diffing (unique among siblings)
   - `Node`: Immutable render tree nodes with properties
   - `PropertyContainer`: Type-safe property storage with `Key<T>` pattern

2. **ConsoleView Protocol & DSL**
   - Base protocol for all view components
   - `ConsoleBuilder` result builder for SwiftUI-like syntax
   - `body: Never` for primitive views, composed views use `body: some ConsoleView`
   - ID modifiers: `.id(_)` for assigning logical IDs

3. **RenderContext**
   - Maintains rendering state during node generation
   - Tracks path hierarchy for address generation
   - Tracks list depth for nested list indentation
   - Validates unique logical IDs in DEBUG builds

4. **Reconciler**
   - Efficient tree diffing algorithm
   - Prioritizes logical ID matching over positional matching
   - Generates minimal update operations

5. **TerminalRuntime (Actor)**
   - Central actor managing differential rendering
   - Processes Node trees and generates RenderCommands
   - Manages animation tasks by Address
   - Coordinates multiple renderers

6. **Renderers**
   - ANSIRenderer: TTY output with ANSI escape codes
   - Component-specific renderers (ListRenderer, TreeRenderer, etc.)

### Component Structure

**Layout Components (7)**
- `VStack`, `HStack`: Container views implementing `ContainerView` protocol
- `Spacer`: Flexible space that expands
- `Divider`: Horizontal line separator
- `Panel`: Box with optional border and title
- `Group`: Logical grouping without visual representation
- `EmptyView`: View that renders nothing

**Text Components (2)**
- `Text`: Basic text with style modifiers (foreground, background, bold, italic, underline, dim)
- `List`: Display items in various list styles (plain, bulleted, numbered, checkbox, definition)

**Data Components (2)**
- `Table`: Tabular data with columns and rows
- `Tree`: Hierarchical tree structure display

**Progress Components (2)**
- `ProgressView`: Determinate/indeterminate progress bars
- `Spinner`: Animated loading indicators with customizable frames

**Input Components (3)**
- `TextField`: Text input field with validation support
- `Button`: Interactive button with keyboard shortcuts
- `Selector`: Selection UI for multiple options

**Control Flow**
- `ForEach`: Iterate over collections with stable IDs via `id:` parameter or `Identifiable` conformance

### ForEach Requirements

ForEach requires stable IDs for all elements:
- Use `ForEach(items)` for `Identifiable` types
- Use `ForEach(items, id: \.property)` with explicit key path
- Use `ForEach(0..<5)` for ranges (Int as ID)
- No fallback to indices or hashes

### Property System

Properties use type-safe keys with computed properties:
```swift
extension PropertyContainer.Key {
    static var text: PropertyContainer.Key<String> { PropertyContainer.Key("text") }
    static var foreground: PropertyContainer.Key<String> { PropertyContainer.Key("foreground") }
    // etc.
}
```

Access via: `node.prop(.text, as: String.self)` or `node.properties[.text]`

## Testing Strategy

1. **Unit Tests**: Component behavior and node generation
2. **Reconciler Tests**: Tree diffing correctness
3. **Render Tests**: Command generation validation
4. **Integration Tests**: End-to-end rendering
5. **Performance Tests**: Large tree handling

## Performance Constraints

- Maximum 15 FPS for animations (configurable)
- Coalesce rapid updates to prevent flicker
- Memory budget: ~thousands of nodes per session
- Duplicate LogicalID validation in DEBUG only

## Color Handling

- Automatic fallback: TrueColor → 256 colors → 16 colors
- Respect NO_COLOR environment variable
- Detect capabilities via COLORTERM, TERM env vars
- Theme system for semantic colors

## NodeKind Enum

The complete list of supported node types (14 total):
```swift
public enum NodeKind: String, Sendable, CaseIterable {
    // Layout (7)
    case empty, vstack, hstack, group, panel, divider, spacer
    
    // Text (2)
    case text, list
    
    // Data (2)
    case table, tree
    
    // Progress (2)
    case progress, spinner
    
    // Input (3)
    case textfield, button, selector
}
```

## View Modifiers and Effects

**Style Modifiers** (Text)
- `.foreground(_:)`: Text color
- `.background(_:)`: Background color
- `.bold()`, `.italic()`, `.underline()`, `.dim()`: Text styles

**Effects** (via ViewModifiers, not NodeKind)
- `.blink()`: Blinking effect
- `.shimmer()`: Shimmer animation
- `.pulse()`: Pulsing animation

## Live Rendering

For dynamic updates without full screen refresh:
```swift
let renderer = LiveRenderer()
await renderer.render(view)

// Or use LiveSession for multiple elements
let session = LiveSession()
await session.update("element-id", at: Point(x: 0, y: 5), with: view)
```