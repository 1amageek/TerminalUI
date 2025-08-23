import Foundation

public struct TableColumnDefinition: Sendable {
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
    
    public enum ColumnWidth: Sendable {
        case fixed(Int)
        case percentage(Double)
        case auto
        case min(Int)
        case max(Int)
        case range(min: Int, max: Int)
    }
    
    public enum TextAlignment: Sendable {
        case left
        case center
        case right
    }
}

public struct TableRowData: Sendable {
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
    
    public enum RowStyle: Sendable {
        case normal
        case highlighted
        case muted
        case success
        case warning
        case error
    }
}

public struct Table: ConsoleView {
    private let columns: [TableColumnDefinition]
    private let rows: [TableRowData]
    private let showHeader: Bool
    private let showBorder: Bool
    private let borderStyle: BorderStyle
    private let striped: Bool
    private let compact: Bool
    
    public init(
        columns: [TableColumnDefinition],
        rows: [TableRowData],
        showHeader: Bool = true,
        showBorder: Bool = true,
        borderStyle: BorderStyle = .single,
        striped: Bool = false,
        compact: Bool = false
    ) {
        self.columns = columns
        self.rows = rows
        self.showHeader = showHeader
        self.showBorder = showBorder
        self.borderStyle = borderStyle
        self.striped = striped
        self.compact = compact
    }
    
    public enum BorderStyle: Sendable {
        case none
        case single
        case double
        case rounded
        case ascii
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {

        let widths = calculateColumnWidths(context: context)
        

        let tableColumns = columns.map { col in
            TableColumn(
                title: col.title,
                key: col.id,
                width: widths[col.id],
                alignment: TableAlignment(rawValue: alignmentString(col.alignment)) ?? .left
            )
        }
        
        let tableRows = rows.map { row in
            TableRow(
                cells: row.cells,
                style: TableRowStyle(rawValue: styleString(row.style)) ?? .normal
            )
        }
        
        let properties = PropertyContainer()
            .with(.columns, value: tableColumns)
            .with(.rows, value: tableRows)
            .with(.showHeader, value: showHeader)
            .with(.showBorder, value: showBorder)
            .with(.striped, value: striped)
            .with(.compact, value: compact)
        
        return Node(id: context.makeNodeID(), kind: .table, properties: properties)
    }
    
    public var body: Never {
        fatalError("Table is a leaf component")
    }
    

    
    private func calculateColumnWidths(context: RenderContext) -> [String: Int] {
        let totalWidth = context.terminalWidth
        var widths: [String: Int] = [:]
        

        for column in columns {
            let minWidth = calculateMinWidth(for: column)
            widths[column.id] = minWidth
        }
        

        var fixedWidth = 0
        var flexColumns: [TableColumnDefinition] = []
        
        for column in columns {
            switch column.width {
            case .fixed(let w):
                widths[column.id] = w
                fixedWidth += w
            case .percentage(let pct):
                let w = Int(Double(totalWidth) * pct)
                widths[column.id] = w
                fixedWidth += w
            case .min(let minWidth):
                widths[column.id] = Swift.max(minWidth, widths[column.id] ?? 0)
                fixedWidth += widths[column.id]!
            case .max(let maxWidth):
                widths[column.id] = Swift.min(maxWidth, widths[column.id] ?? 0)
                fixedWidth += widths[column.id]!
            case .range(let minWidth, let maxWidth):
                let current = widths[column.id] ?? 0
                widths[column.id] = Swift.min(maxWidth, Swift.max(minWidth, current))
                fixedWidth += widths[column.id]!
            case .auto:
                flexColumns.append(column)
            }
        }
        

        if !flexColumns.isEmpty {
            let borders = showBorder ? (columns.count + 1) : 0
            let availableWidth = totalWidth - fixedWidth - borders
            let flexWidth = max(5, availableWidth / flexColumns.count)
            
            for column in flexColumns {
                widths[column.id] = flexWidth
            }
        }
        
        return widths
    }
    
    private func calculateMinWidth(for column: TableColumnDefinition) -> Int {
        var minWidth = column.title.terminalWidth
        

        for row in rows {
            if let cell = row.cells[column.id] {
                minWidth = max(minWidth, cell.terminalWidth)
            }
        }
        

        return minWidth + (compact ? 1 : 2)
    }
    

    
    private func alignmentString(_ alignment: TableColumnDefinition.TextAlignment) -> String {
        switch alignment {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }
    
    private func styleString(_ style: TableRowData.RowStyle?) -> String {
        switch style {
        case .normal, nil: return "normal"
        case .highlighted: return "highlighted"
        case .muted: return "muted"
        case .success: return "success"
        case .warning: return "warning"
        case .error: return "error"
        }
    }
    
    private func borderStyleString(_ style: BorderStyle) -> String {
        switch style {
        case .none: return "none"
        case .single: return "single"
        case .double: return "double"
        case .rounded: return "rounded"
        case .ascii: return "ascii"
        }
    }
}

public struct TableRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    

    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        let showBorder = node.properties[.showBorder] ?? true
        let borderStyle = "single"
        let showHeader = node.properties[.showHeader] ?? true
        let striped = node.properties[.striped] ?? false
        

        let borders = getBorderChars(style: borderStyle)
        
        var currentY = position.y
        

        if showBorder {
            drawTopBorder(at: Point(x: position.x, y: currentY), width: width, borders: borders, commands: &commands)
            currentY += 1
        }
        

        if showHeader {
            drawHeader(at: Point(x: position.x, y: currentY), node: node, borders: borders, commands: &commands)
            currentY += 1
            
            if showBorder {
                drawMiddleBorder(at: Point(x: position.x, y: currentY), width: width, borders: borders, commands: &commands)
                currentY += 1
            }
        }
        

        if let rows: [TableRow] = node.properties[.rows] {
            for (index, row) in rows.enumerated() {
                let isStriped = striped && index % 2 == 1
                drawRowTypeSafe(at: Point(x: position.x, y: currentY), row: row, node: node, borders: borders, isStriped: isStriped, commands: &commands)
                currentY += 1
            }
        }
        

        if showBorder {
            drawBottomBorder(at: Point(x: position.x, y: currentY), width: width, borders: borders, commands: &commands)
        }
        
        return commands
    }
    
    private func getBorderChars(style: String) -> TableBorders {
        switch style {
        case "double":
            return TableBorders.double
        case "rounded":
            return TableBorders.rounded
        case "ascii":
            return TableBorders.ascii
        default:
            return TableBorders.single
        }
    }
    
    private func drawTopBorder(at position: Point, width: Int, borders: TableBorders, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        commands.append(.write(borders.topLeft))
        commands.append(.write(String(repeating: borders.horizontal, count: width - 2)))
        commands.append(.write(borders.topRight))
    }
    
    private func drawMiddleBorder(at position: Point, width: Int, borders: TableBorders, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        commands.append(.write(borders.middleLeft))
        commands.append(.write(String(repeating: borders.horizontal, count: width - 2)))
        commands.append(.write(borders.middleRight))
    }
    
    private func drawBottomBorder(at position: Point, width: Int, borders: TableBorders, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        commands.append(.write(borders.bottomLeft))
        commands.append(.write(String(repeating: borders.horizontal, count: width - 2)))
        commands.append(.write(borders.bottomRight))
    }
    
    private func drawHeader(at position: Point, node: Node, borders: TableBorders, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if borders.vertical != "" {
            commands.append(.write(borders.vertical))
        }
        
        if let columns: [TableColumn] = node.properties[.columns] {
            for column in columns {
                commands.append(.setStyle(.bold))
                let padded = padText(column.title, width: column.width ?? 10, alignment: .center)
                commands.append(.write(padded))
                commands.append(.reset)
                
                if borders.vertical != "" {
                    commands.append(.write(borders.vertical))
                }
            }
        }
    }
    
    private func drawRowTypeSafe(at position: Point, row: TableRow, node: Node, borders: TableBorders, isStriped: Bool, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if isStriped {
            commands.append(.setBackground(.semantic(.muted)))
        }
        
        if borders.vertical != "" {
            commands.append(.write(borders.vertical))
        }
        
        if let columns: [TableColumn] = node.properties[.columns] {
            for column in columns {
                let text = row.cells[column.key] ?? ""
                let padded = padText(text, width: column.width ?? 10, alignment: tableAlignmentToLocal(column.alignment))
                commands.append(.write(padded))
                
                if borders.vertical != "" {
                    commands.append(.write(borders.vertical))
                }
            }
        }
        
        if isStriped {
            commands.append(.reset)
        }
    }
    private func padText(_ text: String, width: Int, alignment: TableColumnDefinition.TextAlignment) -> String {
        let textWidth = text.terminalWidth
        guard textWidth < width else {
            return text.truncated(to: width)
        }
        
        let padding = width - textWidth
        
        switch alignment {
        case .left:
            return text + String(repeating: " ", count: padding)
        case .right:
            return String(repeating: " ", count: padding) + text
        case .center:
            let leftPad = padding / 2
            let rightPad = padding - leftPad
            return String(repeating: " ", count: leftPad) + text + String(repeating: " ", count: rightPad)
        }
    }
    
    private func tableAlignmentToLocal(_ alignment: TableAlignment) -> TableColumnDefinition.TextAlignment {
        switch alignment {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
    
    private func parseAlignment(_ str: String) -> TableColumnDefinition.TextAlignment {
        switch str {
        case "center": return .center
        case "right": return .right
        default: return .left
        }
    }
}

struct TableBorders {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let middleLeft: String
    let middleRight: String
    let horizontal: String
    let vertical: String
    let cross: String
    
    static let single = TableBorders(
        topLeft: "┌", topRight: "┐",
        bottomLeft: "└", bottomRight: "┘",
        middleLeft: "├", middleRight: "┤",
        horizontal: "─", vertical: "│", cross: "┼"
    )
    
    static let double = TableBorders(
        topLeft: "╔", topRight: "╗",
        bottomLeft: "╚", bottomRight: "╝",
        middleLeft: "╠", middleRight: "╣",
        horizontal: "═", vertical: "║", cross: "╬"
    )
    
    static let rounded = TableBorders(
        topLeft: "╭", topRight: "╮",
        bottomLeft: "╰", bottomRight: "╯",
        middleLeft: "├", middleRight: "┤",
        horizontal: "─", vertical: "│", cross: "┼"
    )
    
    static let ascii = TableBorders(
        topLeft: "+", topRight: "+",
        bottomLeft: "+", bottomRight: "+",
        middleLeft: "+", middleRight: "+",
        horizontal: "-", vertical: "|", cross: "+"
    )
}