import Foundation

public struct Divider: ConsoleView {
    private var style: DividerStyle = .single
    private var color: ANSIColor = .semantic(.muted)
    
    public enum DividerStyle: Sendable {
        case single
        case double
        case thick
        case dashed
        case dotted
    }
    
    public init() {}
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let address = context.makeAddress(for: "divider")
        
        let character: String = switch style {
        case .single: "─"
        case .double: "═"
        case .thick: "━"
        case .dashed: "╌"
        case .dotted: "┈"
        }
        
        let properties = PropertyContainer()
            .with(.text, value: character)
            .with(.foreground, value: String(describing: color))
        
        return Node(
            address: address,
            logicalID: nil,
            kind: .divider,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
}

public extension Divider {
    func style(_ style: DividerStyle) -> Self {
        var copy = self
        copy.style = style
        return copy
    }
    
    func color(_ color: ANSIColor) -> Self {
        var copy = self
        copy.color = color
        return copy
    }
    var body: Never {
        fatalError("Divider is a primitive view")
    }

}