# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TerminalUI is a Swift library for creating rich terminal interfaces with declarative DSL, built on top of swift-distributed-tracing. It provides colored text, progress bars, loading spinners, shimmer effects, and other visual elements that can be attached to tracing spans as fragment views.

## Key Design Principles

1. **Independent Library**: TerminalUI depends ONLY on swift-distributed-tracing, not SwiftAgent
2. **Declarative DSL**: SwiftUI-like lightweight DSL for building terminal UIs
3. **Immutable Value Types**: All views are immutable and optimized for differential rendering
4. **Non-blocking**: All operations are async and non-blocking with actor-based runtime
5. **Tracing Integration**: All rendering emits structured events to spans for observability
6. **ID/Address Separation**: Logical IDs for stable identity in diffing, Addresses for hierarchical position

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
   - JSONRenderer: Structured output for IDEs/logging
   - TracingRenderer: Span event emission

### Component Structure

**Layout Components**
- `VStack`, `HStack`, `ZStack`: Container views implementing `ContainerView` protocol
- `Spacer`, `Divider`: Layout primitives
- `Panel`, `Group`: Organizational containers

**Data Components**
- `ForEach`: Requires stable IDs via `id:` parameter or `Identifiable` conformance
- `List`, `Table`: Collection displays
- `KeyValue`: Key-value pair display

**Text Components**
- `Text`: Basic text with style modifiers
- `Badge`, `Note`: Semantic text displays
- `Code`: Syntax-highlighted code blocks

**Progress Components**
- `ProgressView`: Determinate/indeterminate progress
- `Spinner`: Animated loading indicators
- `Meter`: Visual progress meters

### ForEach Requirements

ForEach requires stable IDs for all elements:
- Use `ForEach(items)` for `Identifiable` types
- Use `ForEach(items, id: \.property)` with explicit key path
- Use `ForEach(0..<5)` for ranges (Int as ID)
- No fallback to indices or hashes

### Property System

Properties use type-safe keys:
```swift
extension PropertyContainer.Key {
    static let text = Key<String>("text")
    static let foreground = Key<String>("foreground")
    // etc.
}
```

Access via: `node.prop(.text, as: String.self)`

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

## Tracing Event Schema

All UI operations emit events with name `"terminalui.render"` and attributes:
- `ui.op`: Operation type
- `ui.node_type`: Component type
- `ui.address`: Node address
- `ui.logical_id`: Stable identifier (if present)
- `ui.version`: Schema version
- `ui.color_mode`: Color capability

## SwiftAgent Integration

Create a separate target `TerminalUIAdapterSwiftAgent` (not in core) that provides:
- SpanModifier
- RenderModifier  
- StatusModifier

These allow SwiftAgent Steps to use TerminalUI without core dependency.