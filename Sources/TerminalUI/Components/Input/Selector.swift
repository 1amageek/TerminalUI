import Foundation

/// A simplified selector component for terminal UI
/// This is a basic implementation that can be enhanced later
public struct Selector<Content: ConsoleView>: ConsoleView {
    private let content: Content
    private let title: String?
    
    public init(
        title: String? = nil,
        @ConsoleBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    public var body: Never {
        fatalError("Selector is a primitive view")
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var properties = PropertyContainer()
        
        if let title = title {
            properties = properties.with(.label, value: title)
        }
        
        // Generate child nodes
        let childNode = content._makeNode(context: &context)
        
        return Node(
            address: context.makeAddress(for: "selector"),
            logicalID: nil,
            kind: .selector,
            children: [childNode],
            properties: properties,
            parentAddress: context.currentParent
        )
    }
}