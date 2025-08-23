import Foundation

public struct Grid: ConsoleView {
    private let columns: [Column]
    private let rows: [[String]]
    private let showHeaders: Bool
    private let showBorders: Bool
    private let alignment: TextAlignment
    
    public struct Column: Sendable {
        public let title: String
        public let width: GridWidth
        public let alignment: TextAlignment
        
        public init(title: String, width: GridWidth = .auto, alignment: TextAlignment = .leading) {
            self.title = title
            self.width = width
            self.alignment = alignment
        }
    }
    
    public enum GridWidth: Sendable {
        case auto
        case fixed(Int)
        case percentage(Double)
    }
    
    public init(
        columns: [Column],
        rows: [[String]],
        showHeaders: Bool = true,
        showBorders: Bool = true,
        alignment: TextAlignment = .leading
    ) {
        self.columns = columns
        self.rows = rows
        self.showHeaders = showHeaders
        self.showBorders = showBorders
        self.alignment = alignment
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {

        let columnWidths = calculateColumnWidths(context: context)
        

        let gridColumns = columns.enumerated().map { (index, col) in
            GridColumn(
                title: col.title,
                width: columnWidths[index],
                alignment: convertTextAlignmentToTableAlignment(col.alignment)
            )
        }
        
        let gridData = GridData(columns: gridColumns, rows: rows)
        
        let properties = PropertyContainer()
            .with(.gridData, value: gridData)
            .with(.showHeader, value: showHeaders)
            .with(.showBorder, value: showBorders)
        
        return Node(id: context.makeNodeID(), kind: .grid, properties: properties)
    }
    
    private func calculateColumnWidths(context: RenderContext) -> [Int] {
        var widths = Array(repeating: 0, count: columns.count)
        let availableWidth = context.terminalWidth - (showBorders ? (columns.count + 1) : 0)
        
        for (index, column) in columns.enumerated() {
            switch column.width {
            case .auto:

                var maxWidth = column.title.count
                for row in rows {
                    if index < row.count {
                        maxWidth = max(maxWidth, row[index].count)
                    }
                }
                widths[index] = min(maxWidth, availableWidth / columns.count)
                
            case .fixed(let width):
                widths[index] = width
                
            case .percentage(let percent):
                widths[index] = Int(Double(availableWidth) * percent / 100.0)
            }
        }
        
        return widths
    }
    
    private func convertTextAlignmentToTableAlignment(_ alignment: TextAlignment) -> TableAlignment {
        switch alignment {
        case .leading, .left: return .left
        case .center: return .center
        case .trailing, .right: return .right
        case .justified: return .left
        }
    }
    
    private func alignmentString(_ alignment: TextAlignment) -> String {
        switch alignment {
        case .leading: return "leading"
        case .center: return "center"
        case .trailing: return "trailing"
        case .left: return "left"
        case .right: return "right"
        case .justified: return "justified"
        }
    }
    
    private func alignmentString(_ alignment: TableAlignment) -> String {
        switch alignment {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }
}

public struct GridRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    private func alignmentString(_ alignment: TableAlignment) -> String {
        switch alignment {
        case .left: return "left"
        case .center: return "center"
        case .right: return "right"
        }
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        guard let gridData: GridData = node.properties[.gridData] else {
            return commands
        }
        
        let showHeaders: Bool = node.properties[.showHeader, default: true]
        let showBorders: Bool = node.properties[.showBorder, default: true]
        
        let columns = gridData.columns
        let rows = gridData.rows
        
        var currentY = position.y
        

        if showBorders {
            drawHorizontalBorder(at: Point(x: position.x, y: currentY), columns: columns, isTop: true, commands: &commands)
            currentY += 1
        }
        

        if showHeaders {
            drawRow(columns.map { $0.title }, columns: columns, at: Point(x: position.x, y: currentY), isBold: true, commands: &commands)
            currentY += 1
            
            if showBorders {
                drawHorizontalBorder(at: Point(x: position.x, y: currentY), columns: columns, isMiddle: true, commands: &commands)
                currentY += 1
            }
        }
        

        for (index, row) in rows.enumerated() {
            drawRow(row, columns: columns, at: Point(x: position.x, y: currentY), commands: &commands)
            currentY += 1
            
            if showBorders && index < rows.count - 1 {
                drawHorizontalBorder(at: Point(x: position.x, y: currentY), columns: columns, isDivider: true, commands: &commands)
                currentY += 1
            }
        }
        

        if showBorders {
            drawHorizontalBorder(at: Point(x: position.x, y: currentY), columns: columns, isBottom: true, commands: &commands)
        }
        
        return commands
    }
    
    private func drawRow(_ row: [String], columns: [GridColumn], at position: Point, isBold: Bool = false, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if isBold {
            commands.append(.setStyle(.bold))
        }
        
        var x = position.x
        
        for (index, column) in columns.enumerated() {
            let width = column.width ?? 10
            let alignment = alignmentString(column.alignment)
            let content = index < row.count ? row[index] : ""
            

            commands.append(.write("│ "))
            x += 2
            

            let paddedContent = alignText(content, width: width - 1, alignment: alignment)
            commands.append(.write(paddedContent))
            x += width - 1
        }
        

        commands.append(.write("│"))
        
        if isBold {
            commands.append(.reset)
        }
    }
    
    private func drawHorizontalBorder(at position: Point, columns: [GridColumn], isTop: Bool = false, isMiddle: Bool = false, isDivider: Bool = false, isBottom: Bool = false, commands: inout [RenderCommand]) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        let (left, middle, right, horizontal) = if isTop {
            ("┌", "┬", "┐", "─")
        } else if isMiddle {
            ("├", "┼", "┤", "─")
        } else if isDivider {
            ("├", "┼", "┤", "─")
        } else if isBottom {
            ("└", "┴", "┘", "─")
        } else {
            ("├", "┼", "┤", "─")
        }
        
        commands.append(.write(left))
        
        for (index, column) in columns.enumerated() {
            let width = column.width ?? 10
            commands.append(.write(String(repeating: horizontal, count: width)))
            
            if index < columns.count - 1 {
                commands.append(.write(middle))
            }
        }
        
        commands.append(.write(right))
    }
    
    private func alignText(_ text: String, width: Int, alignment: String) -> String {
        let truncated = text.count > width ? String(text.prefix(width - 1)) + "…" : text
        let padding = width - truncated.count
        
        switch alignment {
        case "center":
            let leftPad = padding / 2
            let rightPad = padding - leftPad
            return String(repeating: " ", count: leftPad) + truncated + String(repeating: " ", count: rightPad)
        case "trailing":
            return String(repeating: " ", count: padding) + truncated
        default:
            return truncated + String(repeating: " ", count: padding)
        }
    }
}