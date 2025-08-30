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
    
    private func colorToString(_ color: ANSIColor?) -> String {
        guard let color = color else { return "" }
        switch color {
        case .semantic(let semantic):
            return "semantic:\(semantic.rawValue)"
        case .rgb(let r, let g, let b):
            return "rgb:\(r),\(g),\(b)"
        case .xterm256(let index):
            return "xterm256:\(index)"
        case .indexed(let index):
            return "indexed:\(index)"
        case .none:
            return ""
        }
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let properties = PropertyContainer()
            .with(.label, value: label ?? "")
            .with(.frames, value: style.frames)
            .with(.frameIndex, value: 0)
            .with(.isAnimating, value: true)
            .with(.foreground, value: colorToString(color))
        
        return Node(
            address: context.makeAddress(for: "spinner"),
            logicalID: nil,
            kind: .spinner,
            properties: properties,
            parentAddress: context.currentParent
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
        

        if let colorStr: String = node.properties[.foreground], !colorStr.isEmpty {
            // Parse color string and apply - this should be handled by PaintEngine
            commands.append(.setForeground(.semantic(.accent)))
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
    var body: Never {
        fatalError("Spinner is a primitive view")
    }

}