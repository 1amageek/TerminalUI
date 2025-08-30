import Foundation

/// A flexible or fixed space that expands along the axis of its parent
public struct Spacer: ConsoleView {
    private let minLength: Int?
    
    public init(minLength: Int? = nil) {
        self.minLength = minLength
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var properties = PropertyContainer()
        
        if let minLength = minLength {
            properties = properties.with(.minLength, value: minLength)
        }
        
        // Mark as flexible if no minimum length specified
        properties = properties.with(.flexible, value: minLength == nil)
        
        return Node(
            address: context.makeAddress(for: "spacer"),
            logicalID: nil,
            kind: .spacer,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
    
    public var body: Never {
        fatalError("Spacer is a primitive view")
    }
}

// Property keys for Spacer
public extension PropertyContainer.Key {
    static var minLength: PropertyContainer.Key<Int> { PropertyContainer.Key("minLength") }
    static var flexible: PropertyContainer.Key<Bool> { PropertyContainer.Key("flexible") }
}