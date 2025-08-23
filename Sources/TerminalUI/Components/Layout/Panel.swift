import Foundation

public struct Panel<Content: ConsoleView>: ConsoleView {
    private let title: String?
    private let content: Content
    private var borderColor: ANSIColor = .semantic(.muted)
    private var rounded: Bool = false
    
    public init(title: String? = nil, @ConsoleBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let id = context.makeNodeID(for: "panel")
        
        var properties = PropertyContainer()
            .with(.border, value: String(describing: borderColor))
            .with(.rounded, value: rounded)
        
        if let title = title {
            properties = properties.with(.label, value: title)
        }
        

        context.pushPath("panel")
        context.pushParent(id)
        let childNode = content._makeNode(context: &context)
        context.popParent()
        context.popPath()
        

        let children: [Node]
        if childNode.kind == .group {
            children = childNode.children
        } else {
            children = [childNode]
        }
        
        return Node(
            id: id,
            kind: .panel,
            children: children,
            properties: properties,
            parentID: context.currentParent
        )
    }
}

public extension Panel {
    func borderColor(_ color: ANSIColor) -> Self {
        var copy = self
        copy.borderColor = color
        return copy
    }
    
    func rounded(_ value: Bool = true) -> Self {
        var copy = self
        copy.rounded = value
        return copy
    }
}