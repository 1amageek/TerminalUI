import Foundation

public struct ListItem: Sendable, Identifiable {
    public let id: String
    public let content: String
    public let icon: String?
    public let badge: String?
    public let style: ItemStyle
    public let metadata: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        content: String,
        icon: String? = nil,
        badge: String? = nil,
        style: ItemStyle = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.content = content
        self.icon = icon
        self.badge = badge
        self.style = style
        self.metadata = metadata
    }
    
    public enum ItemStyle: Sendable {
        case normal
        case selected
        case disabled
        case success
        case warning
        case error
        case muted
    }
}

public enum ListStyle: Sendable {
    case plain
    case bulleted
    case numbered
    case checkbox
    case definition
    
    var bulletSymbol: String {
        switch self {
        case .plain:
            return ""
        case .bulleted:
            return "•"
        case .numbered:
            return "1."
        case .checkbox:
            return "☐"
        case .definition:
            return "▸"
        }
    }
}

public struct List: ConsoleView {
    private let items: [ListItem]
    private let style: ListStyle
    private let selectedIndices: Set<Int>
    private let selectedIDs: Set<String>
    private let compact: Bool
    private let showIcons: Bool
    private let showBadges: Bool
    private let indentLevel: Int
    
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
        self.style = style
        self.selectedIndices = []
        self.selectedIDs = selectedIDs
        self.compact = compact
        self.showIcons = showIcons
        self.showBadges = showBadges
        self.indentLevel = indentLevel
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {

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
            .with(.indentWidth, value: indentLevel)
        
        return Node(
            address: context.makeAddress(for: "list"),
            logicalID: nil,
            kind: .list,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
    
    public var body: Never {
        fatalError("List is a leaf component")
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
        
        guard let items: [ListItemData] = node.properties[.listItems] else {
            return commands
        }
        
        var currentY = position.y
        let indent = String(repeating: "  ", count: indentLevel)
        
        for (index, item) in items.enumerated() {
            drawListItem(
                item: item,
                at: Point(x: position.x, y: currentY),
                indent: indent,
                showIcons: showIcons,
                showBadges: showBadges,
                width: width,
                commands: &commands
            )
            
            currentY += 1
            

            if !compact && index < items.count - 1 {
                currentY += 1
            }
        }
        
        return commands
    }
    
    private func drawListItem(
        item: ListItemData,
        at position: Point,
        indent: String,
        showIcons: Bool,
        showBadges: Bool,
        width: Int,
        commands: inout [RenderCommand]
    ) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        

        commands.append(.write(indent))
        

        let content = item.content
        let icon = item.icon
        let badge = item.badge
        let bullet = item.bullet
        let styleStr = item.style
        let isSelected = item.isSelected
        

        applyItemStyle(styleStr, isSelected: isSelected, commands: &commands)
        

        if !bullet.isEmpty {
            commands.append(.write("\(bullet) "))
        }
        

        if showIcons && !icon.isEmpty {
            commands.append(.write("\(icon) "))
        }
        

        commands.append(.write(content))
        

        if showBadges && !badge.isEmpty {
            commands.append(.write(" "))
            commands.append(.setBackground(.semantic(.accent)))
            commands.append(.setForeground(.rgb(255, 255, 255)))
            commands.append(.write(" \(badge) "))
            commands.append(.reset)
            applyItemStyle(styleStr, isSelected: isSelected, commands: &commands)
        }
        

        commands.append(.reset)
    }
    
    private func applyItemStyle(_ style: String, isSelected: Bool, commands: inout [RenderCommand]) {
        if isSelected {
            commands.append(.setBackground(.semantic(.accent)))
            commands.append(.setForeground(.rgb(255, 255, 255)))
            return
        }
        
        switch style {
        case "disabled":
            commands.append(.setStyle(.dim))
        case "success":
            commands.append(.setForeground(.semantic(.success)))
        case "warning":
            commands.append(.setForeground(.semantic(.warning)))
        case "error":
            commands.append(.setForeground(.semantic(.error)))
        case "muted":
            commands.append(.setForeground(.semantic(.muted)))
        default:
            break
        }
    }
}

public extension List {

    static func bullets(_ items: [String]) -> List {
        List(
            items: items.map { ListItem(content: $0) },
            style: .bulleted
        )
    }
    

    static func numbered(_ items: [String]) -> List {
        List(
            items: items.map { ListItem(content: $0) },
            style: .numbered
        )
    }
    

    static func checklist(_ items: [(String, Bool)]) -> List {
        let listItems = items.map { ListItem(content: $0.0) }
        let selected = Set(items.enumerated().compactMap { $0.element.1 ? $0.offset : nil })
        
        return List(
            items: listItems,
            style: .checkbox,
            selectedIndices: selected
        )
    }
    

    static func definitions(_ items: [(term: String, definition: String)]) -> List {
        let listItems = items.map { item in
            ListItem(content: "\(item.term): \(item.definition)")
        }
        
        return List(
            items: listItems,
            style: .definition
        )
    }
}

public struct NestedList: ConsoleView {
    private let items: [NestedListItem]
    private let style: ListStyle
    
    public struct NestedListItem: Sendable {
        public let content: String
        public let children: [NestedListItem]
        public let icon: String?
        
        public init(content: String, children: [NestedListItem] = [], icon: String? = nil) {
            self.content = content
            self.children = children
            self.icon = icon
        }
    }
    
    public init(items: [NestedListItem], style: ListStyle = .bulleted) {
        self.items = items
        self.style = style
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        VStack {
            ForEach(flattenItems()) { item in
                List(
                    items: [ListItem(content: item.content, icon: item.icon)],
                    style: style,
                    indentLevel: item.level
                )
            }
        }.spacing(0)._makeNode(context: &context)
    }
    
    public var body: Never {
        fatalError("NestedList is expanded to List components")
    }
    
    private struct FlattenedItem: Identifiable {
        let id = UUID().uuidString
        let content: String
        let icon: String?
        let level: Int
    }
    
    private func flattenItems() -> [FlattenedItem] {
        var result: [FlattenedItem] = []
        
        func flatten(_ items: [NestedListItem], level: Int) {
            for item in items {
                result.append(FlattenedItem(
                    content: item.content,
                    icon: item.icon,
                    level: level
                ))
                flatten(item.children, level: level + 1)
            }
        }
        
        flatten(items, level: 0)
        return result
    }
}