import Foundation

public struct TextFieldRenderer {
    private let theme: Theme
    private let capabilities: Capabilities
    
    public init(theme: Theme = .default, capabilities: Capabilities = .default) {
        self.theme = theme
        self.capabilities = capabilities
    }
    

    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        let label = node.prop(.label, as: String.self)
        let text = node.prop(.text, as: String.self) ?? ""
        let placeholder = node.prop(.placeholder, as: String.self)
        let isFocused = node.properties[.focused] ?? false
        let validation: String? = node.properties[PropertyContainer.Key<String>("validation")]
        let caretColumn = text.terminalWidth
        

        if let label = label {
            drawFieldBorder(
                label: label,
                at: position,
                width: width,
                isFocused: isFocused,
                commands: &commands
            )
            

            let contentY = position.y + 1
            let contentX = position.x + 1
            let contentWidth = width - 2
            
            drawFieldContent(
                text: text,
                placeholder: placeholder,
                caretColumn: caretColumn,
                isFocused: isFocused,
                at: Point(x: contentX, y: contentY),
                width: contentWidth,
                commands: &commands
            )
        } else {

            drawFieldContent(
                text: text,
                placeholder: placeholder,
                caretColumn: caretColumn,
                isFocused: isFocused,
                at: position,
                width: width,
                commands: &commands
            )
        }
        

        if let validation = validation {
            drawValidation(
                validation,
                at: Point(x: position.x, y: position.y + (label != nil ? 3 : 1)),
                commands: &commands
            )
        }
        
        return commands
    }
    

    private func drawFieldBorder(
        label: String,
        at position: Point,
        width: Int,
        isFocused: Bool,
        commands: inout [RenderCommand]
    ) {
        let borderColor: ANSIColor = isFocused ? .semantic(.accent) : .semantic(.muted)
        

        commands.append(.moveCursor(row: position.y, column: position.x))
        if isFocused {
            commands.append(.setForeground(borderColor))
        }
        
        commands.append(.write("┌"))
        if !label.isEmpty {
            commands.append(.write("─ \(label) "))
            let remaining = width - 4 - label.terminalWidth
            if remaining > 0 {
                commands.append(.write(String(repeating: "─", count: remaining)))
            }
        } else {
            commands.append(.write(String(repeating: "─", count: width - 2)))
        }
        commands.append(.write("┐"))
        

        commands.append(.moveCursor(row: position.y + 1, column: position.x))
        commands.append(.write("│"))
        commands.append(.moveCursor(row: position.y + 1, column: position.x + width - 1))
        commands.append(.write("│"))
        

        commands.append(.moveCursor(row: position.y + 2, column: position.x))
        commands.append(.write("└"))
        commands.append(.write(String(repeating: "─", count: width - 2)))
        commands.append(.write("┘"))
        
        if isFocused {
            commands.append(.reset)
        }
    }
    

    private func drawFieldContent(
        text: String,
        placeholder: String?,
        caretColumn: Int,
        isFocused: Bool,
        at position: Point,
        width: Int,
        commands: inout [RenderCommand]
    ) {
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        if text.isEmpty, let placeholder = placeholder {

            commands.append(.setForeground(.semantic(.muted)))
            commands.append(.setStyle(.italic))
            let truncated = placeholder.truncated(to: width)
            commands.append(.write(truncated))
            commands.append(.reset)
        } else {

            let visibleText = calculateVisibleText(text, caretColumn: caretColumn, width: width)
            commands.append(.write(visibleText))
            

            if isFocused {
                let actualCaretColumn = min(caretColumn, width - 1)
                commands.append(.moveCursor(row: position.y, column: position.x + actualCaretColumn))
                commands.append(.showCursor)
            }
        }
        

        let textWidth = text.isEmpty ? 0 : text.terminalWidth
        let remainingWidth = width - min(textWidth, width)
        if remainingWidth > 0 {
            commands.append(.write(String(repeating: " ", count: remainingWidth)))
        }
    }
    

    private func calculateVisibleText(_ text: String, caretColumn: Int, width: Int) -> String {
        guard width > 0 else { return "" }
        
        let totalWidth = text.terminalWidth
        

        if totalWidth <= width {
            return text
        }
        

        var offset = 0
        if caretColumn >= width {
            offset = caretColumn - width + 1
        }
        

        var currentWidth = 0
        var visibleText = ""
        var skippedWidth = 0
        
        for char in text {
            let charWidth = CharacterWidth.width(of: char)
            
            if skippedWidth < offset {
                skippedWidth += charWidth
                continue
            }
            
            if currentWidth + charWidth > width {
                break
            }
            
            visibleText.append(char)
            currentWidth += charWidth
        }
        
        return visibleText
    }
    

    private func drawValidation(_ validation: String, at position: Point, commands: inout [RenderCommand]) {
        let parts = validation.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return }
        
        let level = String(parts[0])
        let message = String(parts[1])
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        switch level {
        case "warning":
            commands.append(.setForeground(.semantic(.warning)))
            commands.append(.write("⚠️ \(message)"))
        case "error":
            commands.append(.setForeground(.semantic(.error)))
            commands.append(.write("❌ \(message)"))
        default:
            commands.append(.write(message))
        }
        
        commands.append(.reset)
    }
}