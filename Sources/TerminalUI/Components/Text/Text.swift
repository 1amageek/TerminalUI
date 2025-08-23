import Foundation

public struct Text: ConsoleView {
    private let content: String
    private var foreground: ANSIColor?
    private var background: ANSIColor?
    private var isBold: Bool = false
    private var isItalic: Bool = false
    private var isUnderline: Bool = false
    private var isDim: Bool = false
    
    public init(_ content: String) {
        self.content = content
    }
    
    public init<S: StringProtocol>(_ content: S) {
        self.content = String(content)
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let address = context.makeAddress(for: "text")
        
        var properties = PropertyContainer()
            .with(.text, value: content)
        
        if let fg = foreground {
            properties = properties.with(.foreground, value: String(describing: fg))
        }
        
        if let bg = background {
            properties = properties.with(.background, value: String(describing: bg))
        }
        
        if isBold { properties = properties.with(.bold, value: true) }
        if isItalic { properties = properties.with(.italic, value: true) }
        if isUnderline { properties = properties.with(.underline, value: true) }
        if isDim { properties = properties.with(.dim, value: true) }
        
        return Node(
            address: address,
            logicalID: nil,
            kind: .text,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
}

public extension Text {
    func foreground(_ color: ANSIColor) -> Text {
        var copy = self
        copy.foreground = color
        return copy
    }
    
    func background(_ color: ANSIColor) -> Text {
        var copy = self
        copy.background = color
        return copy
    }
    
    func bold() -> Text {
        var copy = self
        copy.isBold = true
        return copy
    }
    
    func italic() -> Text {
        var copy = self
        copy.isItalic = true
        return copy
    }
    
    func underline() -> Text {
        var copy = self
        copy.isUnderline = true
        return copy
    }
    
    func dim() -> Text {
        var copy = self
        copy.isDim = true
        return copy
    }
    public var body: Never {
        fatalError("Text is a primitive view")
    }

}