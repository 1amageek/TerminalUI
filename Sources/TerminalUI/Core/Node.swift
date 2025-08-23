import Foundation

public struct NodeID: Hashable, Sendable, CustomStringConvertible {
    internal let value: String
    
    internal init(_ value: String) {
        self.value = value
    }
    
    public var description: String {
        value
    }
}

public enum NodeKind: String, Sendable, CaseIterable {

    case empty
    case vstack
    case hstack
    case group
    case panel
    case divider
    case grid
    case keyvalue
    

    case text
    case code
    case badge
    case tag
    case note
    case list
    

    case table
    case tree
    

    case progress
    case spinner
    case meter
    case gauge
    

    case textfield
    case textarea
    

    case image
    case sparkline
    

    case shimmer
    case blink
    case pulse
}

public struct Node: Sendable {

    public let id: NodeID
    

    public let kind: NodeKind
    

    public var children: [Node]
    

    public var properties: PropertyContainer
    
    

    public internal(set) var parentID: NodeID?
    

    public internal(set) var frame: Int
    
    public init(
        id: NodeID,
        kind: NodeKind,
        children: [Node] = [],
        properties: PropertyContainer = PropertyContainer(),
        parentID: NodeID? = nil,
        frame: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.children = children
        self.properties = properties
        self.parentID = parentID
        self.frame = frame
    }
    
}

public extension Node {
    func prop<Value: Sendable>(_ key: PropertyContainer.Key<Value>, as type: Value.Type) -> Value? {
        return properties[key]
    }
    
    func hasProp<Value: Sendable>(_ key: PropertyContainer.Key<Value>) -> Bool {
        return properties.contains(key)
    }
}

public extension Node {

    func with(children: [Node]) -> Node {
        Node(
            id: id,
            kind: kind,
            children: children,
            properties: properties,
            parentID: parentID,
            frame: frame
        )
    }
    

    func with(properties: PropertyContainer) -> Node {
        Node(
            id: id,
            kind: kind,
            children: children,
            properties: properties,
            parentID: parentID,
            frame: frame
        )
    }
}