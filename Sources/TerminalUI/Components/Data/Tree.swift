import Foundation

public struct TreeNode: Sendable {
    public let id: String
    public let label: String
    public let children: [TreeNode]
    public let icon: String?
    public let isExpanded: Bool
    public let metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        label: String,
        children: [TreeNode] = [],
        icon: String? = nil,
        isExpanded: Bool = true,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.label = label
        self.children = children
        self.icon = icon
        self.isExpanded = isExpanded
        self.metadata = metadata
    }
}

public struct Tree: ConsoleView {
    private let root: TreeNode
    private let showRoot: Bool
    private let showIcons: Bool
    private let showLines: Bool
    private let indentWidth: Int
    private let expandedNodes: Set<String>
    
    public init(
        root: TreeNode,
        showRoot: Bool = true,
        showIcons: Bool = true,
        showLines: Bool = true,
        indentWidth: Int = 2,
        expandedNodes: Set<String> = []
    ) {
        self.root = root
        self.showRoot = showRoot
        self.showIcons = showIcons
        self.showLines = showLines
        self.indentWidth = indentWidth
        self.expandedNodes = expandedNodes
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {

        let items = flattenTree(root, showRoot: showRoot)
        

        let treeItems = items.map { item in
            TreeItem(
                id: item.id,
                label: item.label,
                icon: item.icon,
                children: [],
                isExpanded: item.isExpanded,
                level: item.level,
                linePrefix: item.linePrefix
            )
        }
        
        let properties = PropertyContainer()
            .with(.items, value: treeItems)
            .with(.showIcons, value: showIcons)
            .with(.showLines, value: showLines)
            .with(.indentWidth, value: indentWidth)
        
        return Node(id: context.makeNodeID(), kind: .tree, properties: properties)
    }
    
    public var body: Never {
        fatalError("Tree is a leaf component")
    }
    

    
    private struct FlattenedItem {
        let id: String
        let label: String
        let level: Int
        let isExpanded: Bool
        let hasChildren: Bool
        let isLast: Bool
        let icon: String?
        let linePrefix: String
    }
    
    private func flattenTree(_ node: TreeNode, showRoot: Bool) -> [FlattenedItem] {
        var items: [FlattenedItem] = []
        
        if showRoot {
            flattenNode(node, level: 0, prefix: "", isLast: true, items: &items)
        } else {
            for (index, child) in node.children.enumerated() {
                let isLast = index == node.children.count - 1
                flattenNode(child, level: 0, prefix: "", isLast: isLast, items: &items)
            }
        }
        
        return items
    }
    
    private func flattenNode(
        _ node: TreeNode,
        level: Int,
        prefix: String,
        isLast: Bool,
        items: inout [FlattenedItem]
    ) {
        let isExpanded = expandedNodes.contains(node.id) || node.isExpanded
        
        items.append(FlattenedItem(
            id: node.id,
            label: node.label,
            level: level,
            isExpanded: isExpanded,
            hasChildren: !node.children.isEmpty,
            isLast: isLast,
            icon: node.icon,
            linePrefix: prefix
        ))
        
        if isExpanded && !node.children.isEmpty {
            let childPrefix = prefix + (isLast ? "  " : "│ ")
            
            for (index, child) in node.children.enumerated() {
                let childIsLast = index == node.children.count - 1
                flattenNode(
                    child,
                    level: level + 1,
                    prefix: childPrefix,
                    isLast: childIsLast,
                    items: &items
                )
            }
        }
    }
}

public struct TreeRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    

    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        let showIcons = node.properties[.showIcons] ?? true
        let showLines = node.properties[.showLines] ?? true
        let indentWidth = node.properties[.indentWidth] ?? 2
        
        guard let items: [TreeItem] = node.properties[.items] else {
            return commands
        }
        
        var currentY = position.y
        
        for item in items {
            drawTreeItem(
                item: item,
                at: Point(x: position.x, y: currentY),
                showIcons: showIcons,
                showLines: showLines,
                indentWidth: indentWidth,
                commands: &commands
            )
            currentY += 1
        }
        
        return commands
    }
    
    private func drawTreeItem(
        item: TreeItem,
        at position: Point,
        showIcons: Bool,
        showLines: Bool,
        indentWidth: Int,
        commands: inout [RenderCommand]
    ) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        let level = item.level
        let isExpanded = item.isExpanded
        let hasChildren = !item.children.isEmpty
        let isLast = true
        let label = item.label
        let icon = item.icon
        let linePrefix = item.linePrefix
        

        if showLines && level > 0 {
            commands.append(.setForeground(.semantic(.muted)))
            commands.append(.write(linePrefix))
            

            if isLast {
                commands.append(.write("└─"))
            } else {
                commands.append(.write("├─"))
            }
            commands.append(.reset)
        } else {

            let indent = String(repeating: " ", count: level * indentWidth)
            commands.append(.write(indent))
        }
        

        if hasChildren {
            if isExpanded {
                commands.append(.write("▼ "))
            } else {
                commands.append(.write("▶ "))
            }
        } else if showLines {
            commands.append(.write("  "))
        }
        

        if showIcons, let icon = icon, !icon.isEmpty {
            commands.append(.write("\(icon) "))
        }
        

        commands.append(.write(label))
    }
}

public struct TreeBuilder {

    public static func fromPaths(_ paths: [String]) -> TreeNode {
        var root = TreeNode(label: "/", icon: "📁")
        
        for path in paths {
            let components = path.split(separator: "/").map(String.init)
            addPath(components, to: &root)
        }
        
        return root
    }
    
    private static func addPath(_ components: [String], to node: inout TreeNode) {
        guard !components.isEmpty else { return }
        
        let first = components[0]
        let remaining = Array(components.dropFirst())
        

        if let existingIndex = node.children.firstIndex(where: { $0.label == first }) {
            var child = node.children[existingIndex]
            if !remaining.isEmpty {
                addPath(remaining, to: &child)
            }

            var newChildren = node.children
            newChildren[existingIndex] = child
            node = TreeNode(
                id: node.id,
                label: node.label,
                children: newChildren,
                icon: node.icon,
                isExpanded: node.isExpanded,
                metadata: node.metadata
            )
        } else {

            let isDirectory = !remaining.isEmpty
            let icon = isDirectory ? "📁" : "📄"
            var newChild = TreeNode(label: first, icon: icon)
            
            if !remaining.isEmpty {
                addPath(remaining, to: &newChild)
            }
            
            var newChildren = node.children
            newChildren.append(newChild)
            node = TreeNode(
                id: node.id,
                label: node.label,
                children: newChildren,
                icon: node.icon,
                isExpanded: node.isExpanded,
                metadata: node.metadata
            )
        }
    }
    

    public static func fromJSON(_ json: [String: Any]) -> TreeNode? {
        guard let label = json["label"] as? String else { return nil }
        
        let id = json["id"] as? String ?? UUID().uuidString
        let icon = json["icon"] as? String
        let isExpanded = json["expanded"] as? Bool ?? true
        let metadata = json["metadata"] as? [String: String] ?? [:]
        
        var children: [TreeNode] = []
        if let childrenJSON = json["children"] as? [[String: Any]] {
            children = childrenJSON.compactMap { fromJSON($0) }
        }
        
        return TreeNode(
            id: id,
            label: label,
            children: children,
            icon: icon,
            isExpanded: isExpanded,
            metadata: metadata
        )
    }
}