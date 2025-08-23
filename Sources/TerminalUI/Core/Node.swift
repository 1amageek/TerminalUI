import Foundation

// MARK: - Address (Position Information)

/// Represents the hierarchical position of a node in the tree for rendering and routing
public struct Address: Hashable, Sendable, CustomStringConvertible {
    public let raw: String
    
    public init(_ raw: String) {
        self.raw = raw
    }
    
    public var description: String {
        raw
    }
    
    /// Components of the address path
    public var components: [String] {
        raw.split(separator: ".").map(String.init)
    }
    
    /// Depth in the tree hierarchy
    public var depth: Int {
        components.count
    }
    
    /// Parent address (if not root)
    public var parent: Address? {
        guard components.count > 1 else { return nil }
        let parentComponents = components.dropLast()
        return Address(parentComponents.joined(separator: "."))
    }
}

// MARK: - LogicalID (State Identity)

/// Represents the logical identity of a node for diffing and state management
public struct LogicalID: Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let raw: String
    
    public init(_ raw: String) {
        self.raw = raw
    }
    
    public init(stringLiteral value: String) {
        self.raw = value
    }
    
    public var description: String {
        raw
    }
}

// MARK: - NodeKind

public enum NodeKind: String, Sendable, CaseIterable {
    // Layout
    case empty
    case vstack
    case hstack
    case group
    case panel
    case divider
    case grid
    case keyvalue
    
    // Text
    case text
    case code
    case badge
    case tag
    case note
    case list
    
    // Data
    case table
    case tree
    
    // Progress
    case progress
    case spinner
    case meter
    case gauge
    
    // Input
    case textfield
    case textarea
    
    // Visual
    case image
    case sparkline
    
    // Effects
    case shimmer
    case blink
    case pulse
}

// MARK: - Node

public struct Node: Sendable {
    /// The hierarchical address of this node (for rendering/routing)
    public let address: Address
    
    /// Optional logical ID for stable identity across updates (for diffing/state)
    public var logicalID: LogicalID?
    
    /// The type of UI element this node represents
    public let kind: NodeKind
    
    /// Child nodes
    public var children: [Node]
    
    /// Properties specific to this node type
    public var properties: PropertyContainer
    
    /// Parent's address (set by container)
    public internal(set) var parentAddress: Address?
    
    /// Frame number for animations
    public internal(set) var frame: Int
    
    public init(
        address: Address,
        logicalID: LogicalID? = nil,
        kind: NodeKind,
        children: [Node] = [],
        properties: PropertyContainer = PropertyContainer(),
        parentAddress: Address? = nil,
        frame: Int = 0
    ) {
        self.address = address
        self.logicalID = logicalID
        self.kind = kind
        self.children = children
        self.properties = properties
        self.parentAddress = parentAddress
        self.frame = frame
        
        #if DEBUG
        validateUniqueLogicalIDs()
        #endif
    }
    
    // MARK: - Debug Support
    
    #if DEBUG
    /// Validates that all child nodes have unique logical IDs (if present)
    public func validateUniqueLogicalIDs() {
        let childIDs = children.compactMap(\.logicalID)
        let grouped = Dictionary(grouping: childIDs, by: { $0 })
        
        for (id, occurrences) in grouped where occurrences.count > 1 {
            preconditionFailure(
                "Duplicate logical ID '\(id)' found \(occurrences.count) times in children of node at \(address). " +
                "Each child node must have a unique logical ID within its parent."
            )
        }
    }
    #endif
}

// MARK: - Node Extensions

public extension Node {
    /// Get a property value by key
    func prop<Value: Sendable>(_ key: PropertyContainer.Key<Value>, as type: Value.Type) -> Value? {
        properties[key]
    }
    
    /// Check if a property exists
    func hasProp<Value: Sendable>(_ key: PropertyContainer.Key<Value>) -> Bool {
        properties.contains(key)
    }
    
    /// Create a new node with updated children
    func with(children: [Node]) -> Node {
        Node(
            address: address,
            logicalID: logicalID,
            kind: kind,
            children: children,
            properties: properties,
            parentAddress: parentAddress,
            frame: frame
        )
    }
    
    /// Create a new node with updated properties
    func with(properties: PropertyContainer) -> Node {
        Node(
            address: address,
            logicalID: logicalID,
            kind: kind,
            children: children,
            properties: properties,
            parentAddress: parentAddress,
            frame: frame
        )
    }
    
    /// Create a new node with a logical ID
    func with(logicalID: LogicalID?) -> Node {
        Node(
            address: address,
            logicalID: logicalID,
            kind: kind,
            children: children,
            properties: properties,
            parentAddress: parentAddress,
            frame: frame
        )
    }
}

// MARK: - Test Support

#if DEBUG
public extension Node {
    /// Find a child node by its logical ID
    func child(withLogicalID id: String) -> Node? {
        children.first { $0.logicalID?.raw == id }
    }
    
    /// Find a child node by its logical ID
    func child(withLogicalID id: LogicalID) -> Node? {
        children.first { $0.logicalID == id }
    }
    
    /// Get text content from properties (for testing)
    var textContent: String? {
        properties[.text]
    }
    
    /// Debug description showing tree structure
    var debugTree: String {
        func buildTree(_ node: Node, indent: String = "") -> String {
            var result = "\(indent)\(node.kind)"
            if let id = node.logicalID {
                result += " [id: \(id)]"
            }
            result += " @ \(node.address)\n"
            
            for child in node.children {
                result += buildTree(child, indent: indent + "  ")
            }
            return result
        }
        return buildTree(self)
    }
}
#endif

// MARK: - Migration Support (Temporary)
