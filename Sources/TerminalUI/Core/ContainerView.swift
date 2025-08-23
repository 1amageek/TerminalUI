import Foundation

/// Protocol for container-type console views that encapsulate other views
/// This protocol provides common functionality for layout containers like VStack, HStack, Panel, and Group
public protocol ContainerView: ConsoleView where Body == Never {
    associatedtype Content: ConsoleView
    
    /// The content to be contained within this container
    var content: Content { get }
    
    /// The kind of node this container represents
    var containerKind: NodeKind { get }
    
    /// Additional properties specific to this container type
    func extraProperties() -> PropertyContainer
}

public extension ContainerView {
    /// Default implementation for making nodes from container views
    func _makeNode(context: inout RenderContext) -> Node {
        let address = context.makeAddress(for: String(describing: containerKind))
        
        // Get container-specific properties
        let properties = extraProperties()
        
        // Generate child nodes with proper context management
        context.pushPath(String(describing: containerKind))
        context.pushParent(address)
        let childNode = content._makeNode(context: &context)
        context.popParent()
        context.popPath()
        
        // Flatten group nodes if necessary
        let children: [Node]
        if childNode.kind == .group {
            children = childNode.children
        } else {
            children = [childNode]
        }
        
        // Update all children to have this container as their parent
        let childrenWithParent = children.map { child in
            var updatedChild = child
            updatedChild.parentAddress = address
            return updatedChild
        }
        
        return Node(
            address: address,
            logicalID: nil, // Containers typically don't have logical IDs
            kind: containerKind,
            children: childrenWithParent,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
    
    var body: Never {
        fatalError("ContainerView is a primitive view")
    }
}