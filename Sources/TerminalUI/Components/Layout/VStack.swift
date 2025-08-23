import Foundation

public struct VStack<Content: ConsoleView>: ContainerView {
    public let content: Content
    private var spacing: Int = 0
    private var padding: Int = 0
    private var border: ANSIColor?
    private var rounded: Bool = false
    
    public init(@ConsoleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var containerKind: NodeKind {
        .vstack
    }
    
    public func extraProperties() -> PropertyContainer {
        var properties = PropertyContainer()
        
        if spacing > 0 {
            properties = properties.with(.spacing, value: spacing)
        }
        
        if padding > 0 {
            properties = properties.with(.padding, value: padding)
        }
        
        if let borderColor = border {
            properties = properties.with(.border, value: String(describing: borderColor))
            properties = properties.with(.rounded, value: rounded)
        }
        
        return properties
    }
}

public extension VStack {
    func spacing(_ value: Int) -> Self {
        var copy = self
        copy.spacing = value
        return copy
    }
    
    func padding(_ value: Int) -> Self {
        var copy = self
        copy.padding = value
        return copy
    }
    
    func border(_ color: ANSIColor, rounded: Bool = false) -> Self {
        var copy = self
        copy.border = color
        copy.rounded = rounded
        return copy
    }
}