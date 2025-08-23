import Foundation

public struct Badge: ConsoleView {
    private let title: String
    private var color: ANSIColor = .semantic(.accent)
    private var inverted: Bool = false
    
    public init(_ title: String) {
        self.title = title
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let address = context.makeAddress(for: "badge")
        
        var properties = PropertyContainer()
            .with(.text, value: title)
            .with(.tint, value: String(describing: color))
        
        if inverted {
            properties = properties.with(.inverted, value: true)
        }
        
        return Node(
            address: address,
            logicalID: nil,
            kind: .badge,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
}

public extension Badge {
    func tint(_ color: ANSIColor) -> Self {
        var copy = self
        copy.color = color
        return copy
    }
    
    func inverted(_ value: Bool = true) -> Self {
        var copy = self
        copy.inverted = value
        return copy
    }
    var body: Never {
        fatalError("Badge is a primitive view")
    }

}