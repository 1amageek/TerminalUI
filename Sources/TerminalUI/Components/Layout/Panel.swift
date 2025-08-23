import Foundation

public struct Panel<Content: ConsoleView>: ContainerView {
    private let title: String?
    public let content: Content
    private var borderColor: ANSIColor = .semantic(.muted)
    private var rounded: Bool = false
    
    public init(title: String? = nil, @ConsoleBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var containerKind: NodeKind {
        .panel
    }
    
    public func extraProperties() -> PropertyContainer {
        var properties = PropertyContainer()
            .with(.border, value: String(describing: borderColor))
            .with(.rounded, value: rounded)
        
        if let title = title {
            properties = properties.with(.label, value: title)
        }
        
        return properties
    }
}

public extension Panel {
    func borderColor(_ color: ANSIColor) -> Self {
        var copy = self
        copy.borderColor = color
        return copy
    }
    
    func rounded(_ value: Bool = true) -> Self {
        var copy = self
        copy.rounded = value
        return copy
    }
}