import Foundation

public struct PaintEngine {
    private let theme: Theme
    private let capabilities: Capabilities
    
    public init(theme: Theme = .default, capabilities: Capabilities = .default) {
        self.theme = theme
        self.capabilities = capabilities
    }
    

    public func paint(_ node: Node) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        paintNode(node, at: Point(x: 0, y: 0), commands: &commands)
        return commands
    }
    

    private func paintNode(_ node: Node, at position: Point, commands: inout [RenderCommand]) {
        let x = node.properties[.x] ?? position.x
        let y = node.properties[.y] ?? position.y
        let width = node.prop(.width, as: Int.self) ?? 0
        let height = node.prop(.height, as: Int.self) ?? 0
        
        switch node.kind {
        case .text:
            paintText(node, at: Point(x: x, y: y), commands: &commands)
            
        case .vstack:
            paintVStack(node, at: Point(x: x, y: y), width: width, height: height, commands: &commands)
            
        case .hstack:
            paintHStack(node, at: Point(x: x, y: y), width: width, height: height, commands: &commands)
            
        case .panel:
            paintPanel(node, at: Point(x: x, y: y), width: width, height: height, commands: &commands)
            
        case .divider:
            paintDivider(node, at: Point(x: x, y: y), width: width, commands: &commands)
            
        case .progress:
            paintProgress(node, at: Point(x: x, y: y), width: width, commands: &commands)
            
        case .badge:
            paintBadge(node, at: Point(x: x, y: y), commands: &commands)
            
        case .note:
            paintNote(node, at: Point(x: x, y: y), width: width, commands: &commands)
            
        default:

            for child in node.children {
                paintNode(child, at: Point(x: x, y: y), commands: &commands)
            }
        }
    }
    

    private func paintText(_ node: Node, at position: Point, commands: inout [RenderCommand]) {
        let text = node.prop(.text, as: String.self) ?? ""
        

        commands.append(.moveCursor(row: position.y, column: position.x))
        

        if let fg = node.prop(.foreground, as: String.self) {
            if let color = parseColor(fg) {
                commands.append(.setForeground(theme.resolve(color)))
            }
        }
        
        if let bg = node.prop(.background, as: String.self) {
            if let color = parseColor(bg) {
                commands.append(.setBackground(theme.resolve(color)))
            }
        }
        
        var style = TextStyle.none
        if node.prop(.bold, as: Bool.self) == true { style.insert(.bold) }
        if node.prop(.italic, as: Bool.self) == true { style.insert(.italic) }
        if node.prop(.underline, as: Bool.self) == true { style.insert(.underline) }
        if node.prop(.dim, as: Bool.self) == true { style.insert(.dim) }
        
        if style != .none {
            commands.append(.setStyle(style))
        }
        

        commands.append(.write(text))
        

        if style != .none || node.hasProp(.foreground) || node.hasProp(.background) {
            commands.append(.reset)
        }
    }
    

    private func paintVStack(_ node: Node, at position: Point, width: Int, height: Int, commands: inout [RenderCommand]) {
        let spacing = node.prop(.spacing, as: Int.self) ?? 0
        let padding = node.prop(.padding, as: Int.self) ?? 0
        
        var currentY = position.y + padding
        
        for child in node.children {
            let childX = position.x + padding
            paintNode(child, at: Point(x: childX, y: currentY), commands: &commands)
            

            let childHeight = child.prop(.height, as: Int.self) ?? 1
            currentY += childHeight + spacing
        }
    }
    

    private func paintHStack(_ node: Node, at position: Point, width: Int, height: Int, commands: inout [RenderCommand]) {
        let spacing = node.prop(.spacing, as: Int.self) ?? 0
        let padding = node.prop(.padding, as: Int.self) ?? 0
        
        var currentX = position.x + padding
        
        for child in node.children {
            paintNode(child, at: Point(x: currentX, y: position.y + padding), commands: &commands)
            

            let childWidth = child.prop(.width, as: Int.self) ?? 0
            currentX += childWidth + spacing
        }
    }
    

    private func paintPanel(_ node: Node, at position: Point, width: Int, height: Int, commands: inout [RenderCommand]) {
        let title = node.prop(.label, as: String.self)
        let borderColor = node.prop(.border, as: String.self)
        let rounded = node.prop(.rounded, as: Bool.self) ?? false
        

        if borderColor != nil {
            drawBorder(
                at: position,
                width: width,
                height: height,
                title: title,
                rounded: rounded,
                commands: &commands
            )
        }
        

        let innerX = borderColor != nil ? position.x + 1 : position.x
        let innerY = borderColor != nil ? position.y + 1 : position.y
        
        for child in node.children {
            paintNode(child, at: Point(x: innerX, y: innerY), commands: &commands)
        }
    }
    

    private func paintDivider(_ node: Node, at position: Point, width: Int, commands: inout [RenderCommand]) {
        let character = node.prop(.text, as: String.self) ?? "─"
        let dividerLine = String(repeating: character, count: width)
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if let fg = node.prop(.foreground, as: String.self),
           let color = parseColor(fg) {
            commands.append(.setForeground(theme.resolve(color)))
        }
        
        commands.append(.write(dividerLine))
        commands.append(.reset)
    }
    

    private func paintProgress(_ node: Node, at position: Point, width: Int, commands: inout [RenderCommand]) {
        let value = node.prop(.value, as: Double.self) ?? 0
        let total = node.prop(.total, as: Double.self) ?? 1
        let label = node.prop(.label, as: String.self)
        let indeterminate = node.prop(.indeterminate, as: Bool.self) ?? false
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if let label = label {
            commands.append(.write("\(label): "))
        }
        
        if indeterminate {

            commands.append(.write("⠋ Working..."))
        } else {

            let progress = min(1.0, max(0.0, value / total))
            let filled = Int(Double(width - 2) * progress)
            let empty = width - 2 - filled
            
            commands.append(.write("["))
            if filled > 0 {
                commands.append(.setForeground(.semantic(.accent)))
                commands.append(.write(String(repeating: "█", count: filled)))
            }
            if empty > 0 {
                commands.append(.setForeground(.semantic(.muted)))
                commands.append(.write(String(repeating: "░", count: empty)))
            }
            commands.append(.reset)
            commands.append(.write("]"))
            
            if node.properties[.percentage] != nil {
                let percentage = Int(progress * 100)
                commands.append(.write(" \(percentage)%"))
            }
        }
    }
    

    private func paintBadge(_ node: Node, at position: Point, commands: inout [RenderCommand]) {
        let text = node.prop(.text, as: String.self) ?? ""
        let tintColor = node.prop(.tint, as: String.self)
        let inverted = node.properties[.inverted] ?? false
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if let tintStr = tintColor, let color = parseColor(tintStr) {
            if inverted {
                commands.append(.setBackground(theme.resolve(color)))
                commands.append(.setForeground(.rgb(255, 255, 255)))
            } else {
                commands.append(.setForeground(theme.resolve(color)))
            }
        }
        
        commands.append(.write(" \(text) "))
        commands.append(.reset)
    }
    

    private func paintNote(_ node: Node, at position: Point, width: Int, commands: inout [RenderCommand]) {
        let message = node.prop(.text, as: String.self) ?? ""
        let icon = node.properties[.icon] ?? ""
        let foreground = node.prop(.foreground, as: String.self)
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if let fg = foreground, let color = parseColor(fg) {
            commands.append(.setForeground(theme.resolve(color)))
        }
        
        commands.append(.write("\(icon) \(message)"))
        commands.append(.reset)
    }
    

    private func drawBorder(
        at position: Point,
        width: Int,
        height: Int,
        title: String?,
        rounded: Bool,
        commands: inout [RenderCommand]
    ) {

        guard width >= 2 && height >= 2 else { return }
        
        let chars = rounded ? BorderChars.rounded : BorderChars.single
        

        commands.append(.moveCursor(row: position.y, column: position.x))
        commands.append(.write(chars.topLeft))
        
        if let title = title, !title.isEmpty {
            let titleStr = "─ \(title) ─"
            let availableWidth = max(0, width - 2)
            if titleStr.count <= availableWidth {
                commands.append(.write(titleStr))
                let remainingWidth = availableWidth - titleStr.count
                if remainingWidth > 0 {
                    commands.append(.write(String(repeating: chars.horizontal, count: remainingWidth)))
                }
            } else {
                commands.append(.write(String(repeating: chars.horizontal, count: availableWidth)))
            }
        } else {
            let lineWidth = max(0, width - 2)
            if lineWidth > 0 {
                commands.append(.write(String(repeating: chars.horizontal, count: lineWidth)))
            }
        }
        
        commands.append(.write(chars.topRight))
        

        if height > 2 {
            for row in 1..<(height - 1) {
                commands.append(.moveCursor(row: position.y + row, column: position.x))
                commands.append(.write(chars.vertical))
                
                if width > 1 {
                    commands.append(.moveCursor(row: position.y + row, column: position.x + width - 1))
                    commands.append(.write(chars.vertical))
                }
            }
        }
        

        commands.append(.moveCursor(row: position.y + height - 1, column: position.x))
        commands.append(.write(chars.bottomLeft))
        let bottomWidth = max(0, width - 2)
        if bottomWidth > 0 {
            commands.append(.write(String(repeating: chars.horizontal, count: bottomWidth)))
        }
        commands.append(.write(chars.bottomRight))
    }
    

    private func parseColor(_ string: String) -> ANSIColor? {

        if string.contains("semantic") {
            if string.contains("accent") { return .semantic(.accent) }
            if string.contains("success") { return .semantic(.success) }
            if string.contains("warning") { return .semantic(.warning) }
            if string.contains("error") { return .semantic(.error) }
            if string.contains("info") { return .semantic(.info) }
            if string.contains("muted") { return .semantic(.muted) }
        }
        return nil
    }
}

private struct BorderChars {
    let topLeft: String
    let topRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
    
    static let single = BorderChars(
        topLeft: "┌",
        topRight: "┐",
        bottomLeft: "└",
        bottomRight: "┘",
        horizontal: "─",
        vertical: "│"
    )
    
    static let rounded = BorderChars(
        topLeft: "╭",
        topRight: "╮",
        bottomLeft: "╰",
        bottomRight: "╯",
        horizontal: "─",
        vertical: "│"
    )
}