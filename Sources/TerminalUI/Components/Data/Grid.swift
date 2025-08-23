import Foundation

public struct Grid: ConsoleView {
    private let columns: [GridColumn]
    private let rows: [[String]]
    private let showHeaders: Bool
    private let showBorders: Bool
    private let alignment: TextAlignment
    
    public init(
        columns: [GridColumn],
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
                width: .fixed(columnWidths[index]),
                alignment: col.alignment
            )
        }
        
        let gridData = GridData(columns: gridColumns, rows: rows)
        
        let properties = PropertyContainer()
            .with(.gridData, value: gridData)
            .with(.showHeader, value: showHeaders)
            .with(.showBorder, value: showBorders)
        
        return Node(
            address: context.makeAddress(for: "grid"),
            logicalID: nil,
            kind: .grid,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
    
    private func calculateColumnWidths(context: RenderContext) -> [Int] {
        var widths = Array(repeating: 0, count: columns.count)
        let availableWidth = context.terminalWidth - (showBorders ? (columns.count + 1) : 0)
        
        for (index, column) in columns.enumerated() {
            switch column.width {
            case .auto:

                var maxWidth = column.title.terminalWidth
                for row in rows {
                    if index < row.count {
                        maxWidth = max(maxWidth, row[index].terminalWidth)
                    }
                }
                widths[index] = min(maxWidth, availableWidth / columns.count)
                
            case .fixed(let width):
                widths[index] = width
                
            case .percentage(let percent):
                widths[index] = Int(Double(availableWidth) * percent / 100.0)
                
            case .min, .max, .range:
                widths[index] = availableWidth / columns.count
            }
        }
        
        return widths
    }
    
    public var body: Never {
        fatalError("Grid is a primitive view")
    }
}