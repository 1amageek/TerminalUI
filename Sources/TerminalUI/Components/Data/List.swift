import Foundation

// MARK: - List Style

public enum ListStyle: Sendable, CaseIterable {
    case plain
    case bulleted
    case numbered
    case checkbox
    case definition
}

// MARK: - List Item

public struct ListItem: Sendable, Identifiable {
    public let id: String
    public let content: String
    public let icon: String?
    public let badge: String?
    public let style: ItemStyle
    
    public enum ItemStyle: Sendable, CaseIterable {
        case normal
        case selected
        case disabled
        case success
        case warning
        case error
        case muted
    }
    
    public init(
        id: String = UUID().uuidString,
        content: String,
        icon: String? = nil,
        badge: String? = nil,
        style: ItemStyle = .normal
    ) {
        self.id = id
        self.content = content
        self.icon = icon
        self.badge = badge
        self.style = style
    }
}

// MARK: - List Item Data (Internal)
// Using the ListItemData from DataTypes.swift

// MARK: - List Component

public struct List<Content: ConsoleView>: ConsoleView {
    private let content: Content?
    private let items: [ListItem]
    private let style: ListStyle
    private let selectedIndices: Set<Int>
    private let selectedIDs: Set<String>
    private let compact: Bool
    private let showIcons: Bool
    private let showBadges: Bool
    private let indentLevel: Int
    
    // Legacy initializer with ListItems
    public init(
        items: [ListItem],
        style: ListStyle = .bulleted,
        selectedIndices: Set<Int> = [],
        compact: Bool = false,
        showIcons: Bool = true,
        showBadges: Bool = true,
        indentLevel: Int = 0
    ) {
        self.items = items
        self.content = nil
        self.style = style
        self.selectedIndices = selectedIndices
        self.selectedIDs = []
        self.compact = compact
        self.showIcons = showIcons
        self.showBadges = showBadges
        self.indentLevel = indentLevel
    }
    
    public init(
        items: [ListItem],
        style: ListStyle = .bulleted,
        selectedIDs: Set<String>,
        compact: Bool = false,
        showIcons: Bool = true,
        showBadges: Bool = true,
        indentLevel: Int = 0
    ) {
        self.items = items
        self.content = nil
        self.style = style
        self.selectedIndices = []
        self.selectedIDs = selectedIDs
        self.compact = compact
        self.showIcons = showIcons
        self.showBadges = showBadges
        self.indentLevel = indentLevel
    }
    
    // New initializer with ConsoleBuilder for nested content
    public init(
        style: ListStyle = .bulleted,
        compact: Bool = false,
        showIcons: Bool = true,
        showBadges: Bool = true,
        @ConsoleBuilder content: () -> Content
    ) where Content: ConsoleView {
        self.content = content()
        self.items = []
        self.style = style
        self.selectedIndices = []
        self.selectedIDs = []
        self.compact = compact
        self.showIcons = showIcons
        self.showBadges = showBadges
        self.indentLevel = 0  // Will be set by context
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        // Check current list depth from context and increase it for nested lists
        let currentDepth = context.listDepth
        context.pushListDepth()
        defer { context.popListDepth() }
        
        if let content = content {
            // New style: render child content with increased indent
            var childContext = context
            let childNode = content._makeNode(context: &childContext)
            
            // Wrap in a list node with appropriate indent
            let properties = PropertyContainer()
                .with(.kind, value: styleString(style))
                .with(.compact, value: compact)
                .with(.showIcons, value: showIcons)
                .with(.showBadges, value: showBadges)
                .with(.indentWidth, value: currentDepth)
            
            return Node(
                address: context.makeAddress(for: "list"),
                logicalID: nil,
                kind: .list,
                children: [childNode],
                properties: properties,
                parentAddress: context.currentParent
            )
        } else {
            // Legacy style: render items directly
            let renderItems = items.enumerated().map { index, item in
                let isSelected = selectedIndices.contains(index) || selectedIDs.contains(item.id)
                return ListItemData(
                    id: item.id,
                    content: item.content,
                    icon: item.icon ?? "",
                    badge: item.badge ?? "",
                    style: styleString(item.style),
                    isSelected: isSelected,
                    bullet: getBullet(for: index, isSelected: isSelected)
                )
            }
            
            let properties = PropertyContainer()
                .with(.listItems, value: renderItems)
                .with(.kind, value: styleString(style))
                .with(.compact, value: compact)
                .with(.showIcons, value: showIcons)
                .with(.showBadges, value: showBadges)
                .with(.indentWidth, value: indentLevel + currentDepth)
            
            return Node(
                address: context.makeAddress(for: "list"),
                logicalID: nil,
                kind: .list,
                properties: properties,
                parentAddress: context.currentParent
            )
        }
    }
    
    public var body: Never {
        fatalError("List is a primitive view")
    }
    
    private func getBullet(for index: Int, isSelected: Bool) -> String {
        switch style {
        case .plain:
            return ""
        case .bulleted:
            return "•"
        case .numbered:
            return "\(index + 1)."
        case .checkbox:
            return isSelected ? "☑" : "☐"
        case .definition:
            return "▸"
        }
    }
    
    private func styleString(_ itemStyle: ListItem.ItemStyle) -> String {
        switch itemStyle {
        case .normal: return "normal"
        case .selected: return "selected"
        case .disabled: return "disabled"
        case .success: return "success"
        case .warning: return "warning"
        case .error: return "error"
        case .muted: return "muted"
        }
    }
    
    private func styleString(_ listStyle: ListStyle) -> String {
        switch listStyle {
        case .plain: return "plain"
        case .bulleted: return "bulleted"
        case .numbered: return "numbered"
        case .checkbox: return "checkbox"
        case .definition: return "definition"
        }
    }
}

// MARK: - List Renderer

public struct ListRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        let compact = node.properties[.compact] ?? false
        let showIcons = node.properties[.showIcons] ?? true
        let showBadges = node.properties[.showBadges] ?? true
        let indentLevel = node.properties[.indentWidth] ?? 0
        
        // If it has child nodes, render them with proper indentation
        if !node.children.isEmpty {
            let indent = String(repeating: "  ", count: indentLevel)
            var currentY = position.y
            
            for child in node.children {
                // Recursively render children
                let childCommands = renderChild(child, at: Point(x: position.x, y: currentY), width: width, indent: indent)
                commands.append(contentsOf: childCommands)
                currentY += calculateHeight(for: child)
            }
        } else if let items: [ListItemData] = node.properties[.listItems] {
            // Legacy rendering for items
            var currentY = position.y
            let indent = String(repeating: "  ", count: indentLevel)
            
            for (_, item) in items.enumerated() {
                drawListItem(
                    item: item,
                    at: Point(x: position.x, y: currentY),
                    width: width,
                    indent: indent,
                    showIcons: showIcons,
                    showBadges: showBadges,
                    commands: &commands
                )
                
                currentY += compact ? 1 : 2
            }
        }
        
        return commands
    }
    
    private func renderChild(_ node: Node, at position: Point, width: Int, indent: String) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        // Apply indentation and render based on node type
        switch node.kind {
        case .text:
            if let text = node.prop(.text, as: String.self) {
                commands.append(.moveCursor(row: position.y, column: position.x))
                commands.append(.write("\(indent)• \(text)"))
            }
        case .list:
            // Nested list - will have its own indentation
            let renderer = ListRenderer(theme: theme)
            let nestedCommands = renderer.render(node, at: position, width: width)
            commands.append(contentsOf: nestedCommands)
        default:
            // Other content types
            break
        }
        
        return commands
    }
    
    private func calculateHeight(for node: Node) -> Int {
        switch node.kind {
        case .text:
            return 1
        case .list:
            // Calculate based on children
            var height = 0
            for child in node.children {
                height += calculateHeight(for: child)
            }
            if height == 0 && node.properties[.listItems] != nil {
                // Legacy items
                if let items: [ListItemData] = node.properties[.listItems] {
                    let compact = node.properties[.compact] ?? false
                    height = items.count * (compact ? 1 : 2)
                }
            }
            return height
        default:
            return 1
        }
    }
    
    private func drawListItem(
        item: ListItemData,
        at position: Point,
        width: Int,
        indent: String,
        showIcons: Bool,
        showBadges: Bool,
        commands: inout [RenderCommand]
    ) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        var line = indent
        
        if !item.bullet.isEmpty {
            line += "\(item.bullet) "
        }
        
        if showIcons && !item.icon.isEmpty {
            line += "\(item.icon) "
        }
        
        line += item.content
        
        if showBadges && !item.badge.isEmpty {
            line += " [\(item.badge)]"
        }
        
        // Apply style
        switch item.style {
        case "selected":
            commands.append(.setStyle(.bold))
        case "disabled", "muted":
            commands.append(.setStyle(.dim))
        case "success":
            commands.append(.setForeground(.semantic(.success)))
        case "warning":
            commands.append(.setForeground(.semantic(.warning)))
        case "error":
            commands.append(.setForeground(.semantic(.error)))
        default:
            break
        }
        
        commands.append(.write(line))
        commands.append(.reset)
    }
}

// MARK: - List Modifiers

public extension List {
    func spacing(_ value: Int) -> some ConsoleView {
        // This would be implemented via a wrapper view
        self
    }
    
    func selected(indices: Set<Int>) -> List {
        List(
            items: items,
            style: style,
            selectedIndices: indices,
            compact: compact,
            showIcons: showIcons,
            showBadges: showBadges,
            indentLevel: indentLevel
        )
    }
    
    func selected(ids: Set<String>) -> List {
        List(
            items: items,
            style: style,
            selectedIDs: ids,
            compact: compact,
            showIcons: showIcons,
            showBadges: showBadges,
            indentLevel: indentLevel
        )
    }
    
    func compact(_ value: Bool = true) -> List {
        List(
            items: items,
            style: style,
            selectedIndices: selectedIndices,
            compact: value,
            showIcons: showIcons,
            showBadges: showBadges,
            indentLevel: indentLevel
        )
    }
}

// MARK: - Property Keys
// Using the property keys from PropertyContainer.swift