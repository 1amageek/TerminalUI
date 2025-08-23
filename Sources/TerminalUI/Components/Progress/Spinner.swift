import Foundation

public struct Spinner: ConsoleView {
    private let label: String?
    private let style: SpinnerStyle
    private let color: ANSIColor?
    
    public init(
        _ label: String? = nil,
        style: SpinnerStyle = .dots,
        color: ANSIColor? = nil
    ) {
        self.label = label
        self.style = style
        self.color = color
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let properties = PropertyContainer()
            .with(.label, value: label ?? "")
            .with(.frames, value: style.frames)
            .with(.frameIndex, value: 0)
            .with(.isAnimating, value: true)
            .with(.color, value: color?.toHex() ?? "")
        
        return Node(
            id: context.makeNodeID(), 
            kind: .spinner,
            properties: properties
        )
    }
}

public struct SpinnerRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        commands.append(.moveCursor(row: position.y, column: position.x))
        

        if let colorHex: String = node.properties[.color], !colorHex.isEmpty {
            if let color = ANSIColor.fromHex(colorHex) {
                commands.append(.setForeground(color))
            }
        } else {
            commands.append(.setForeground(.semantic(.accent)))
        }
        

        let frames = node.properties[.frames] ?? ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        let frameIndex = node.properties[.frameIndex] ?? 0
        let isAnimating = node.properties[.isAnimating] ?? true
        
        if isAnimating && !frames.isEmpty {
            let currentFrame = frames[frameIndex % frames.count]
            commands.append(.write(currentFrame))
        } else {

            if !frames.isEmpty {
                commands.append(.write(frames[0]))
            }
        }
        

        if let label: String = node.properties[.label], !label.isEmpty {
            commands.append(.write(" "))
            commands.append(.reset)
            commands.append(.write(label))
        } else {
            commands.append(.reset)
        }
        
        return commands
    }
}

public extension Spinner {

    static func loading(_ label: String? = "Loading...") -> Spinner {
        Spinner(label, style: .dots)
    }
    

    static func processing(_ label: String? = "Processing...") -> Spinner {
        Spinner(label, style: .line)
    }
    

    static func syncing(_ label: String? = "Syncing...") -> Spinner {
        Spinner(label, style: .arc)
    }
}