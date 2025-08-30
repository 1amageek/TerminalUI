import Foundation

public enum ColumnWidth: Sendable, Hashable {
    case fixed(Int)
    case percentage(Double)
    case auto
    case min(Int)
    case max(Int)
    case range(min: Int, max: Int)
}

public struct TableColumn: Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let width: ColumnWidth
    public let alignment: TextAlignment
    
    public init(
        id: String,
        title: String,
        width: ColumnWidth = .auto,
        alignment: TextAlignment = .left
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.alignment = alignment
    }
}

public struct TableRow: Sendable, Hashable, Identifiable {
    public let id: String
    public let cells: [String: String]
    public let style: RowStyle?
    
    public init(
        id: String = UUID().uuidString,
        cells: [String: String],
        style: RowStyle? = nil
    ) {
        self.id = id
        self.cells = cells
        self.style = style
    }
    
    public enum RowStyle: String, Sendable, CaseIterable {
        case normal
        case highlighted
        case muted
        case success
        case warning
        case error
    }
}


public struct TreeItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let label: String
    public let icon: String?
    public let children: [TreeItem]
    public let hasChildren: Bool
    public let isExpanded: Bool
    public let level: Int
    public let linePrefix: String
    public let isLast: Bool
    
    public init(
        id: String,
        label: String,
        icon: String? = nil,
        children: [TreeItem] = [],
        hasChildren: Bool? = nil,
        isExpanded: Bool = false,
        level: Int = 0,
        linePrefix: String = "",
        isLast: Bool = false
    ) {
        self.id = id
        self.label = label
        self.icon = icon
        self.children = children
        // If hasChildren is not explicitly set, derive from children
        self.hasChildren = hasChildren ?? !children.isEmpty
        self.isExpanded = isExpanded
        self.level = level
        self.linePrefix = linePrefix
        self.isLast = isLast
    }
}


public struct ListItemData: Sendable, Hashable {
    public let id: String
    public let content: String
    public let icon: String
    public let badge: String
    public let style: String
    public let isSelected: Bool
    public let bullet: String
    
    public init(
        id: String,
        content: String,
        icon: String = "",
        badge: String = "",
        style: String = "normal",
        isSelected: Bool = false,
        bullet: String = ""
    ) {
        self.id = id
        self.content = content
        self.icon = icon
        self.badge = badge
        self.style = style
        self.isSelected = isSelected
        self.bullet = bullet
    }
}


