import Foundation

public struct HStack<Content: ConsoleView>: ConsoleView {
    private let content: Content
    private var spacing: Int = 0
    private var padding: Int = 0
    private var border: ANSIColor?
    private var rounded: Bool = false
    
    public init(@ConsoleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let id = context.makeNodeID(for: "hstack")
        
        var properties = PropertyContainer()
        
        if spacing > 0 {
            properties = properties.with(.spacing, value: spacing)
        }
        
        if padding > 0 {
            properties = properties.with(.padding, value: padding)
        }
        
        if let borderColor = border {
            properties = properties.with(.border, value: String(describing: borderColor))
            properties = properties.with(.rounded, value: rounded)
        }
        

        context.pushPath("hstack")
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
            kind: .hstack,
            children: children,
            properties: properties,
            parentID: context.currentParent
        )
    }
}

public extension HStack {
    func spacing(_ value: Int) -> Self {
        var copy = self
        copy.spacing = value
        return copy
    }
    
    func padding(_ value: Int) -> Self {
        var copy = self
        copy.padding = value
        return copy
    }
    
    func border(_ color: ANSIColor, rounded: Bool = false) -> Self {
        var copy = self
        copy.border = color
        copy.rounded = rounded
        return copy
    }
}