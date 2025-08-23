import Foundation

public struct EmptyView: ConsoleView {
    public init() {}
    
    public func _makeNode(context: inout RenderContext) -> Node {
        Node(
            address: context.makeAddress(for: "empty"),
            logicalID: nil,
            kind: .empty,
            children: [],
            properties: PropertyContainer(),
            parentAddress: context.currentParent
        )
    }
    
    public var body: Never {
        fatalError("EmptyView is a primitive view")
    }
}