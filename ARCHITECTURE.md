# TerminalUI Architecture

## Overview

TerminalUI is a Swift library for creating rich terminal interfaces with a declarative DSL, built on top of swift-distributed-tracing. It provides a SwiftUI-like API for building terminal UIs with support for colors, animations, and interactive components.

## Core Concepts

### 1. ID/Address Separation

TerminalUI uses a dual identification system:

- **Address**: Hierarchical position identifier for rendering and routing (e.g., "vstack.text.0")
- **LogicalID**: Stable identity for diffing and state management (must be unique among siblings)

```swift
public struct Node {
    public let address: Address        // Position in tree
    public let logicalID: LogicalID?  // Stable identity
    // ...
}
```

This separation enables:
- Efficient reconciliation through stable IDs
- Proper handling of reordering and moves
- Clear distinction between structural position and logical identity

### 2. ConsoleView Protocol

The fundamental building block for all UI components:

```swift
public protocol ConsoleView: Sendable {
    associatedtype Body
    func _makeNode(context: inout RenderContext) -> Node
    var body: Body { get }
}
```

Components can be:
- **Leaf views**: Implement `_makeNode` directly (e.g., Text, Badge)
- **Container views**: Compose other views via `body` property (e.g., VStack, HStack)

### 3. Reconciliation

The `Reconciler` performs efficient tree diffing with prioritized matching:

1. **Priority 1**: Match by logical IDs if present
2. **Priority 2**: Match by position and kind for nodes without IDs

```swift
let result = reconciler.reconcile(oldTree: previousTree, newTree: currentTree)
// result contains: insertions, updates, deletions, moves
```

This enables incremental updates instead of full re-renders.

## Component Hierarchy

```
ConsoleView (Protocol)
├── Primitive Views (Body == Never)
│   ├── Text
│   ├── Badge
│   ├── Note
│   ├── Code
│   ├── Divider
│   ├── ProgressView
│   ├── Spinner
│   ├── Meter
│   └── TextField
├── Container Views
│   ├── VStack
│   ├── HStack
│   ├── Group
│   ├── Panel
│   └── ContainerView (Protocol)
├── Data Views
│   ├── ForEach (requires stable IDs)
│   ├── List
│   ├── Table
│   ├── Tree
│   ├── Grid
│   └── KeyValue
└── Effect Views
    ├── BlinkEffect
    ├── ShimmerEffect
    └── PulseEffect
```

## Data Flow

1. **View Declaration**: User declares views using DSL
2. **Node Generation**: Views generate Node tree via `_makeNode`
3. **Reconciliation**: Reconciler diffs old and new trees
4. **Layout**: LayoutEngine calculates positions and sizes
5. **Painting**: PaintEngine generates render commands
6. **Rendering**: Renderers output to terminal/JSON/tracing

```
User Code → ConsoleView → Node Tree → Reconciler → Layout → Paint → Render
```

## ForEach and Stable IDs

ForEach now **requires** stable IDs for all elements:

```swift
// ✅ Good: Explicit IDs
ForEach(items, id: \.id) { item in
    Text(item.name)
}

// ✅ Good: Identifiable conformance
ForEach(identifiableItems) { item in
    Text(item.name)
}

// ❌ Removed: Index-based IDs (unstable)
// ❌ Removed: Hash-based IDs (unstable)
```

This ensures:
- Consistent behavior across data updates
- Proper animation and state preservation
- Predictable reconciliation

## Session Management

Sessions connect terminal UI to tracing spans:

```swift
let session = Console.start(on: span)
await session.render {
    VStack {
        Text("Hello").id("greeting")
        ForEach(items, id: \.id) { item in
            Text(item.name)
        }
    }
}
```

## Runtime Architecture

The `TerminalRuntime` actor coordinates:

- **Reconciler**: Tree diffing and change detection
- **LayoutEngine**: Size and position calculation
- **PaintEngine**: Command generation
- **Renderers**: Output to various targets
  - ANSIRenderer: TTY with ANSI codes
  - JSONRenderer: Structured output
  - TracingRenderer: Span events

## Best Practices

### 1. Always Use Stable IDs in Dynamic Content

```swift
// Good
ForEach(users, id: \.userID) { user in
    UserRow(user: user)
}

// Bad - will cause reconciliation issues
ForEach(Array(users.enumerated()), id: \.offset) { index, user in
    UserRow(user: user)
}
```

### 2. Assign Logical IDs to Stateful Components

```swift
VStack {
    TextField("Name", text: $name)
        .id("name-field")  // Preserves focus across updates
    
    ProgressView(value: progress)
        .id("main-progress")  // Maintains animation state
}
```

### 3. Use ContainerView Protocol for Custom Containers

```swift
struct Card<Content: ConsoleView>: ContainerView {
    let content: Content
    let containerKind = NodeKind.panel
    
    func extraProperties() -> PropertyContainer {
        PropertyContainer()
            .with(.border, value: BorderStyle.rounded)
    }
}
```

## Performance Considerations

1. **Reconciliation Complexity**: O(n) for nodes with logical IDs, O(n²) worst case for positional matching
2. **Memory Usage**: Node trees are lightweight value types
3. **Rendering**: Incremental updates minimize terminal redraws
4. **Animations**: Capped at 15 FPS by default to prevent flicker

## Type Safety

The ID/Address system is fully type-safe:

- `Address`: Opaque type for positions
- `LogicalID`: Opaque type for identities  
- `NodeID`: Deprecated type alias for migration

This prevents mixing of concepts and ensures correct usage.

## Migration Guide

### From NodeID to Address/LogicalID

Before:
```swift
let nodeID = context.makeNodeID()
Node(id: nodeID, ...)
```

After:
```swift
let address = context.makeAddress()
Node(address: address, logicalID: nil, ...)
```

### Adding Stable IDs

Before:
```swift
ForEach(items) { item in
    Text(item.description)
}
```

After:
```swift
ForEach(items, id: \.someStableProperty) { item in
    Text(item.description)
}
```

## Testing

The architecture supports comprehensive testing:

1. **Unit Tests**: Test individual components and reconciliation
2. **Golden Tests**: DSL → Node → Commands → Expected output
3. **Performance Tests**: Large tree reconciliation benchmarks

## Future Enhancements

- [ ] Partial re-rendering within nodes
- [ ] Virtual scrolling for large lists
- [ ] Dirty region tracking
- [ ] Animation curve support
- [ ] Layout caching
- [ ] Parallel reconciliation