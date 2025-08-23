import Foundation

// MARK: - ConsoleView Protocol

public protocol ConsoleView: Sendable {
    associatedtype Body
    
    /// Generate a node representation of this view
    func _makeNode(context: inout RenderContext) -> Node
    
    /// The body of this view
    @ConsoleBuilder
    var body: Body { get }
}

public extension ConsoleView where Body: ConsoleView {
    func _makeNode(context: inout RenderContext) -> Node {
        body._makeNode(context: &context)
    }
}

// MARK: - Logical ID Support

/// Internal view wrapper that applies a logical ID to its content
internal struct _LogicalIDView<Content: ConsoleView>: ConsoleView {
    let content: Content
    let logicalID: LogicalID
    
    func _makeNode(context: inout RenderContext) -> Node {
        var node = content._makeNode(context: &context)
        
        // Apply the logical ID to the node
        if node.logicalID != nil {
            #if DEBUG
            print("Warning: Overriding existing logical ID '\(node.logicalID!)' with '\(logicalID)' at \(node.address)")
            #endif
        }
        
        node = node.with(logicalID: logicalID)
        return node
    }
    
    var body: Never {
        fatalError("_LogicalIDView is a primitive view")
    }
}

// MARK: - ConsoleView ID Extensions

public extension ConsoleView {
    /// Assign a logical ID to this view for stable identity during diffing
    /// - Parameter logical: The logical ID to assign (must be unique among siblings)
    func id<S: CustomStringConvertible>(_ logical: S) -> some ConsoleView {
        _LogicalIDView(content: self, logicalID: LogicalID(String(describing: logical)))
    }
    
    /// Assign a logical ID to this view for stable identity during diffing
    /// - Parameter logical: The logical ID to assign (must be unique among siblings)
    func id(_ logical: LogicalID) -> some ConsoleView {
        _LogicalIDView(content: self, logicalID: logical)
    }
    
    /// Assign a logical ID to this view using a string literal
    /// - Parameter logical: The logical ID string (must be unique among siblings)
    func id(_ logical: String) -> some ConsoleView {
        _LogicalIDView(content: self, logicalID: LogicalID(logical))
    }
    
    /// Assign a logical ID to this view using an integer
    /// - Parameter logical: The logical ID integer (must be unique among siblings)
    func id(_ logical: Int) -> some ConsoleView {
        _LogicalIDView(content: self, logicalID: LogicalID(String(logical)))
    }
    
    /// Assign a logical ID to this view using a UUID
    /// - Parameter logical: The logical ID UUID (must be unique among siblings)
    func id(_ logical: UUID) -> some ConsoleView {
        _LogicalIDView(content: self, logicalID: LogicalID(logical.uuidString))
    }
}