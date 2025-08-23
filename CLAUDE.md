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

# Generate Xcode project (if needed)
swift package generate-xcodeproj

# Clean build artifacts
swift package clean

# Update dependencies (when added)
swift package update
```

## Architecture

### Core Components

1. **ConsoleView Protocol & DSL**
   - Base protocol for all view components
   - ConsoleBuilder result builder for SwiftUI-like syntax
   - Node tree generation for rendering

2. **ConsoleSession & Console**
   - Session management tied to tracing spans (1:1 or 1:many)
   - Entry point via `Console.start(on: span)`
   - Methods: `render()`, `progress()`, `spinner()`, `log()`

3. **TerminalRuntime (Actor)**
   - Central actor managing differential rendering
   - Processes Node trees and generates RenderCommands
   - Manages multiple renderers (TTY, JSON, Tracing)

4. **Renderers**
   - ANSIRenderer: TTY output with ANSI escape codes
   - JSONRenderer: Structured output for IDEs/logging
   - TracingRenderer: Span event emission

### Implementation Priority

When implementing features, follow this order:
1. Core node system and render context
2. Runtime with diff engine and layout
3. Basic renderers (ANSI first)
4. Session management
5. Effects (spinner, progress, shimmer)
6. Components (text, layouts, data displays)
7. Tracing integration
8. Tests and documentation

## Key Technical Decisions

### Color Handling
- Automatic fallback: TrueColor → 256 colors → 16 colors
- Respect NO_COLOR environment variable
- Detect capabilities via COLORTERM, TERM env vars

### Performance Constraints
- Maximum 15 FPS for animations (default)
- Coalesce rapid updates to prevent flicker
- Memory budget: ~thousands of nodes per session

### Effects Implementation
- **Shimmer**: HSV phase shift per character
- **Blink**: Low frequency duty cycle (readability-first)
- **Pulse**: Size/brightness modulation
- **Spinners**: Pre-defined patterns (dots, line, arc, bounce, braille)

## Testing Strategy

1. **Golden Tests**: DSL → Node → RenderCommand → Expected ANSI
2. **Width Reflow**: Terminal resize handling
3. **Color Fallback**: Graceful degradation testing
4. **Effects**: FPS limits and stop conditions
5. **Headless Mode**: Event emission without TTY

## Dependency Management

The library must add swift-distributed-tracing as a dependency:
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.0.0")
]
```

## Session Options

Default values to implement:
- `collapseChildren: true` (fold child spans)
- `liveFPS: 15` (max frame rate)
- `headless: false` (TTY rendering enabled)
- `theme: .default` (color scheme)

## Tracing Event Schema

All UI operations emit events with name `"terminalui.render"` and attributes:
- `ui.op`: "node_start" | "node_update" | "node_end" | "frame"
- `ui.node_type`: Component type
- `ui.id` / `ui.parent_id`: Stable identifiers
- `ui.json`: Compressed payload (optional)
- `ui.version`: "1.0"
- `ui.color_mode`: "truecolor" | "256" | "16"

## SwiftAgent Integration

Create a separate target `TerminalUIAdapterSwiftAgent` (not in core) that provides:
- SpanModifier
- RenderModifier  
- StatusModifier
These allow SwiftAgent Steps to use TerminalUI without core dependency.