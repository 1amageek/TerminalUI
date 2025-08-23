import Foundation

public struct DiffEngine {
    
    public init() {}
    

    public func diff(from oldTree: Node, to newTree: Node) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        

        diffNodes(old: oldTree, new: newTree, commands: &commands)
        
        return commands
    }
    

    public func renderTree(_ tree: Node) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        renderNode(tree, commands: &commands)
        return commands
    }
    

    private func diffNodes(old: Node, new: Node, commands: inout [RenderCommand]) {

        if old.kind != new.kind {

            commands.append(.end(old.id))

            commands.append(.begin(new.id, new.kind, parent: new.parentID))

            for child in new.children {
                renderNode(child, commands: &commands)
            }
            return
        }
        

        let oldText: String? = old.properties[.text]
        let newText: String? = new.properties[.text]
        
        if oldText != newText {
            if let text = newText {
                commands.append(.setText(new.id, text))
            }
        }
        

        if old.frame != new.frame {
            let payload = FramePayload(
                frame: new.frame,
                progress: Double(new.frame) / 100.0
            )
            commands.append(.frame(new.id, payload))
        }
        

        diffChildren(oldChildren: old.children, newChildren: new.children, parentID: new.id, commands: &commands)
    }
    

    private func diffChildren(oldChildren: [Node], newChildren: [Node], parentID: NodeID, commands: inout [RenderCommand]) {

        var oldMap: [NodeID: Node] = [:]
        for child in oldChildren {
            oldMap[child.id] = child
        }
        
        var newMap: [NodeID: Node] = [:]
        for child in newChildren {
            newMap[child.id] = child
        }
        

        for oldChild in oldChildren {
            if newMap[oldChild.id] == nil {
                commands.append(.end(oldChild.id))
            }
        }
        

        for newChild in newChildren {
            if let oldChild = oldMap[newChild.id] {

                diffNodes(old: oldChild, new: newChild, commands: &commands)
            } else {

                renderNode(newChild, commands: &commands)
            }
        }
    }
    

    private func renderNode(_ node: Node, commands: inout [RenderCommand]) {

        commands.append(.begin(node.id, node.kind, parent: node.parentID))
        

        if let text: String = node.properties[.text] {
            commands.append(.setText(node.id, text))
        }
        

        for child in node.children {
            renderNode(child, commands: &commands)
        }
    }
}

extension Node {

    func isStructurallyEqual(to other: Node) -> Bool {
        return id == other.id &&
               kind == other.kind &&
               properties.debugDescription == other.properties.debugDescription &&
               children.count == other.children.count &&
               zip(children, other.children).allSatisfy { $0.isStructurallyEqual(to: $1) }
    }
}