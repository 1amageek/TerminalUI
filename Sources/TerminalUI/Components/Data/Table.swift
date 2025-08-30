import Foundation

public struct Table: ConsoleView {
    private let columns: [TableColumn]
    private let rows: [TableRow]
    private let showHeader: Bool
    private let showBorder: Bool
    private let borderStyle: BorderStyle
    private let striped: Bool
    private let compact: Bool
    
    public init(
        columns: [TableColumn],
        rows: [TableRow],
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
        

        let properties = PropertyContainer()
            .with(.columns, value: columns)
            .with(.rows, value: rows)
            .with(.columnWidths, value: widths)
            .with(.showHeader, value: showHeader)
            .with(.showBorder, value: showBorder)
            .with(.borderStyle, value: borderStyleString(borderStyle))
            .with(.striped, value: striped)
            .with(.compact, value: compact)
        
        return Node(
            address: context.makeAddress(for: "table"),
            logicalID: nil,
            kind: .table,
            properties: properties,
            parentAddress: context.currentParent
        )
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
        var flexColumns: [TableColumn] = []
        
        for column in columns {
            switch column.width {
            case .fixed(let w):
                widths[column.id] = w
                fixedWidth += w
            case .percentage(let pct):
                // pct: 0-100 (unified with Grid)
                let borders = showBorder ? (columns.count + 1) : 0
                let avail = totalWidth - borders
                let w = Int((pct / 100.0) * Double(avail))
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
    
    private func calculateMinWidth(for column: TableColumn) -> Int {
        var minWidth = column.title.terminalWidth
        

        for row in rows {
            if let cell = row.cells[column.id] {
                minWidth = max(minWidth, cell.terminalWidth)
            }
        }
        

        return minWidth + (compact ? 1 : 2)
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